# 02 — สถาปัตยกรรม

## 1. Stack และเหตุผล

| ชั้น | เลือก | เหตุผล |
|---|---|---|
| UI + logic | **Flutter Windows desktop** จาก `lib/` เดิม | coordinator default 2 · "`lib/` เป็นต้นฉบับเดียว" แบบ QuetzaLib · ไม่ต้องดูแลสองฐานโค้ด — Electron ถูกปัด (`T1-C` §4.6: fork แอป Flutter ล้วนโดยไม่ได้อะไร) |
| ฐานข้อมูล | `sqflite_common_ffi` บน Windows (API เดียวกับ `sqflite`) | `Repository`/`AppDatabase` ใช้ได้เกือบเหมือนเดิม — เปลี่ยนแค่ `databaseFactory` |
| ถาด / หน้าต่าง / ปุ่มลัด / เปิดพร้อมเครื่อง | `tray_manager` · `window_manager` · `hotkey_manager` · `launch_at_startup` (ทั้งหมด MIT) | ชุด LeanFlutter ที่ใช้กันทั่วไป (`T1-C` §4.3) |
| หน้าต่างโน้ต | `desktop_multi_window` 0.3.x | multi-window ของ Flutter ยังไม่ stable (`T3-C` §4.2) |
| แจ้งเตือน | `flutter_local_notifications` ที่มีอยู่ (อัปเกรดเป็น 22.x ครั้งเดียว) ใช้แค่ `show()` บน Windows | ไม่เพิ่ม dependency · หลบข้อจำกัด MSIX/ไม่ซ้ำ (§4) |
| MCP shim | **`ourobask-mcp.exe`** — Dart CLI ล้วน (`dart compile exe`) ไม่มี Flutter | ECO-C4 อนุญาต "binary เล็กข้างตัวแอป" · เปิดเร็ว ไม่โหลด engine |
| ช่องทาง shim ↔ แอป | named pipe ผ่าน `win32` FFI | ECO-C5 · `dart:io` ไม่มี named pipe server |
| ธีม | `tokens.g.dart` ที่ vendor จากสัญญา Eco + `ddxThemeData()` | ECO-T1–T3 |

**dependency ใหม่ทั้งหมด** (ทุกตัวต้องเพิ่มใน `pubspec.yaml` เฉพาะที่จำเป็น): `sqflite_common_ffi`, `tray_manager`, `window_manager`,
`hotkey_manager`, `launch_at_startup`, `desktop_multi_window`, `win32`, `uuid` (UUIDv7) — 8 ตัว · ไม่มีตัวไหนใช้บน Android
(import ผ่าน `lib/desktop/` และ `lib/eco/` ที่ถูกเรียกเฉพาะ `Platform.isWindows`)
❓ ถ้าเจ้าของอยากลดจำนวน: `launch_at_startup` แทนได้ด้วย registry 5 บรรทัดผ่าน `win32` ที่ต้องมีอยู่แล้ว

## 2. Process model

```
                    ┌──────────────────── Ourobask.exe (process เดียว) ─────────────────────┐
 ผู้ใช้ ──คลิก──►   │ engine หลัก (ซ่อนได้ ไม่ตาย)                                            │
                    │   AppState (ChangeNotifier ตัวเดียว · ผู้เขียน SQLite คนเดียว)           │
                    │   ReminderScheduler (Timer)  ──► show() แจ้งเตือน / เปิดการ์ดปลุก        │
                    │   TrayController · HotkeyController · EcoPipeServer (isolate)            │
                    │        ▲ method channel (ข้อความ JSON)                                   │
                    │        ▼                                                                 │
                    │ engine โน้ต #1..#8  (desktop_multi_window · แสดงผลอย่างเดียว ไม่แตะ DB)  │
                    └──────────────────────────▲──────────────────────────────────────────────┘
                                               │ \\.\pipe\zydraxyl-ourobask-<SID> + token (ECO-C5)
 Z.I.Z / CLI agent ──stdio MCP──► ourobask-mcp.exe (shim ไม่มี UI ไม่เปิด DB)
 Hub ──argv `--eco-open <uri>`──► Ourobask.exe ตัวที่สอง ──ส่งต่อทาง pipe──► ตัวแรก แล้วออก (ECO-C11)
```

กติกา:
1. **ผู้เขียนฐานข้อมูลมีคนเดียว** = engine หลัก ทุกการเขียน (UI, โน้ต, ปุ่มบนแจ้งเตือน, MCP) วิ่งผ่าน `AppState`
   → ไม่มีปัญหาสอง process แย่ง SQLite และ UI สดเสมอ (ECO-C5, `T3-C` X2)
2. engine โน้ตได้แค่ `{kind, uid}` ตอนเปิด แล้วรับ "view model" JSON จาก engine หลัก · กด ✓/เลื่อน = ส่งคำสั่งกลับ
   (ไม่ลงทะเบียน `sqflite` ใน engine โน้ตเลย — กันเผลอเปิด DB ซ้อน)
3. ปิดหน้าต่างหลัก = ซ่อนลงถาด (`window_manager.setPreventClose(true)`) · "ออกจากโปรแกรม" ในเมนูถาดเท่านั้นที่จบ process
4. single instance: ตัวที่สองเจอ pipe ของตัวแรก → ส่ง `{"op":"focus"|"open","uri":…}` แล้ว exit `0` ·
   pipe ไม่ตอบ → ถือว่าเป็นตัวแรก (กันไฟล์ instance ค้าง — ECO-L5 ตรวจ pid)

## 3. ชั้นโค้ดและโฟลเดอร์

```
Ourobask-APP/
├── lib/
│   ├── main.dart                 + if (Platform.isWindows) await desktopBootstrap(args)
│   ├── data/
│   │   ├── database.dart         + schema v5 (uid/updated_at/deleted_at, agent_*, desk_pins, eco_*)
│   │   ├── repository.dart       + upsert ตาม uid · soft delete · merge ใน transaction เดียว
│   │   ├── backup.dart           → ใช้ our_tasks_codec · อ่าน ourobask-backup v1–v4 ต่อ
│   │   └── our_tasks_codec.dart  NEW — serializer/parser ตัวเดียวของ `our.tasks` (ไฟล์สำรอง + Eco)
│   ├── services/
│   │   ├── notification_service.dart   + เส้นทาง Windows (show + ปุ่ม) · รับ payload เมื่อกด
│   │   └── reminder_scheduler.dart     NEW — ตัวตั้งเวลาในแอป (ใช้บน Windows เท่านั้น)
│   ├── state/app_state.dart      + เรียก lib/eco สำหรับ agent/proposal (ไม่ยัด logic ใหม่ใน AppState ที่ยาว 987 บรรทัดแล้ว)
│   ├── desktop/                  NEW — bootstrap, tray, hotkey, quick_add, mini_list, sticky_main, alarm_card
│   ├── eco/                      NEW — pipe_server, mcp_handlers, permissions, proposals, audit, locator, zeco
│   └── ui/                       + NavigationRail เมื่อกว้าง ≥ 840px
├── tool/ourobask_mcp/            NEW — bin/ourobask_mcp.dart (Dart ล้วน) → ourobask-mcp.exe
├── windows/                      NEW — runner จาก `flutter create --platforms=windows .`
│                                   (Runner.rc: CompanyName=ZYDRAXYL, ProductName=Ourobask)
├── eco/                          NEW — สำเนาสัญญา Eco ที่ vendor มา + eco.lock.json (ECO-R32 · ห้ามแก้มือ)
└── src/design/                   เอกสารชุดนี้
```

ขนาดไฟล์: กติกา CLAUDE.md ไม่มีตัวตรวจ แต่ `app_state.dart` 987 บรรทัดแล้ว — logic ใหม่ทั้งหมดอยู่ใน `lib/eco/` และ `lib/desktop/`
ที่รับ `AppState` เป็นพารามิเตอร์ (แบบ `library_grouping.dart` ของ QuetzaLib: ไม่มี ChangeNotifier ตัวที่สอง)

## 4. การแจ้งเตือนบน Windows — ทำไมไม่ใช้ `zonedSchedule`

| ข้อจำกัดที่ research เจอ (`T3-C` §4.1) | ผลถ้าใช้ OS ตั้งเวลา | ตัวตั้งเวลาในแอป |
|---|---|---|
| `zonedSchedule` ยิงครั้งเดียว ไม่ซ้ำ | กิจวัตรต้องตั้งล่วงหน้า K ครั้ง + ระบบ id ใหม่ | คำนวณครั้งถัดไปเองจาก `Routine.occursOn` (มีอยู่แล้ว) |
| cancel ได้เฉพาะ MSIX | ไม่ใช่ MSIX → ปิดเตือน/ลบงานแล้ว**ยังเด้ง** | ไม่มีอะไรต้อง cancel — ตารางอยู่ในหน่วยความจำ |
| MSIX → AppData ถูก virtualize ต่อแพ็กเกจ [K ต้องตรวจ] | Hub/Z.I.Z อาจมองไม่เห็นไฟล์ locator (ECO-L1) และข้อมูลหายเมื่อถอนการติดตั้ง | portable zip ปกติ — ตรงกับ ECO-K7 (Hub ติดตั้งหลายเวอร์ชันจาก portable) |
| alarm แบบ Android ไม่มี | — | การ์ดปลุก always-on-top + เสียงวน (05 §4) |

ต้นทุนที่ยอมรับ: **ออกจากโปรแกรมแล้วไม่มีการเตือน** → แอปอยู่ในถาดเป็นค่าเริ่มต้น, เมนู "ออก" เตือนครั้งแรก,
และเมื่อเปิดใหม่แสดง "พลาดการเตือน N รายการ" (04 §5) ❓ รอเจ้าของตัดสิน → [Grill Q2](./07-grill-me.md)

Android ไม่เปลี่ยน: ยังใช้ `zonedSchedule` + exact alarm เหมือนเดิม — `ReminderScheduler` ถูกสร้างเฉพาะ `Platform.isWindows`

## 5. ไฟล์บนเครื่อง Windows

| อะไร | ที่อยู่ | หมายเหตุ |
|---|---|---|
| ฐานข้อมูล | `%APPDATA%\ZYDRAXYL\Ourobask\ourobask.db` (`getApplicationSupportDirectory()`) | เปิด WAL · ปุ่ม "เปิดโฟลเดอร์ข้อมูล" ในตั้งค่า |
| snapshot ก่อน AI เขียน | `…\Ourobask\snapshots\<ISO>-<proposalId>.db` (`VACUUM INTO`) | ECO-S3 · เก็บ 10 ล่าสุด |
| audit log | ตาราง `eco_audit` ในฐานข้อมูล | ECO-S4 (เลือกแบบ "เก็บในคลังของแอป") |
| ไฟล์ sync (ถ้าเปิด) | `<โฟลเดอร์ที่ผู้ใช้เลือก>\ourobask-sync\<deviceId>.json` | 04 §4 |
| locator / instance | `%LOCALAPPDATA%\Zydraxyl\locator\ourobask.json` · `instances\ourobask.json` | ECO-L1–L5 |
| ตัวแอป (portable) | Hub: `%LOCALAPPDATA%\Zydraxyl\apps\ourobask\<version>\` · ไม่มี Hub: ที่ไหนก็ได้ที่ผู้ใช้แตก zip | ECO-K7 |

หลายเวอร์ชันแชร์ฐานข้อมูลเดียวกัน → **เวอร์ชันเก่าต้องไม่เปิดฐานข้อมูลที่ `schemaVersion` ใหม่กว่าแบบเขียนได้** (ECO-K7):
`AppDatabase` วันนี้ไม่มี `onDowngrade` → sqflite จะ error · ต้องเพิ่ม: เจอ version ใหม่กว่า → หน้าจอ "ข้อมูลนี้มาจาก Ourobask ที่ใหม่กว่า —
เปิดด้วยเวอร์ชันใหม่ผ่าน Hub" และ**ไม่เปิดฐานข้อมูล**

## 6. ส่วนที่ใช้ร่วมกับ Android

| ส่วน | Android | Windows |
|---|---|---|
| `data/` ทั้งหมด (schema v5, codec, merge) | ✅ ต้องได้ด้วย — ไม่งั้นไฟล์จาก PC เข้ามือถือไม่ได้ | ✅ |
| `ui/` หน้าเดิม | ✅ หน้าตาเดิม | ✅ + NavigationRail + ธีม Eco |
| การ์ด "งานที่ Z.I.Z ส่งผลกลับ" (review) | ✅ ดู/รับได้ (ข้อมูลมากับ sync) | ✅ |
| `desktop/`, `eco/` (pipe, MCP, locator), `ReminderScheduler` | ❌ | ✅ |
| `UpdateService` ดาวน์โหลด APK | ✅ เดิม | ❌ เช็กเวอร์ชันได้ · ปุ่มเป็น "อัปเดตผ่าน Hub / เปิดหน้า release" |

## 7. โมดูล DraconDex ที่คัดลอก

**ไม่มี.** Ourobask ไม่ใช่แอปข้อมูลโลก/หน้า — ไม่ copy โมดูลใด (coordinator default 4 ไม่เกี่ยว)
สิ่งเดียวที่รับมาคือ **token ธีม** แบบ byte-identical ผ่าน pull-pin (ECO-R32, ECO-G2):

```
eco/eco.lock.json               {"ref":"eco-vX.Y.Z","files":{"tokens/tokens.g.dart":"<sha256>", "schemas/our.tasks/1.0.schema.json":…}}
node tools/eco-contract.mjs --check                 ← CI (ไฟล์ไม่ถูกแก้)
node tools/eco-contract.mjs --vendor --ref eco-vX.Y.Z  ← เจ้าของเลื่อน pin เอง
```
(`tools/eco-contract.mjs` เป็นของ repo สัญญา — vendor มาเหมือนกัน ไม่เขียนเอง)

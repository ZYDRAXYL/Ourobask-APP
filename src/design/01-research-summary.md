# 01 — สรุปการค้นคว้า

แหล่ง: `Zydraxyl-HUB/Design/eco/research/T1-C-structure.md` §4 · `T2-C-features.md` §4 · `T3-C-internals.md` §4
· `T4-C-uxui.md` §5 · `T5-eco-research.md` §4–§6 · และโค้ดจริงใน repo นี้ (`lib/`, `pubspec.yaml`, `.github/workflows/`)

ระดับความมั่นใจตาม research: **[V]** อ่านแหล่งจริง · **[S]** snippet จากผลค้นหา · **[K]** ความรู้เดิม ยังไม่ตรวจ
ข้อที่ไม่ใช่ [V] ต้องทดสอบบนเครื่อง Windows จริงก่อนเชื่อ (ดูตาราง "ต้องพิสูจน์ก่อนเขียนโค้ด" ท้ายไฟล์)

---

## 1. ผลิตภัณฑ์/โปรเจกต์ที่เทียบ

| ชื่อ | URL | ไลเซนส์ | ยืมอะไร | เลี่ยงอะไร |
|---|---|---|---|---|
| Super Productivity | https://github.com/johannesjo/super-productivity | MIT [V] | แอปเดียวทั้ง desktop + mobile, schema กลาง, sync ผ่านไฟล์/WebDAV, เตือนพัก | Electron + Angular — Ourobask เป็น Flutter อยู่แล้ว ไม่ย้าย stack |
| Microsoft Sticky Notes | https://support.microsoft.com/windows/apps/stickynotes/get-started-with-sticky-notes | ปิด | ปิดโน้ต ≠ ลบ · มีหน้ารวมโน้ต · สีต่อโน้ต · ปักบนสุด [S] | sync ผ่านบัญชี Microsoft |
| Todoist Quick Add | https://todoist.com/help/articles/115001745265 | ปิด | ปุ่มลัดทั่วระบบ · แยกวัน/ความสำคัญจากข้อความแล้ว**ไฮไลต์ก่อนกด Enter** · คลิกคำที่ถูกอ่านเป็นวันผิดให้กลับเป็นข้อความ [S] | parser หลายภาษาที่ไม่มีไทย |
| Sunsama Daily Planning | https://help.sunsama.com/docs/daily-planning | ปิด | พิธี "วางแผนวันนี้": ดูงานค้าง → เลือก → เตือนเมื่องานเกินเวลา [S] | ผูก Slack/Jira |
| TickTick Windows widget | https://ticktick.com/windows | ปิด | แถบงานแคบที่มองเห็นตลอด → รายการย่อ O4 | — |
| GitHub Copilot coding agent | https://docs.github.com/en/enterprise-cloud@latest/copilot/using-github-copilot/coding-agent/using-copilot-to-work-on-an-issue | ปิด | มอบงานให้ agent → agent ส่ง "การเปลี่ยนแปลงที่ตรวจได้" → คนตรวจแล้วรับ · **เฉพาะเจ้าของสิทธิ์สั่ง agent ได้** [S] | การรันบนคลาวด์ |
| GitHub issue forms | https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms | — | ฟิลด์ที่มีชนิดสำหรับงานที่ agent รับ (คำสั่ง, ลิงก์บริบท) [S] | — |
| Taskwarrior | https://github.com/GothenburgBitFactory/taskwarrior | MIT [K] | **JSON export คือ API สาธารณะ** — แนวเดียวกับ `our.tasks` + MCP | CLI-only |
| BurntToast / windows-toasts | https://powershellgallery.com/packages/BurntToast · https://windows-toasts.readthedocs.io | MIT [S] | ปุ่มเลื่อน (snooze) + เลือกเวลาเลื่อน | — |

## 2. ไลบรารี Flutter desktop ที่เกี่ยว

| งาน | แพ็กเกจ | ไลเซนส์ / สถานะ | ข้อสรุป |
|---|---|---|---|
| SQLite บน Windows | `sqflite_common_ffi` | BSD-2 [K] | ต้องใช้ — `sqflite` ไม่มี Windows (`T3-C` §4.1) |
| แจ้งเตือน | `flutter_local_notifications` (มีอยู่แล้ว ^19.4.2) | BSD-3 · Windows ✅ [S: pub.dev] | init ต้องมี `appName`, `appUserModelId`, `guid` · **cancel/getActive ใช้ได้เฉพาะเมื่อแพ็กเป็น MSIX** · `periodicallyShow` throw · `zonedSchedule` บน Windows **ยิงครั้งเดียว ไม่สนใจ `matchDateTimeComponents`** (`T3-C` §4.1) · v22 เปลี่ยนพารามิเตอร์ Windows → อัปเกรดครั้งเดียวตอนพอร์ต |
| ถาด | `tray_manager` (LeanFlutter) | MIT [V] | ไอคอน, tooltip, เมนูขวา, submenu · `setTitle` ไม่มีผลบน Windows · มีแผนย้ายไป `nativeapi` → **pin เวอร์ชัน** |
| หน้าต่าง | `window_manager` | MIT [V] | always-on-top, frameless, ซ่อนแทนปิด (`setPreventClose`), ข้าม taskbar |
| หลายหน้าต่าง | `desktop_multi_window` 0.3.0 | [S] | **1 หน้าต่าง = 1 Flutter engine/isolate** ไม่แชร์ `AppState` · ต้องแก้ runner เพื่อลงทะเบียน plugin ต่อหน้าต่าง |
| multi-window ของ Flutter เอง | `RegularWindow` | [S] ยังไม่อยู่ใน stable (3.44.x, ก.ค. 2026) | รอ — ออกแบบให้เปลี่ยนมาใช้ได้ภายหลัง |
| ปุ่มลัดทั่วระบบ | `hotkey_manager` | MIT [K] | สำหรับเพิ่มงานด่วน |
| เปิดพร้อม Windows | `launch_at_startup` | MIT [K] | registry Run key (ไม่ต้อง MSIX) |
| แจ้งเตือนสำรอง | `local_notifier` | MIT [V] | README ไม่มี API กำหนดปุ่มบนแจ้งเตือน → ไม่พอสำหรับ "เสร็จแล้ว/เลื่อน" |
| named pipe (MCP shim ↔ แอป) | `win32` (FFI) | BSD-3 [K] | `dart:io` ไม่มี named pipe ฝั่ง server บน Windows → ต้อง FFI |

## 3. ข้อสรุปต่อหัวข้อ

### 3.1 โครงสร้าง (T1)
- ไม่ต้องสร้าง repo ใหม่ · ไม่ต้องมี chain — `lib/` + `windows/` ใน repo เดียว (`T1-C` §4.4–4.5)
- research เสนอสองทาง: **สอง process** (แอปหลัก + "Desk" ถือโน้ต/แจ้งเตือน, แชร์ SQLite WAL — `T1-C`) กับ
  **process เดียว + `desktop_multi_window`** (`T3-C` §4.2) → **เลือกอย่างหลัง** เพราะ ECO-C5 ต้องการผู้เขียนฐานข้อมูลคนเดียว
  และ `AppState` โหลดครั้งเดียวทั้งก้อน (สอง process = UI ค้างข้อมูลเก่า — `T3-C` X2)

### 3.2 ฟีเจอร์ (T2)
- MVP ที่ research จัดไว้: ปุ่มลัดเพิ่มงาน (O5) · แยกวันจากข้อความ + ไฮไลต์ (O6/O7) · โน้ตบนจอ (O11/O12) ·
  ปุ่มบนแจ้งเตือน (O14) · ปิดแจ้งเตือนแบบปัดทิ้ง (O16) · **ประตูสิทธิ์ agent** (O19)
- ตัดออก: นำเข้าจาก Jira/GitHub (O2/O3) — ไม่เกี่ยวกับเจตนาเจ้าของ และ O3 มีแหล่งอ่อน · sync ผ่านบัญชี (O13) — ขัดแนว Eco ไม่มีบัญชี

### 3.3 ภายใน (T3)
- **ข้อเท็จจริงจากโค้ด** (ตรวจในรอบนี้):
  - `Repository.mergeAll` (`lib/data/repository.dart`) ใส่ทุกแถวเป็นแถวใหม่ (ล้าง id แล้ว remap) → **นำเข้าแบบรวมไฟล์เดิมซ้ำ = งานซ้ำทุกชิ้น** ·
    และ `mergeAll` **ไม่อยู่ใน transaction** (เรียก `insertX` ทีละแถว) → พังกลางทางได้ข้อมูลครึ่งเดียว (ขัด ECO-R17)
  - `updated_at` มีแค่ `tasks` กับ `notes` · ลบทุกอย่างเป็น hard delete · งานเสร็จเกิน 30 วันถูกลบถาวรทุกครั้งที่เปิดแอป
  - `BackupService` เขียน `exported_at` เป็นเวลาท้องถิ่นไม่มี `Z` (ขัด ECO-R10) · เงินเควสเป็น `REAL`/`double` (ขัด ECO-R10 ถ้าส่งออกตรง ๆ)
  - `NotificationService.isSupported` = Android/iOS เท่านั้น · `payload: 'task:<id>'` ถูกส่งไปแต่ไม่มีตัวรับเมื่อกดแจ้งเตือน
  - `UpdateService` เลือก asset `.apk` จาก `releases/latest` ของ `ZYDRAXYL/Ourobask-APP`
- ID ทุกตัวเป็น integer AUTOINCREMENT → ใช้ข้ามเครื่อง/ข้ามแอปไม่ได้ (`T3-C` X1) → เพิ่ม `uid` (UUIDv7 ตาม ECO-I4)

### 3.4 UX (T4)
- PC = "พื้นผิวที่อยู่ข้างงาน" (ถาด, โน้ต, แจ้งเตือน, รายการย่อ) + หน้าต่างเต็มเดิม (`T4-C` §5.1)
- สีงานของผู้ใช้เป็น**ข้อมูล** — ใช้เป็นจุด/แถบ/สีจาง 18% ไม่ใช้เป็นสีตัวอักษร (`T4-C` §5.3, §5.7)
- สี `DeadlineBucket` ที่ hard-code (`#E76F51 #E9A319 #43A047`) ชนกับความหมาย danger/warn/success → บน PC ใช้ข้อความ + ไอคอน + token
- โน้ตบนจอ**ห้ามแย่งโฟกัส**ตอนโผล่ (มีแค่การ์ดปลุกที่ขอโฟกัสได้) (`T4-C` §5.8)

### 3.5 Eco (T5)
- Ourobask ไม่มี chain → **pull-pin** สัญญา (`eco.lock.json` + `tools/eco-contract.mjs --vendor`) (`T5` §6.2, ECO-G2)
- MCP v1 = stdio เท่านั้น, shim คุยกับแอปที่รันอยู่ทาง named pipe (ECO-C4, ECO-C5) — ตรงกับการที่ Ourobask อยู่ในถาดตลอด

## 4. ข้อที่ research ขัดกัน และที่เลือก

| ประเด็น | ฝั่ง A | ฝั่ง B | เลือก · เหตุผล |
|---|---|---|---|
| `flutter_local_notifications` รองรับ Windows ไหม | `T3-C` §4.1: รองรับ (อ้าง pub.dev) | `T4-C` §5.4: "ยังไม่ยืนยัน" | **A** — มีแหล่งอ้าง; แต่ข้อจำกัด (MSIX, ไม่ซ้ำ) ทำให้เราใช้แค่ `show()` |
| สอง process vs หลายหน้าต่างใน process เดียว | `T1-C` §4.4 | `T3-C` §4.2 | **B** — ผู้เขียน DB คนเดียว (ECO-C5) |
| ที่เก็บตำแหน่งโน้ต | `settings` key `sticky:<type>:<id>` (`T3-C`) | ตาราง `sticky_note`/`desk_pin` (`T1-C`, `T4-C`) | **ตารางใหม่ `desk_pins`** — ต้องลบตามเจ้าของและไม่ควรถูก sync ไปมือถือ; อยู่ใน settings จะลบ/กรองยาก |
| `alarm` บน Windows | toast `scenario="alarm"` ผ่าน raw XML (`T3-C`, ยังไม่ตรวจ) | การ์ดปลุกในแอป always-on-top (`T4-C`) | **การ์ดในแอปเป็นทางหลัก** · toast เป็นตัวเสริม — การ์ดอยู่ในมือเรา ไม่ขึ้นกับ Focus Assist |

## 5. ต้องพิสูจน์ก่อนเขียนโค้ด (spike 1–2 วัน)

| # | ทดสอบ | ถ้าไม่ผ่าน |
|---|---|---|
| S1 | `flutter_local_notifications` (v22) `show()` บน Windows **ไม่แพ็ก MSIX** พร้อมปุ่ม action 2–3 ปุ่ม และรับ callback เมื่อแอปอยู่ในถาด | ใช้การ์ดในแอปอย่างเดียว (ทำอยู่แล้วสำหรับ alarm) |
| S2 | `desktop_multi_window` 8 หน้าต่าง: RAM รวม, always-on-top, ไม่แย่งโฟกัส, ส่งข้อความกลับหน้าต่างหลัก | ลดเพดานโน้ต หรือเลื่อนโน้ตไป v1 แล้วใช้รายการย่อปักบนสุดแทน ([Grill Q3](./07-grill-me.md)) |
| S3 | named pipe server ผ่าน `win32` FFI ใน isolate แยก + client จาก `dart compile exe` | MCP เลื่อน — ส่งออก `.zeco` ยังใช้ได้ |
| S4 | ข้อความไทยใน toast และโน้ต (ฟอนต์ Noto Sans Thai ที่ bundle) | ใช้ Leelawadee UI ของระบบ |
| S5 | `hotkey_manager` จับ `Ctrl+Alt+N` ขณะแอปซ่อนอยู่ | ให้ผู้ใช้ตั้งปุ่มเอง |

# 06 — การเชื่อมกับ Zydraxyl Eco

ทุกข้ออ้าง `Zydraxyl-HUB/Design/eco/ECO-CONTRACT.md` ด้วยรหัสกฎ · ไม่เขียนกฎซ้ำ — ที่นี่บอกแค่ "Ourobask ทำอะไรตามกฎนั้น"
ตัวตน (ECO-I1): `id = ourobask` · `code = our` · format ที่เป็นเจ้าของ: `our.tasks` (ECO-I3)

## 1. Checklist Eco v1 ของ Ourobask (ECO §17 แถว OUR)

| ข้อ | ทำที่ | ลำดับ |
|---|---|---|
| vendor สัญญา + `eco.lock.json` + CI `--check` (ECO-R32) — แบบ **pull-pin** (ECO-G2) | `eco/` · `.github/workflows/ci.yml` เพิ่ม 1 step | MVP |
| ส่งออก `.zeco` + rendition (ECO-R9) | §2 | MVP |
| นำเข้าตาม ECO-R15 + พรีวิว (ECO-R16) | §3 · 05 §7 | MVP |
| ผ่าน fixture ที่ประกาศ (ECO-R30) | §8 | MVP |
| locator + instance (ECO-L1–L5) | §5 | MVP |
| MCP stdio + ชุดมาตรฐาน (ECO-C4–C6) | §4 | MVP |
| สิทธิ์ · snapshot · audit (ECO-S1–S4) | 04 §1.3, §2 · 05 §6 | MVP |
| `--eco-open` + single instance (ECO-C3, C11) | §7 · 02 §2 | MVP |
| token ร่วม (ECO-T1–T3) | 05 §8 | MVP |
| ปฏิเสธเขียนข้อมูลที่ใหม่กว่าตัวเอง (ECO-K7) | 02 §5 · 04 §6.2 ข้อ 5 | MVP |
| อ่าน/ตรวจลายเซ็น `eco.json` (ECO-K2) — ⬜ ควร | ใช้ทำ "เปิดด้วย…" ในตาราง ECO-R15 แถว 3 | v1 |

## 2. ส่งออก `.zeco`

```
ourobask-<ชื่อ>-<YYYYMMDD>.zeco
├── mimetype                              "application/vnd.zydraxyl.eco+zip" (entry แรก, STORED — ECO-B2)
├── manifest.json
├── parts/main/tasks.json                 our.tasks 1.0 (04 §3) · role=primary
├── parts/entities/entities.json          eco.entity-set 1.0 · role=data — **ต้องมี** เพราะ Z.I.Z ต้องอ่าน (ECO-R9)
├── renditions/index.html                 รายการงานแบบอ่านอย่างเดียว ไม่มี script · CSS inline จาก token ธีม daylight (ECO-T5)
└── renditions/README.md                  Markdown: หัวข้อตามโฟลเดอร์ · `- [ ]` งานค้าง · `- [x]` งานเสร็จ
```
ไม่มี `preview.png` (ECO-R9: "ควร" สำหรับ format ที่ไม่ใช่ภาพ — ข้าม, ประหยัดงาน `RepaintBoundary`) · ไม่มี `assets/` (Ourobask ไม่มีไฟล์แนบ · เสียงปลุกไม่ส่ง)

```json
{
  "eco": "1.0", "id": "0192f3b0-…", "format": "our.tasks", "formatVersion": "1.0",
  "title": "งานลูกค้า A — งานค้าง", "lang": "th", "exportedAt": "2026-10-18T09:30:00Z",
  "producer": {"app": "ourobask", "version": "2.0.0", "build": "exe", "platform": "windows-x64"},
  "source": {"app": "ourobask", "project": "0192…store", "projectName": "งานของฉัน",
             "ref": "zydraxyl://ourobask/0192…store/0192…p1"},
  "parts": [
    {"id": "main", "path": "parts/main/tasks.json", "format": "our.tasks", "formatVersion": "1.0", "role": "primary",
     "mediaType": "application/json", "sha256": "…", "bytes": 18234},
    {"id": "entities", "path": "parts/entities/entities.json", "format": "eco.entity-set", "formatVersion": "1.0",
     "role": "data", "mediaType": "application/json", "sha256": "…", "bytes": 6120}
  ],
  "renditions": [
    {"path": "renditions/index.html", "mediaType": "text/html", "role": "view"},
    {"path": "renditions/README.md", "mediaType": "text/markdown", "role": "view"}
  ]
}
```

### 2.1 `our.tasks` → `eco.entity-set` (ECO-E1 — บังคับแค่ `eid` `kind` `name`)

| ของ Ourobask | `kind` | `name` | `summary` | `fields` (ชั้นเดียว, ค่า JSON ล้วน) | `links` |
|---|---|---|---|---|---|
| Task ธรรมดา | `task` | title | บรรทัดแรกของ notes | `due` (ISO หรือวันที่), `priority`, `done`, `agentState` | `in-project` → project |
| Quest | `quest` | title | "฿12,400.00 / ฿35,000.00" | `target` `"35000.00"`, `saved` `"12400.00"` (string — ECO-R10) | `in-project` |
| Routine | `routine` | title | "ทุกวันที่ 1, 15 · 08:00" | `repeat`, `days` (array of string) | `funds` → quest |
| Note | `note` | title หรือบรรทัดแรก | — · ตัวเต็มใน `text` (`eco.text`) | `pinned` | `in-project` |
| Idea | `idea` | 40 ตัวอักษรแรก | — · `text` | `box` | `became` → task |
| Project | `project` | name | description | `openTasks` | — |

`eid` = `uid` ของแถว · `text.value` เป็น CommonMark (เช็กลิสต์ใน notes ผ่านไปตรง ๆ) · `updatedAt` ตามแถว
ไม่ส่ง reminders เป็น entity (เป็นรายละเอียดของงาน ไม่ถูกอ้างข้ามแอป)

### 2.2 ส่งออกจากไหน
ตั้งค่า › ข้อมูล › "ส่งออกสำหรับแอปอื่นใน Zydraxyl (.zeco)" · เมนูโฟลเดอร์งาน "ส่งออกโฟลเดอร์นี้" (`scope = project:<uid>`, v1) ·
MCP `eco_export` (เขียนลง `%APPDATA%\ZYDRAXYL\Ourobask\exports\` — ดูข้อเสนอ §9 ข้อ 2) · ไฟล์สำรองบนมือถือยังเป็น `.json` ล้วน (part หลักไม่ห่อ)

## 3. นำเข้า

| format ที่อ่าน (`reads` ใน `eco.json`) | major | ทำอะไร |
|---|---|---|
| `our.tasks` | 1 | merge ตาม uid (04 §4.1) · พรีวิว 05 §7 |
| `eco.entity-set` | 1 | **จากแอปอื่น**: `kind` ที่รู้จัก (`task`) → งานใหม่ · อื่น ๆ (เช่น `character` จาก BahaMyth) → ถาม "สร้างเป็นไอเดีย N ใบในกล่อง 'นำเข้าจาก BahaMyth'?" — ไอเดียเป็นที่ลงที่ปลอดภัยที่สุด · `eid` เดิมเก็บเป็น `context_refs` ของงาน/ลิงก์ในเนื้อไอเดีย ไม่ใช้เป็น `uid` ของเรา |
| อื่น ๆ | — | ECO-R15 แถว 3 (เสนอเปิดด้วยแอปเจ้าของ + แสดง rendition ใน sandbox — ECO-R21) |

- นำเข้า = atomic (ECO-R17) · ไม่แตะไฟล์ต้นทาง (ECO-R18) · `uid` ชนกับของที่มีอยู่ = กรณีปกติของ format ตัวเอง → ใช้กติกา merge (ECO-R19 กำหนดให้ "ถาม" — เราตอบคำถามนั้นครั้งเดียวในพรีวิวด้วยตัวเลข "อัปเดต N · ข้าม M" แทนถามทีละแถว ดู §9 ข้อ 3)
- ลากไฟล์ `.zeco`/`.json` วางบนหน้าต่างหลัก = เปิดพรีวิวนำเข้า (ECO-C1 ข้อ 1)

## 4. MCP — `ourobask-mcp.exe`

### 4.1 การเชื่อม (ECO-C4, C5)
- คำสั่ง: `ourobask-mcp.exe` (Dart CLI ข้าง `Ourobask.exe`) · ชื่อ server ในคอนฟิก agent: `zydraxyl-ourobask`
- shim อ่าน `%LOCALAPPDATA%\Zydraxyl\instances\ourobask.json` → ต่อ `\\.\pipe\zydraxyl-ourobask-<SID>` + token
  ไม่มี instance → เปิด `Ourobask.exe --minimized` แล้วรอ pipe ≤ 20 วินาที (ECO-C5)
- ทุก tool call กลายเป็นข้อความ JSON ทาง pipe → `lib/eco/mcp_handlers.dart` ใน engine หลัก → ตรวจ `eco_grants` → เรียก `AppState`

### 4.2 ชุดมาตรฐาน (ECO-C6)

| tool | Ourobask ทำอะไร | สิทธิ์ |
|---|---|---|
| `eco_info` | app/version, reads/writes (§6), สิทธิ์ตอนนี้ | — |
| `eco_list_projects` | 1 รายการ "คลังงาน" + Work Project ทั้งหมด (เหมือน locator §5) | — |
| `eco_search` | ค้น title/notes/content ของ task, note, idea → Eco reference + ชื่อ + kind | `read` |
| `eco_get` | ref → `eco.entity-set` (+ `our.tasks` บางส่วนถ้าขอ `native:true`) | `read` |
| `eco_export` | เขียน `.zeco` ลงโฟลเดอร์ exports ของแอป (ไม่รับ path จาก agent) | `read` |
| `eco_propose` | รับ patch → ตรวจ (ห้ามลบ/ตั้ง done/แตะเงิน — 04 §2.2) → `proposalId` + สรุป diff ภาษาไทย | `propose` |
| `eco_apply` | มี batch grant → ใช้เลย · ไม่มี → คืน `{"status":"pending_user"}` และขึ้นแผงตรวจในแอป | `write` |
| `eco_delete` | ยืนยันในแอปทุกครั้ง · tombstone (04 §4.3) | `delete` |
| `eco_import` | path ไฟล์ → เปิดพรีวิวในหน้าต่าง (ผู้ใช้กดเอง) | `write` |

### 4.3 tool เฉพาะ Ourobask (ECO-C8 — ขึ้นต้น `our_`)

| tool | input | output / ผล | annotations | สิทธิ์ |
|---|---|---|---|---|
| `our_list_tasks` | `filter: overdue\|today\|upcoming\|no_date\|project\|agent_queue`, `project?` | งานพร้อม bucket (ใช้ `bucketOf` เดิมใน `lib/utils/`) | readOnly | `read` |
| `our_get_task` | `uid` | งาน + reminders (ไม่มีเสียง) + เช็กลิสต์ + `agent` | readOnly | `read` |
| `our_claim_task` | `uid`, `runId` | `queued → claimed` + lease 30 นาที · ชนกับ run อื่น → error `already_claimed` | idempotent | `propose` |
| `our_submit_result` | `uid`, `runId`, `result` (Markdown), `proposalId?`, `state: needs_review\|failed` | ตั้ง `agent_result` · แจ้งเตือนผู้ใช้ | — | `propose` |
| `our_list_notes` | `project` | โน้ตของโฟลเดอร์ (โน้ตอยู่นอกโฟลเดอร์ไม่ได้ — CLAUDE.md) | readOnly | `read` |
| `our_list_ideas` | `box?`, `filter: all\|filed\|unfiled` | ไอเดีย | readOnly | `read` |
| `our_today` | — | สรุปวันนี้: เกินกำหนด/วันนี้/กิจวัตร/การเตือนถัดไป (ข้อมูลเดียวกับรายการย่อ) | readOnly | `read` |
| `our_quest_summary` | `project?` | `MoneySummary` เป็น string ทศนิยม | readOnly | `read` **+ เปิด "ให้ AI เห็นยอดเงิน"** ❓ → [Grill Q9](./07-grill-me.md) |

การสร้าง/แก้/โปรโมตไอเดียเป็นงาน **ไม่มี tool แยก** — ทำผ่าน `eco_propose` (patch แบบ `eco.entity-set` + `fields.op`) เพื่อให้ทุกการเขียนผ่านแผงตรวจเดียว
(`T3-C` §4.6 เสนอ `our.create_task`/`our.update_task`/`our.complete_task` แยก → ตัดออก เพราะจะเป็นทางเขียนที่ข้าม ECO-S2)

**ไม่เปิดทาง MCP เลย:** `clearAllData` · นำเข้าแบบเขียนทับ · ไฟล์/URI เสียง · `settings` ทั้งหมด (`sync_dir`, `device_id`) · `desk_pins` (ECO-S6 allowlist)

### 4.4 resource (ECO-C7)
`zydraxyl://ourobask/<store_uid>` (คลังงาน) · `zydraxyl://ourobask/<store_uid>/<uid>` (งาน/โน้ต/ไอเดีย/โฟลเดอร์) — อ่านได้เท่ากับ `eco_get`

## 5. Locator + instance (ECO-L1–L5)

Ourobask ไม่มี "ไฟล์โปรเจกต์" — ทั้งฐานข้อมูลคือคลังเดียว · Work Project เป็นโฟลเดอร์งาน**ในคลัง** · จึงลงทะเบียนแบบนี้:

```json
{
  "format": "eco.locator", "formatVersion": "1.0", "app": "ourobask", "appVersion": "2.0.0",
  "updatedAt": "2026-10-18T09:00:00Z",
  "projects": [
    {"projectUid": "0192…store", "name": "งานของฉัน", "kind": "store",
     "path": "C:\\Users\\me\\AppData\\Roaming\\ZYDRAXYL\\Ourobask", "openWith": "C:\\Users\\me\\AppData\\Roaming\\ZYDRAXYL\\Ourobask\\ourobask.db",
     "lastOpenedAt": "2026-10-18T08:55:00Z", "nativeFormat": {"id": "our.tasks", "version": "1.0"}, "pinned": true},
    {"projectUid": "0192…p1", "name": "งานลูกค้า A", "kind": "work-project",
     "path": "C:\\Users\\me\\AppData\\Roaming\\ZYDRAXYL\\Ourobask", "openWith": "C:\\Users\\me\\AppData\\Roaming\\ZYDRAXYL\\Ourobask\\ourobask.db",
     "lastOpenedAt": "2026-10-17T10:00:00Z", "nativeFormat": {"id": "our.tasks", "version": "1.0"}, "pinned": false}
  ]
}
```
- Hub ใช้ `zydraxyl://ourobask/0192…p1` เปิดตรงไปที่โฟลเดอร์งาน — Work Project มี `uid` อยู่แล้ว (04 §1.1) จึงใช้เป็น `projectUid` ได้ฟรี
- เขียนใหม่ (atomic) เมื่อ: เปิดแอป · สร้าง/เปลี่ยนชื่อ/ลบ/เก็บถาวรโฟลเดอร์งาน · ไม่รวมโฟลเดอร์ที่ `archived` หรือถูกลบ
- instance file + pipe ตาม ECO-L5 ตัวอย่างเป๊ะ (`"app":"ourobask"`, `"ecoProtocol":1`, `"mcp":{"protocols":["2025-11-25"]}`) · ลบตอนออก

## 6. แถวของ Ourobask ใน `eco.json` (ECO-K3 — เสนอให้ repo สัญญาใส่)

```json
{
  "id": "ourobask", "code": "our", "name": "Ourobask",
  "builds": [
    {"build": "exe", "platform": "windows-x64", "releaseRepo": "ZYDRAXYL/Ourobask-APP", "tagPattern": "v*", "rank": "version",
     "assets": {"portable": "ourobask-v*-windows-x64-portable.zip"}, "minHub": "1.0.0"},
    {"build": "apk", "platform": "android", "releaseRepo": "ZYDRAXYL/Ourobask-APP", "tagPattern": "v*", "rank": "version",
     "assets": {"apk": "ourobask-v*.apk"}}
  ],
  "formats": {
    "writes": [{"format": "our.tasks", "versions": ">=1.0.0 <2.0.0"}, {"format": "eco.entity-set", "versions": ">=1.0.0 <2.0.0"}],
    "reads":  [{"format": "our.tasks", "majors": [1]}, {"format": "eco.entity-set", "majors": [1]}]
  },
  "mcp": {"command": "ourobask-mcp.exe", "args": [], "protocols": ["2025-11-25"]}, "ecoProtocol": 1
}
```
- `releaseRepo` = repo นี้เอง เพราะเป็น public อยู่แล้ว (`AppInfo.latestReleaseApi` ใช้ API แบบไม่มี token) — ECO-K4 ผ่าน
- asset pattern ไม่ชนกับ APK: zip ลงท้าย `-windows-x64-portable.zip` · APK ลงท้าย `.apk` (ตัวอัปเดตบนมือถือกรองด้วย `.apk` อยู่แล้ว)
- ไม่มี installer ใน MVP (ECO-K7 ใช้ portable) · ถ้าเจ้าของอยากได้ไฟล์ `Setup.exe` สำหรับคนไม่ใช้ Hub → Inno Setup ใน v1 แล้วเพิ่ม `"installer": "ourobask-v*-windows-x64-setup.exe"`

### 6.1 release workflow (เพิ่มใน `.github/workflows/release.yml`)

```
on: push tags v*           (เดิม)
jobs:
  release (ubuntu)  : flutter test → build apk ×2 → upload      (เดิม)
  windows (windows-latest, ใหม่):
    flutter config --enable-windows-desktop
    flutter test
    flutter build windows --release
    dart compile exe tool/ourobask_mcp/bin/ourobask_mcp.dart -o build/.../Release/ourobask-mcp.exe
    Compress-Archive build/windows/x64/runner/Release/* → dist/ourobask-${TAG}-windows-x64-portable.zip
    upload ลง release เดียวกับ APK (softprops/action-gh-release, tag เดียวกัน)
```
- CI (`ci.yml`) เพิ่ม job `flutter build windows` บน `windows-latest` เพื่อจับ build แตกก่อน tag
- ❓ ลงลายเซ็น Authenticode? ไม่มี → SmartScreen เตือนตอนเปิดครั้งแรก (Hub ลด friction ได้บางส่วน) — เป็นเรื่องระดับ Eco ไม่ถามซ้ำที่นี่

## 7. Connect อื่น ๆ

| กลไก (ECO-C1) | Ourobask |
|---|---|
| `--eco-open <uri>` (ECO-C3) | `zydraxyl://ourobask/<store>` = เปิดหน้าแรก · `/<projectUid>` = เปิดโฟลเดอร์งาน · `/<store>/<uid>` = เปิดงาน/โน้ต · exit `11` ถ้าหาไม่เจอ · `12` ถ้าฐานข้อมูลใหม่กว่า |
| single instance (ECO-C11) | ส่งต่อทาง pipe เดียวกับ MCP (02 §2) — ไม่ต้องใช้กลไกที่สอง |
| `.zeco` association (ECO-C9) | เพิ่ม `Ourobask.zeco` ใน `OpenWithProgids` (HKCU) ตอนเปิดครั้งแรก · ไม่ตั้งตัวเองเป็น Default ถ้ามี Hub · ไม่มีตัวติดตั้ง → ทำในแอป ตั้งค่า › Eco › "ให้ Ourobask เปิดไฟล์ .zeco ได้" |
| clipboard (ECO-C10) | "คัดลอกลิงก์" บนงาน = `text/plain` ชื่อ + Eco reference · วางลิงก์ Eco ใน notes → แสดงเป็นลิงก์ที่กดเปิดผ่าน Hub |
| deep link ขาออก | ลิงก์ใน `context_refs`/notes กด = เปิด `zydraxyl://…` ผ่าน OS (Hub ลงทะเบียน ECO-C2) · ไม่มี Hub → toast "ติดตั้ง Zydraxyl Hub เพื่อเปิดลิงก์ข้ามแอป" |

## 8. Conformance

| ข้อ | ทำ |
|---|---|
| ECO-R28 fixture ของ `our.tasks` | สร้างด้วยโค้ดจริง: `flutter test test/eco_fixture_test.dart --update` เขียน `fixtures/our.tasks/1.0/{empty,basic,quest-money,all-day-tz,tombstones}.zeco` แล้วส่ง PR ไป repo สัญญา (ห้ามเขียนมือ) |
| ECO-R29 ฝั่งผู้เขียน | CI สร้าง fixture ใหม่ → diff กับที่ commit · validate กับ `eco/schemas/our.tasks/1.0.schema.json` (ไม่มี `additionalProperties:false`) |
| ECO-R30 ฝั่งผู้อ่าน | นำเข้า fixture ทุกตัวของ `our.tasks` 1.x + `eco.entity-set` 1.x ลงฐานข้อมูลเปล่าใน `flutter test` (sqflite ffi ใน VM) · ไฟล์ "2.0" ปลอมต้องถูกปฏิเสธ |
| fixture ที่สำคัญที่สุด | `quest-money`: `"0.10" + "0.20"` ต้องได้ `"0.30"` — วันนี้ยอดเงินเป็น `double` ภายใน → แปลงเป็น string ด้วยทศนิยม 2 ตำแหน่งตอนเขียนและอ่านกลับเป็นสตางค์ (integer) ก่อนคำนวณ — ไม่ parse เป็น double ตรง ๆ |

## 9. ข้อเสนอเพิ่มเข้า Eco contract

1. **ข้อยกเว้น "metadata ของงาน agent"** ใน ECO-S2: tool ที่เขียน**เฉพาะฟิลด์สถานะของ agent** (`agent_state`, `agent_result`, lease) และไม่แก้ข้อมูลผู้ใช้
   ใช้สิทธิ์ `propose` ได้โดยไม่ผ่าน `eco_apply` แต่ต้องลง audit — แอปอื่นที่ให้ Z.I.Z "รับงาน" (RyuLong, LevelthanQ) จะต้องการแบบเดียวกัน
   เสนอชื่อมาตรฐาน `eco_claim` / `eco_submit_result` แทน `our_*` ถ้ามีแอปที่สองใช้
2. **ปลายทางของ `eco_export` สำหรับแอปที่ไม่มีโฟลเดอร์โปรเจกต์ Eco**: ECO-C6 บังคับ `<project>/.zydraxyl/exports/` — Ourobask ไม่มี →
   เสนอ fallback `%APPDATA%\<publisher>\<App>\exports\` (หรือ `%LOCALAPPDATA%\Zydraxyl\exports\<appId>\`) ที่ระบุในสัญญา
3. **ECO-R19 สำหรับ format ของตัวเองที่มี `updatedAt`**: อนุญาตให้ตัดสิน "ใหม่กว่าชนะ" ได้ถ้าแสดงจำนวนในพรีวิวและผู้ใช้กดยืนยันครั้งเดียว —
   ถามทีละ `eid` ใช้ไม่ได้กับ sync ที่มีหลายร้อยแถว
4. **สมาชิกโปรเจกต์ Eco ที่ไม่ใช่โฟลเดอร์** (ECO-L6/L7): ให้ `members.<appId>` มี `{"projectUid", "ref"}` โดยไม่มี `path` ได้ —
   สำหรับแอปที่ข้อมูลอยู่ในฐานข้อมูลกลางของแอป (Ourobask, QuetzaLib) · จนกว่าจะรับ Ourobask ไม่ผูก Work Project กับโปรเจกต์ Eco (03 D9)
5. **วันที่แบบทั้งวัน** ใน ECO-R10: ระบุว่า "วันที่ไม่มีเวลา" เขียนเป็น `YYYY-MM-DD` ไม่แปลงเป็น UTC — ทุกแอปที่มีกำหนดการ/ไทม์ไลน์ (BahaMyth Chronicler, Ourobask) เจอปัญหาเดียวกัน

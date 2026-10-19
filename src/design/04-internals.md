# 04 — ระบบภายใน

อ้างโค้ดปัจจุบัน: `lib/data/database.dart` (schema v4), `lib/data/repository.dart`, `lib/data/backup.dart` (`ourobask-backup` v4),
`lib/services/notification_service.dart`, `lib/state/app_state.dart`, `lib/app_info.dart` (1.5.1+8)

---

## 1. Schema v5

### 1.1 คอลัมน์ที่เพิ่มในตารางข้อมูลทั้ง 8 ตาราง (`kDataTables`)

| คอลัมน์ | ชนิด | ความหมาย |
|---|---|---|
| `uid` | `TEXT` + `CREATE UNIQUE INDEX idx_<t>_uid` | UUIDv7 (ECO-I4) — ID ข้ามเครื่อง/ข้ามแอป · integer `id` ยังเป็น PK ภายในเหมือนเดิม (`T3-C` X1) |
| `updated_at` | `INTEGER` ms (มีแล้วใน `tasks`, `notes`) | ใช้ตัดสิน merge · **ทุกการเขียนผ่าน `Repository` ต้องแตะค่านี้** |
| `deleted_at` | `INTEGER` ms nullable | tombstone — ลบ = ตั้งค่านี้ ไม่ `DELETE` (§4.3) |

migration v5 (ใน `_migrations[5]` + ขั้น Dart ต่อท้าย เพราะ SQL สร้าง UUIDv7 ไม่ได้):
```
ALTER TABLE <t> ADD COLUMN uid TEXT                       -- ×8
ALTER TABLE <t> ADD COLUMN updated_at INTEGER             -- ×6 (ยกเว้น tasks, notes)
ALTER TABLE <t> ADD COLUMN deleted_at INTEGER             -- ×8
-- ขั้น Dart: UPDATE <t> SET uid=?, updated_at=COALESCE(updated_at, created_at, <now>) ทีละแถว ใน transaction เดียว
CREATE UNIQUE INDEX idx_<t>_uid ON <t>(uid)               -- หลัง backfill
```
`onUpgrade` วันนี้รันแค่ SQL → เพิ่ม hook `_afterUpgrade(db, from, to)` สำหรับขั้น Dart (ต้องอยู่ใน transaction ของ `onUpgrade`)

### 1.2 คอลัมน์ "agent-ready" ใน `tasks` (ตัดจาก `T3-C` §4.5 ให้เหลือที่ใช้จริง)

| คอลัมน์ | ชนิด | ค่า | ลำดับ |
|---|---|---|---|
| `agent_state` | `TEXT NOT NULL DEFAULT 'none'` | `none · queued · claimed · needs_review · failed` (open enum, fallback `none`) | MVP |
| `agent_brief` | `TEXT NOT NULL DEFAULT ''` | คำขอที่ผู้ใช้เลือก/พิมพ์ตอนส่งให้ Z.I.Z | MVP |
| `agent_result` | `TEXT` nullable | Markdown สรุปผลของ Z.I.Z (`eco.text`) | MVP |
| `agent_run_id` | `TEXT` nullable | run ที่ถือ lease อยู่ | MVP |
| `agent_claimed_at` | `INTEGER` nullable | เวลาเริ่ม lease — เกิน 30 นาทีไม่มี `submit` → กลับเป็น `queued` | MVP |
| `context_refs` | `TEXT NOT NULL DEFAULT '[]'` | JSON array ของ Eco reference (ECO-I5) เช่น `["zydraxyl://ryulong/<p>/<e>"]` | v1 |

ตัดออกจาก `T3-C`: `assignee` (ซ้ำกับ `agent_state != 'none'`) · สถานะ `done` ของ agent (ซ้ำกับ `tasks.done` ที่เป็นของผู้ใช้)

### 1.3 ตารางใหม่ — **เฉพาะเครื่อง** (ไม่ sync, ไม่ส่งออก, ไม่อยู่ใน `kDataTables`)

```sql
CREATE TABLE desk_pins (            -- โน้ตบนหน้าจอ (05 §3)
  owner_kind TEXT NOT NULL,         -- 'task' | 'note' | 'idea'
  owner_uid  TEXT NOT NULL,
  x INTEGER, y INTEGER, w INTEGER NOT NULL DEFAULT 240, h INTEGER NOT NULL DEFAULT 160,
  monitor TEXT,                     -- ชื่อจอ · จอหาย → ดึงกลับเข้าจอหลัก
  on_top INTEGER NOT NULL DEFAULT 0,
  visible INTEGER NOT NULL DEFAULT 1,
  PRIMARY KEY (owner_kind, owner_uid)
);
CREATE TABLE eco_grants (           -- ECO-S1
  client TEXT NOT NULL, level TEXT NOT NULL,   -- read|propose|write|delete
  expires_at INTEGER, batch_left INTEGER,      -- batch grant (ECO-S2) · NULL = ไม่ใช่ batch
  created_at INTEGER NOT NULL, PRIMARY KEY (client, level)
);
CREATE TABLE eco_proposals (        -- ECO-C6 eco_propose / our_submit_result
  proposal_id TEXT PRIMARY KEY, client TEXT NOT NULL, task_uid TEXT,
  patch TEXT NOT NULL,              -- eco.entity-set patch (JSON)
  summary TEXT NOT NULL, status TEXT NOT NULL, -- pending|applied|rejected|expired
  snapshot TEXT, created_at INTEGER NOT NULL, decided_at INTEGER
);
CREATE TABLE eco_audit (            -- ECO-S4 append-only
  at INTEGER NOT NULL, client TEXT NOT NULL, tool TEXT NOT NULL,
  uids TEXT NOT NULL, proposal_id TEXT, snapshot TEXT, result TEXT NOT NULL
);
```
ทำไม `desk_pins` ไม่อยู่ใน `settings` (ที่ `T3-C` เสนอ): ต้องลบตามเจ้าของ และต้องแน่ใจว่าไม่ติดไปกับไฟล์สำรอง — ตารางแยกทำทั้งสองข้อได้ด้วย SQL ธรรมดา
ทำไม `eco_*` เป็นตาราง ไม่ใช่ `.jsonl`: Ourobask ไม่มีโฟลเดอร์โปรเจกต์ Eco ที่จะวาง `.zydraxyl/audit/` (ECO-S4 อนุญาตเก็บในคลังของแอป)

### 1.4 ค่าใน `settings` ที่เพิ่ม

| key | ค่า |
|---|---|
| `device_id` | UUIDv7 ของเครื่องนี้ (ใช้ตัดสินเสมอใน merge + ชื่อไฟล์ sync) |
| `store_uid` | UUIDv7 ของ "คลังงาน" ทั้งก้อน = `projectUid` ใน locator (06 §4) |
| `sync_dir` | โฟลเดอร์ sync ที่ผู้ใช้เลือก (เฉพาะเครื่อง — ห้ามส่งออก ECO-R11) |
| `reminder_checked_at` | เวลาที่ตัวตั้งเวลาตรวจล่าสุด (หา "การเตือนที่พลาด") |
| `snooze` | JSON `{"<reminderUid>@<occurrenceISO>": "<untilISO>"}` |

### 1.5 คอลัมน์ที่ "ผูกกับเครื่อง" — ห้ามเดินทางข้ามเครื่องแบบมีความหมาย

| คอลัมน์ | ทำไม | กติกา |
|---|---|---|
| `reminders.notification_id` | id ของ OS ต่อเครื่อง | ไม่ส่งออก · ผู้นำเข้าออกใหม่ (`insertReminder` ทำอยู่แล้ว) |
| `reminders.sound_uri` | Android `content://` / Windows path ของ `.wav` | ส่งออกเฉพาะ `soundName` · ฝั่งที่ไม่รู้จัก URI → เสียงปลุกเริ่มต้นของแพลตฟอร์ม |
| `desk_pins.*`, `eco_*`, `settings.*` | สถานะเครื่อง | ไม่ส่งออกเลย |

---

## 2. สถานะงานของ Z.I.Z + การเสนอ → ใช้

### 2.1 state machine (`tasks.agent_state`)

```
            ผู้ใช้: "ให้ Z.I.Z ช่วย…"                Z.I.Z: our_claim_task(uid, runId)
  none ───────────────────────────► queued ───────────────────────────► claimed
   ▲  ▲                               ▲  ▲                                 │  │
   │  │ ผู้ใช้: "ยกเลิก"                │  └──── lease เกิน 30 นาที ───────────┘  │ our_submit_result(uid, runId, result, proposalId?)
   │  └───────────────────────────────┘                                    │  ▼
   │                                   failed ◄── our_submit_result(state=failed)
   │                                                                 needs_review
   └──────────── ผู้ใช้กด "รับ" (apply บางส่วนหรือทั้งหมด) หรือ "ไม่รับ" ◄────────────┘
```
- `tasks.done` เป็นของผู้ใช้เท่านั้น — Z.I.Z ไม่มี tool ที่ตั้ง `done = 1` ❓ → [Grill Q5](./07-grill-me.md)
- `claim` / `submit_result` แตะ**เฉพาะคอลัมน์ `agent_*`** และต้องมีสิทธิ์ `propose` · ทุกครั้งเขียน `eco_audit`
  (เป็นข้อยกเว้นของ ECO-S2 ที่เสนอเข้าสัญญาใน 06 §7 — ไม่ได้แก้ข้อมูลของผู้ใช้ จึงไม่ต้องกดยืนยัน)

### 2.2 ลำดับการทำงานเต็ม

```
ผู้ใช้        Ourobask (AppState + lib/eco)                 ourobask-mcp.exe      Z.I.Z / agent
  │ ให้ Z.I.Z ช่วย "แตกงานย่อย" ─► agent_state=queued
  │                                    │◄──── pipe ───── our_list_tasks{filter:"agent_queue"} ◄── tools/call
  │                                    │ ตรวจ eco_grants(read) ไม่มี → การ์ดขอสิทธิ์ (ECO-S1)
  │ [อนุญาตจนจบ session] ─────────────►│ ส่งรายการกลับ (eco.entity-set)
  │                                    │◄──── our_claim_task{uid, runId} (propose) → claimed
  │                                    │                                         … agent ทำงานนอกแอป …
  │                                    │◄──── eco_propose{patch} → snapshot ครั้งแรกของ session (ECO-S3)
  │                                    │      → เก็บ eco_proposals(pending) → คืน proposalId + สรุป diff
  │                                    │◄──── our_submit_result{uid, runId, result, proposalId} → needs_review
  │ แจ้งเตือน "Z.I.Z ส่งผลงาน: ส่งรายงานลูกค้า" [ดู]
  │ แผงตรวจ: ผลลัพธ์ Markdown + ☑ เปลี่ยนแปลงทีละข้อ ─► [ใช้ 3 จาก 4]
  │                                    │ apply ผ่าน AppState (saveTask/saveNote…) ใน transaction เดียว
  │                                    │ eco_audit · agent_state=none · toast "เลิกทำ 3 การเปลี่ยนแปลงจาก Z.I.Z"
  │                                    │◄──── (ถ้า agent เรียก eco_apply{proposalId}) → ตอบ "รอผู้ใช้ตรวจในแอป"
```
- `eco_apply` จาก agent **ไม่ใช้เองโดยตรง** ถ้าไม่มี batch grant — ปุ่มในแอปคือทางเดียว (ECO-S2) และคืนสถานะ `pending_user`
- patch ที่ทำได้ใน v1: สร้าง task/note/idea · แก้ `title`/`notes`/`due`/`priority`/`project` ของ task · เพิ่มเช็กลิสต์ใน notes ·
  **ไม่ได้**: ลบ, ตั้ง `done`, แก้เงินเควส (`quest_entries`), แก้ reminder/เสียง
- เพดาน ≤ 500 entity ต่อ proposal (ECO-S10) · proposal ค้างเกิน 7 วัน → `expired`

---

## 3. ไฟล์ `our.tasks` 1.0 (ECO-I3 จองชื่อไว้ให้)

### 3.1 หลัก

- **serializer ตัวเดียว** (`our_tasks_codec.dart`) ใช้ทั้งไฟล์สำรองบนมือถือ (`.json`), ไฟล์ sync (§4) และ part หลักใน `.zeco` (06 §2)
- อ้างกันด้วย `uid` ไม่ใช่ integer (ECO-R8) · เวลา ISO-8601 UTC ลงท้าย `Z` · **เงินเป็น string ทศนิยม** (ECO-R10)
- วันแบบ "ทั้งวัน" เขียนเป็นวันที่ล้วน `"2026-10-20"` + `allDay: true` — ห้ามแปลงเป็น UTC (เที่ยงคืนไทย = 17:00 ของวันก่อนใน UTC → เลื่อนวัน)
- เวลาที่ระบุชั่วโมงเขียนเป็น UTC + `tz` (IANA) ที่ผู้เขียนใช้ เพื่อให้เครื่องที่ timezone ต่างกันยังแสดง "17:00 ตามเวลาไทย" ได้
- ฟิลด์ที่ไม่รู้จัก: อ่านแล้ว**เก็บไว้ส่งออกกลับ** สำหรับไฟล์ของตัวเอง (ECO-R20) — เก็บใน map `_unknown` ต่อ entity ในหน่วยความจำ
  ระหว่างนำเข้า→ส่งออกในรอบเดียว (ไม่เก็บลง SQLite ใน v1 · ❓ ถ้าต้องการรอดข้ามการเปิดแอป ต้องเพิ่มคอลัมน์ `extra TEXT`)

### 3.2 ตัวอย่าง

```json
{
  "format": "our.tasks", "formatVersion": "1.0",
  "exportedAt": "2026-10-18T09:30:00Z",
  "producer": {"app": "ourobask", "version": "2.0.0", "build": "exe", "platform": "windows-x64"},
  "store": "0192f3a0-7777-7aaa-8bbb-000000000001",
  "scope": "all",
  "projects": [
    {"uid": "0192…p1", "name": "งานลูกค้า A", "description": "", "color": "#3F72AF", "icon": 1,
     "sortOrder": 0, "archived": false, "createdAt": "2026-09-01T02:00:00Z", "updatedAt": "2026-10-18T09:00:00Z"}
  ],
  "tasks": [
    {"uid": "0192…t1", "project": "0192…p1", "title": "ส่งรายงานลูกค้า", "notes": "- [ ] แนบไฟล์สรุป\n- [ ] โทรยืนยัน",
     "kind": "normal", "due": {"at": "2026-10-18T10:00:00Z", "tz": "Asia/Bangkok"}, "durationMinutes": 60,
     "priority": "urgent", "done": false, "completedAt": null, "color": "#E76F51", "sortOrder": 0,
     "agent": {"state": "needs_review", "brief": "แตกงานย่อย + เสนอลำดับทำ", "result": "## ข้อเสนอ\n…",
               "contextRefs": ["zydraxyl://ryulong/0192…/0192…"]},
     "createdAt": "2026-10-10T03:00:00Z", "updatedAt": "2026-10-18T09:00:00Z"},
    {"uid": "0192…q1", "project": null, "title": "ออมเงินซื้อโน้ตบุ๊ก", "kind": "quest", "targetAmount": "35000.00",
     "due": {"date": "2026-12-31", "allDay": true}, "priority": "normal", "done": false, "color": "#43A047",
     "createdAt": "2026-08-01T01:00:00Z", "updatedAt": "2026-10-15T12:00:00Z"}
  ],
  "questEntries": [
    {"uid": "0192…e1", "task": "0192…q1", "amount": "1200.50", "note": "เงินเดือน", "routine": "0192…r1",
     "createdAt": "2026-10-01T05:00:00Z", "updatedAt": "2026-10-01T05:00:00Z"}
  ],
  "routines": [
    {"uid": "0192…r1", "title": "หยอดกระปุก", "project": null, "repeat": "monthly", "weekdays": [], "monthDays": [1, 15],
     "startTime": "08:00", "endTime": "09:00", "tz": "Asia/Bangkok", "quest": "0192…q1", "questAmount": "500.00",
     "active": true, "startDate": "2026-08-01", "endDate": null, "color": "#2A9D8F",
     "createdAt": "2026-08-01T01:00:00Z", "updatedAt": "2026-08-01T01:00:00Z"}
  ],
  "reminders": [
    {"uid": "0192…m1", "owner": {"kind": "task", "uid": "0192…t1"}, "offsetMinutes": 15, "enabled": true,
     "alarm": true, "soundName": "เสียงระฆัง", "updatedAt": "2026-10-10T03:00:00Z"}
  ],
  "ideaBoxes": [{"uid": "0192…b1", "name": "เกม", "color": "#8E7DBE", "icon": 9, "sortOrder": 0, "createdAt": "…", "updatedAt": "…"}],
  "ideas": [{"uid": "0192…i1", "content": "ทำ VN สั้น ๆ", "color": "#8E7DBE", "box": "0192…b1", "convertedTask": null,
             "archived": false, "createdAt": "…", "updatedAt": "…"}],
  "notes": [{"uid": "0192…n1", "project": "0192…p1", "title": "สรุปประชุม", "content": "…", "color": "#546E7A",
             "pinned": true, "sortOrder": 0, "createdAt": "…", "updatedAt": "…"}],
  "deleted": [{"kind": "task", "uid": "0192…t9", "deletedAt": "2026-10-17T08:00:00Z"}]
}
```

### 3.3 enum (ECO-R6)

| ฟิลด์ | ชนิด | ค่า | fallback |
|---|---|---|---|
| `tasks[].kind` | open | `normal` `quest` | `normal` (quest ที่ไม่รู้จัก = งานธรรมดา, ยังเห็นชื่อ) |
| `tasks[].priority` | closed | `normal` `important` `urgent` (= 0/1/2, ป้าย "ปกติ/สำคัญ/ด่วนมาก") | — |
| `tasks[].agent.state` | open | `none` `queued` `claimed` `needs_review` `failed` | `none` |
| `routines[].repeat` | open | `weekly` `monthly` | `weekly` + `active:false` (ไม่เดาวันผิด) |
| `reminders[].owner.kind` | closed | `task` `routine` | — |
| `deleted[].kind` | open | ทุก kind ข้างบน + `project` `note` `idea` `ideaBox` `questEntry` `reminder` | ข้าม |

- `color` เขียนเป็น `#RRGGBB` (ไม่ใช่ int ARGB ของ Flutter) — อ่านง่ายข้ามภาษา
- `scope`: `all` | `project:<uid>` | `open-tasks` — ผู้อ่านใช้ตัดสินว่า "ไม่มีในไฟล์" แปลว่า "ลบ" หรือไม่ (**ไม่เคย** — ลบต้องมาจาก `deleted` เท่านั้น)

### 3.4 การอ่านไฟล์เก่า

| ไฟล์ | อ่านได้ไหม | ทำอะไร |
|---|---|---|
| `ourobask-backup` v1–v4 | ✅ ตลอดไป | แปลงด้วย codec เดิม (`BackupPayload`) → ออก `uid` ใหม่ให้ทุกแถว → **ไม่มีทางรู้ว่าตรงกับแถวไหน** → นำเข้าแบบ "รวม" จะเพิ่มแถวใหม่เหมือนวันนี้ และหน้าพรีวิวต้องเตือน "ไฟล์รุ่นเก่า — อาจได้งานซ้ำ" |
| `our.tasks` 1.x | ✅ | merge ตาม §4 |
| `our.tasks` 2.x+ | ❌ | ECO-R15 แถว 4: "ไฟล์มาจาก Ourobask ที่ใหม่กว่า — อัปเดตแอป" |

---

## 4. มือถือ ↔ PC: merge และ sync

### 4.1 merge (ใช้ทั้งนำเข้าแบบ "รวม" และ sync) — pure Dart, ทดสอบได้ไม่ต้องมีอุปกรณ์

```
สำหรับแต่ละ entity ในไฟล์ (เรียงตาม FK: projects → ideaBoxes → tasks → routines → ideas → notes → questEntries → reminders):
  local = หาแถวที่ uid ตรงกัน (รวมแถวที่มี deleted_at)
  ไม่มี local                 → INSERT (แปลง uid อ้างอิง → integer id ภายใน)
  incoming.updatedAt > local  → UPDATE ทุกฟิลด์ (รวมการชุบชีวิตถ้า local ถูกลบ… ดูข้อ tombstone)
  เท่ากัน                     → ผู้ชนะ = deviceId มากกว่า (ตัดสินแบบเดียวกันทุกเครื่อง → ผลเหมือนกันทั้งสองฝั่ง)
  น้อยกว่า                    → ข้าม
สำหรับแต่ละ deleted[]:  deletedAt > local.updatedAt → ตั้ง deleted_at (+ ลบลูกแบบ soft ตาม §4.3)
ทั้งหมดใน db.transaction เดียว (ECO-R17) → จบแล้ว AppState._reloadAll() + เตือนใหม่ทั้งหมด (rescheduleAll มีอยู่แล้ว)
```
- นำเข้าไฟล์เดิมซ้ำ = ไม่เกิดอะไร (idempotent) — แก้บั๊ก "รวมแล้วงานซ้ำ" ของ `mergeAll` วันนี้
- LWW **ต่อแถว** (ไม่ใช่ต่อฟิลด์): แก้ชื่องานบนมือถือ + แก้กำหนดบน PC ในช่วงเดียวกัน → ฝั่งที่แก้ทีหลังชนะทั้งแถว ❓ → [Grill Q11](./07-grill-me.md)
- นาฬิกาเพี้ยน: เครื่องที่นาฬิกาเร็วชนะเสมอ — ยอมรับใน v1 (เครื่องผู้ใช้ทั่วไป sync NTP) · หน้าพรีวิวแสดง "ไฟล์นี้มาจากอนาคต N นาที" ถ้า `exportedAt` > ตอนนี้ + 5 นาที

### 4.2 sync ผ่านโฟลเดอร์ (D6, v1)

```
<sync_dir>\ourobask-sync\
  ├── 0192…devicePC.json      ← เครื่องนี้เขียนไฟล์ของตัวเองเท่านั้น (our.tasks, scope=all, รวม deleted) · atomic: .tmp → rename
  └── 0192…devicePhone.json   ← อ่านอย่างเดียว · merge ตาม §4.1
```
- ไม่มีไฟล์ไหนถูกสองเครื่องเขียน → ไม่มี "conflicted copy" ของ OneDrive/Drive (`T3-C` §4.4 ตัวเลือก C)
- จังหวะ (PC): ตอนเปิดแอป · ทุก 5 นาที · 10 วินาทีหลังมีการแก้ · เมื่อไฟล์ของเครื่องอื่นเปลี่ยน (`mtime` — ไม่ใช้ file watcher ตาม ECO-C1 ข้อ 8)
- **ข้อจำกัดบน Android** (ต้องบอกตรง ๆ): Google Drive / OneDrive บนมือถือไม่เป็นโฟลเดอร์จริง — อ่านเขียนอัตโนมัติได้แน่นอนเฉพาะ Syncthing
  (โฟลเดอร์จริง) · ที่เหลือมือถือใช้ปุ่ม "ส่งไปเครื่องอื่น / รับจากเครื่องอื่น" ด้วยไฟล์รูปแบบเดียวกันและ merge เดียวกัน ❓ → [Grill Q10](./07-grill-me.md)

### 4.3 tombstone และการลบ

- ทุก `delete*` ใน `Repository` → `UPDATE … SET deleted_at=?, updated_at=?` · ทุก query รายการเพิ่ม `WHERE deleted_at IS NULL`
- FK `ON DELETE CASCADE/SET NULL` ไม่ทำงานกับ soft delete → `Repository` ทำเอง: ลบงาน → reminders + quest_entries ของงาน ·
  ลบโฟลเดอร์ → notes ทั้งหมด (+ งานถ้าเลือก "ลบงานไปด้วย", ไม่งั้น `project_id = NULL`) · ลบกล่องไอเดีย → `ideas.box_id = NULL`
- **การล้างประวัติ 30 วันอัตโนมัติ** (`_purgeExpiredCompleted`) ต้องเขียน tombstone ด้วย — ไม่งั้นอีกเครื่องที่ยังมีงานนั้นจะ sync กลับมา
- tombstone อายุ 180 วัน แล้วลบจริง · เครื่องที่ไม่ได้ sync นานกว่า 180 วันอาจชุบชีวิตงานที่ลบไปแล้ว → หน้าพรีวิวเตือนเมื่อไฟล์เก่ากว่า 180 วัน
- ความเสี่ยงหลักของ soft delete: ลืม `WHERE deleted_at IS NULL` ที่ใดที่หนึ่ง → ของที่ลบโผล่กลับ · กันด้วยเทสต์ 1 ตัวต่อ list method

---

## 5. ตัวตั้งเวลาแจ้งเตือนบน Windows (`ReminderScheduler`)

```
ทุก 30 วินาที (Timer.periodic) และทันทีหลัง AppState เปลี่ยน:
  now = DateTime.now()
  สำหรับแต่ละ reminder ที่ enabled และเจ้าของยังไม่เสร็จ/ไม่ถูกลบ:
    fireAt = งาน: effectiveDue − offset  · กิจวัตร: ครั้งถัดไปจาก Routine.occursOn/startOn (โค้ดเดิมใน AppState._nextRoutineFire)
    ถ้ามี snooze ของ occurrence นี้ → fireAt = snoozeUntil
    ถ้า reminder_checked_at < fireAt ≤ now → ยิง (alarm → การ์ดปลุก · ไม่ใช่ → show() พร้อมปุ่ม)
  reminder_checked_at = now
```
- ใช้ **การไล่ทุก 30 วินาที** แทน Timer ตัวเดียวไปยังเวลาถัดไป: เครื่องหลับ/ตื่น/เปลี่ยนเวลา/เปลี่ยน timezone ไม่ทำให้พลาด ·
  งานหลักหมื่นชิ้นก็ยังเป็นแค่ลูปในหน่วยความจำ (ceiling: ถ้าเกิน ~50k reminder ค่อยเปลี่ยนเป็น heap)
- ตอนเปิดแอป: ช่วง `(reminder_checked_at, now]` ที่ยิงไม่ได้เพราะแอปปิด → **สรุปเป็นแจ้งเตือนเดียว** "พลาดการเตือน N รายการ [ดู]" (ไม่ยิงทีละอัน)
- ปุ่มบนแจ้งเตือน: `payload = "task:<uid>"` / `"routine:<uid>@<occurrence>"` · `เสร็จแล้ว` → `AppState.toggleTaskDone` ·
  `เลื่อน` → เขียน `settings.snooze` · `เปิด` → แสดงหน้าต่างหลักที่งานนั้น (วันนี้ payload ส่งไปแต่ไม่มีใครรับ — ต้องเพิ่มตัวรับ ทั้ง Android และ Windows)
- เสียงปลุกบน PC: `PlaySound` (winmm ผ่าน `win32` ที่มีอยู่แล้ว) แบบ `SND_ASYNC|SND_LOOP` · รับเฉพาะ `.wav` (เสียงระบบ Windows หรือไฟล์ที่ผู้ใช้เลือก
  คัดลอกเข้าโฟลเดอร์ข้อมูล) — ไม่เพิ่มแพ็กเกจเสียง
- Android: **ไม่เปลี่ยน** — ยัง `zonedSchedule` + `matchDateTimeComponents` เหมือนเดิม

---

## 6. เวอร์ชัน — กติกาการ bump

### 6.1 หกชนิด อย่าปน (ECO-G3)

| เวอร์ชัน | อยู่ที่ | ตอนนี้ → เสนอ |
|---|---|---|
| app version | `pubspec.yaml version:` **และ** `AppInfo.version`/`buildNumber` (`lib/app_info.dart`) — `test/update_test.dart` ตรวจว่าตรงกัน | `1.5.1+8` → **`2.0.0+9`** |
| schema SQLite | `AppDatabase.schemaVersion` | 4 → **5** |
| ไฟล์สำรองเก่า | `BackupService.formatVersion` (`ourobask-backup`) | 4 → **หยุดที่ 4** (อ่านอย่างเดียว) |
| `our.tasks` | `formatVersion` ในไฟล์ | — → **`1.0`** |
| `ecoProtocol` / MCP revision | `eco.json` ของ Ourobask (06 §5) | — → `1` / `2025-11-25` |
| `ecoContract` | `eco/eco.lock.json` | — → `eco-v0.x` ตามที่ pin |

### 6.2 กติกา

1. **เวอร์ชันเดียวทั้ง Android และ Windows** · tag เดียว `vX.Y.Z` · release เดียวมีทั้ง APK และ zip Windows (06 §5)
   — เพราะ `lib/` เดียวกัน และตัวอัปเดต APK อ่าน `releases/latest`: ถ้ามี release ที่มีแต่ Windows มือถือจะเห็น "มีรุ่นใหม่" แต่ไม่มี APK
2. `buildNumber` (`+B`) เพิ่มทุก release ห้ามซ้ำ (ตัวอัปเดตบน Android เทียบค่านี้) · Windows ได้ค่านี้เข้า `FLUTTER_BUILD_NUMBER` ของ runner อัตโนมัติ
3. bump `pubspec.yaml` กับ `AppInfo` ใน commit เดียวกันเสมอ (CLAUDE.md) — ใช้ skill `version-update` ถ้ามี
4. ตารางตัดสินใจ:

| การเปลี่ยน | app | schema | `our.tasks` |
|---|---|---|---|
| แก้บั๊ก/UI ไม่แตะข้อมูล | Z | — | — |
| ฟีเจอร์ใหม่ที่เพิ่มคอลัมน์ optional | Y | +1 (migration additive) | MINOR ถ้าส่งออกฟิลด์ใหม่ (ECO-R3) |
| ฟิลด์บังคับใหม่ / เปลี่ยนความหมาย / ลบฟิลด์ | X | +1 | MAJOR + dual-read 3 ขั้น (ECO-R23–R26) |
| PC + schema v5 + ไฟล์รูปแบบใหม่ (รอบนี้) | **X → 2.0.0** | 5 | 1.0 |

เหตุผลที่ 2.0.0: มือถือรุ่น 1.x **นำเข้าไฟล์จาก 2.x ไม่ได้** (`BackupService.parse` จะเห็น `format` ไม่ใช่ `ourobask-backup` → "ไม่ใช่ไฟล์สำรองของ Ourobask") —
ผู้ใช้ต้องอัปเดตมือถือก่อนใช้ร่วมกับ PC · major bump บอกเรื่องนี้ ❓ → [Grill Q6](./07-grill-me.md)

5. เวอร์ชันเก่าเปิดฐานข้อมูล schema ใหม่กว่า → ปฏิเสธ ไม่ downgrade (ECO-K7, 02 §5)

---

## 7. เทสต์ที่ต้องมี (ไม่ต้องใช้อุปกรณ์ — `flutter test` ใน CI เดิม)

| เทสต์ | จับอะไร |
|---|---|
| `our_tasks_codec_test.dart` | ส่งออก → นำเข้า → ส่งออก ได้ไฟล์เท่าเดิม (ยกเว้น `exportedAt`) · `uid` คงเดิม (ECO-R8) · เงิน `"1200.50"` ไม่กลายเป็น `1200.5` · วันทั้งวันไม่เลื่อน |
| `merge_test.dart` | รวมไฟล์เดิมสองครั้ง = จำนวนแถวเท่าเดิม · ใหม่กว่าชนะ · เท่ากันตัดสินด้วย deviceId · tombstone ชนะการแก้ที่เก่ากว่า |
| `soft_delete_test.dart` | ทุก list method ของ `Repository` ไม่คืนแถวที่ `deleted_at` ไม่ว่าง |
| `reminder_scheduler_test.dart` | `fireAt` ของงาน/กิจวัตรรายสัปดาห์/รายเดือน (วันที่ 31 ในเดือนที่มี 30 วัน) · การเตือนที่พลาดถูกนับ ไม่ยิงซ้ำ |
| fixture Eco (06 §6) | `our.tasks` 1.0 ใน `.zeco` ผ่าน validator ของสัญญา |

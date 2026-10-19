# Ourobask PC + Eco — เอกสารออกแบบ

> **สถานะ: ออกแบบ ยังไม่สร้าง** · ร่าง 2026-10-18 · ไม่มีโค้ดใน `lib/` ถูกแก้จากรอบนี้
> สัญญากลางของ Eco: `Zydraxyl-HUB/Design/eco/ECO-CONTRACT.md` (อ้างด้วยรหัส เช่น ECO-R10)
> research ดิบ: `Zydraxyl-HUB/Design/eco/research/` (กลุ่ม C แท็ก `[OUR]` + `T5-eco-research.md`)

## Ourobask PC คืออะไร

Ourobask วันนี้เป็นแอป Flutter บน Android เก็บ Task / Quest / Routine / Idea / Note ใน SQLite ในเครื่อง
**Ourobask PC** คือ build Windows ของ `lib/` ชุดเดียวกัน ที่เพิ่ม "การมีตัวตนบนเดสก์ท็อป" — ไอคอนถาด, โน้ตบนหน้าจอ,
การแจ้งเตือนบนจอ, รายการงานย่อ และปุ่มเพิ่มงานด่วนจากทุกที่ — และเป็นสมาชิกของ Zydraxyl Eco:
ให้ **Z.I.Z** อ่านงานที่ค้าง เสนองานที่ช่วยทำ แล้วให้ผู้ใช้กดยืนยัน ผ่าน MCP (ECO-C4–C6) และส่งออก/นำเข้า `our.tasks` (ECO-I3)

## สรุปการตัดสินใจหลัก (ทุกข้อเป็น "เสนอ" จนเจ้าของตอบ Grill-me)

| เรื่อง | ข้อเสนอ | ที่มา |
|---|---|---|
| Stack | Flutter Windows desktop จาก `lib/` เดิม · ไม่ fork · ไม่ใช้ Electron | coordinator default 2 · `T1-C` §4.6 |
| process | **process เดียว** = ผู้เขียน SQLite คนเดียว · โน้ตบนจอเป็นหน้าต่างลูกของ process เดียวกัน | ECO-C5 · `T3-C` X2 |
| การแจ้งเตือน | **ตัวตั้งเวลาในแอป** (แอปอยู่ในถาด) + `show()` ทันทีเมื่อถึงเวลา — ไม่พึ่ง `zonedSchedule` บน Windows · ไม่ต้อง MSIX | `T3-C` §4.1 → [Grill Q2](./07-grill-me.md) |
| มือถือ ↔ PC | schema v5: `uid` + `updated_at` + `deleted_at` ทุกตาราง · merge ด้วย `uid` แบบ last-writer-wins · ไม่ซ้ำแถวอีก | `T3-C` §4.4 |
| ไฟล์ Eco | `our.tasks` 1.0 = ไฟล์สำรองรุ่นใหม่ด้วย (serializer ตัวเดียว) · ห่อเป็น `.zeco` เมื่อส่งใน Eco | ECO-I3, ECO-B* |
| Z.I.Z | งานติดสถานะ `agent_state` · Z.I.Z ส่งผลกลับเป็น proposal → ผู้ใช้ตรวจ → apply · Z.I.Z ติ๊ก "เสร็จ" เองไม่ได้ | ECO-S2 · [Grill Q5](./07-grill-me.md) |
| release | tag `v*` เดิม · release เดียวมีทั้ง APK และ `ourobask-vX.Y.Z-windows-x64-portable.zip` | ECO-K3/K4 |

## ดัชนีเอกสาร (ลำดับการอ่าน)

| # | ไฟล์ | อ่านเพื่อ |
|---|---|---|
| 1 | [`01-research-summary.md`](./01-research-summary.md) | แอป/ไลบรารีที่ศึกษา ยืมอะไร เลี่ยงอะไร · ข้อจำกัด Windows ที่ research เจอ |
| 2 | [`02-architecture.md`](./02-architecture.md) | stack, process model, ชั้นโค้ด, โฟลเดอร์ใหม่, ตำแหน่งไฟล์ข้อมูลบน Windows |
| 3 | [`03-features.md`](./03-features.md) | รายการฟีเจอร์ MVP / v1 / later พร้อมเหตุผล |
| 4 | [`04-internals.md`](./04-internals.md) | schema v5, ฟิลด์ agent-ready, merge/sync, ตัวตั้งเวลาแจ้งเตือน, รูปแบบ `our.tasks`, version bump |
| 5 | [`05-ux-ui.md`](./05-ux-ui.md) | ถาด, โน้ตบนจอ, แจ้งเตือน, รายการย่อ, เพิ่มด่วน, ส่งงานให้ Z.I.Z, ธีม Eco |
| 6 | [`06-eco-integration.md`](./06-eco-integration.md) | `.zeco`, MCP tools, locator, release asset ใน `eco.json`, fixture, ข้อเสนอเพิ่มเข้าสัญญา |
| 7 | [`07-grill-me.md`](./07-grill-me.md) | 13 คำถามที่เจ้าของต้องตัดสิน |

## ขอบเขต

- **ใน:** Windows x64 (Eco v1 = PC เท่านั้น) · การเปลี่ยน schema/ไฟล์สำรองที่ Android ต้องรับด้วย (เพราะ `lib/` เดียวกัน)
- **นอก:** macOS/Linux (later) · บัญชี/คลาวด์ · ปรับหน้าตาฝั่งมือถือ (คงเดิมจนกว่าจะมีรอบแยก)
- Ourobask **ไม่มี chain** ของตัวเอง และไม่ต้องสร้าง — รับสัญญา Eco แบบ pull-pin (ECO-G2)

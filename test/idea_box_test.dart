import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourobask/data/backup.dart';
import 'package:ourobask/data/models.dart';
import 'package:ourobask/ui/widgets/idea_contents.dart';

void main() {
  Idea idea(int id, {int? boxId}) =>
      Idea(id: id, content: 'ไอเดีย $id', boxId: boxId);

  group('กล่องไอเดียตามหมวดหมู่', () {
    test('กล่องหลักรวมไอเดียทุกใบ ไม่ว่าจัดหมวดแล้วหรือยัง', () {
      final List<Idea> pile = <Idea>[
        idea(1),
        idea(2, boxId: 7),
        idea(3, boxId: 8),
      ];
      expect(ideasInBox(pile, null).map((Idea i) => i.id), <int>[1, 2, 3]);
    });

    test('กล่องหมวดหมู่เห็นเฉพาะไอเดียที่จัดใส่ไว้', () {
      final List<Idea> pile = <Idea>[
        idea(1),
        idea(2, boxId: 7),
        idea(3, boxId: 8),
        idea(4, boxId: 7),
      ];
      expect(ideasInBox(pile, 7).map((Idea i) => i.id), <int>[2, 4]);
      expect(ideasInBox(pile, 8).map((Idea i) => i.id), <int>[3]);
      expect(ideasInBox(pile, 99), isEmpty);
    });

    test('ไอเดียที่ยังไม่จัดหมวดอยู่ในกล่องหลักอย่างเดียว', () {
      final Idea plain = idea(1);
      expect(plain.isFiled, isFalse);
      expect(idea(2, boxId: 3).isFiled, isTrue);
    });

    test('บันทึกและอ่านกล่องกลับมาได้ครบ', () {
      final IdeaBox box = IdeaBox(
        id: 4,
        name: 'ของอยากซื้อ',
        color: kPalette[6],
        iconIndex: 3,
        sortOrder: 2,
        createdAt: DateTime(2026, 5, 1),
      );
      final IdeaBox copy = IdeaBox.fromMap(box.toMap());
      expect(copy.id, 4);
      expect(copy.name, 'ของอยากซื้อ');
      expect(copy.color, kPalette[6]);
      expect(copy.iconIndex, 3);
      expect(copy.sortOrder, 2);
      expect(copy.createdAt, DateTime(2026, 5, 1));
      expect(copy.icon, kIdeaBoxIcons[3]);
    });

    test('ไอคอนของกล่องวนกลับมาเมื่อ index เกินจำนวนที่มี', () {
      expect(ideaBoxIconAt(kIdeaBoxIcons.length), kIdeaBoxIcons.first);
    });

    test('ตัวกรองการแสดงผลลิสไอเดีย', () {
      final List<Idea> pile = <Idea>[
        idea(1),
        idea(2, boxId: 7),
        idea(3, boxId: 8),
        idea(4),
      ];
      expect(
        filterIdeasByCategory(pile, IdeaListFilter.all).map((Idea i) => i.id),
        <int>[1, 2, 3, 4],
      );
      expect(
        filterIdeasByCategory(pile, IdeaListFilter.unfiled).map((Idea i) => i.id),
        <int>[1, 4],
      );
      expect(
        filterIdeasByCategory(pile, IdeaListFilter.filed).map((Idea i) => i.id),
        <int>[2, 3],
      );
    });

    test('ป้ายชื่อของตัวกรองแต่ละแบบ', () {
      expect(IdeaListFilter.all.label, 'แสดงทั้งหมด');
      expect(IdeaListFilter.unfiled.label, 'ไม่มีหมวดหมู่');
      expect(IdeaListFilter.filed.label, 'มีหมวดหมู่');
    });

    test('ไอเดียเก็บกล่องที่จัดใส่ไว้ลงฐานข้อมูลด้วย', () {
      final Idea filed = Idea(id: 1, content: 'ทำแอป', boxId: 9);
      expect(filed.toMap()['box_id'], 9);
      expect(Idea.fromMap(filed.toMap()).boxId, 9);
    });

    test('ข้อมูลเก่าที่ยังไม่มีคอลัมน์กล่อง อ่านเป็นยังไม่จัดหมวด', () {
      final Map<String, Object?> legacy = <String, Object?>{
        'id': 1,
        'content': 'ไอเดียเก่า',
        'color': kPalette[4],
        'created_at': DateTime(2026, 1, 1).millisecondsSinceEpoch,
      };
      expect(Idea.fromMap(legacy).boxId, isNull);
    });
  });

  group('ไฟล์สำรองที่มีกล่องหมวดหมู่', () {
    test('อ่านกล่องและไอเดียที่จัดใส่ไว้กลับมาได้', () {
      final String json = jsonEncode(<String, Object?>{
        'format': BackupService.magic,
        'version': BackupService.formatVersion,
        'ideas': <Object?>[Idea(id: 1, content: 'ทำแอป', boxId: 2).toMap()],
        'idea_boxes': <Object?>[IdeaBox(id: 2, name: 'งานอดิเรก').toMap()],
      });

      final BackupPayload payload = BackupService.parse(json);
      expect(payload.ideaBoxes.single.name, 'งานอดิเรก');
      expect(payload.ideas.single.boxId, 2);
      expect(payload.counts.ideaBoxes, 1);
    });

    test('ไฟล์สำรองรุ่นก่อนหน้าที่ยังไม่มีกล่อง อ่านได้ตามปกติ', () {
      final String json = jsonEncode(<String, Object?>{
        'format': BackupService.magic,
        'version': 3,
        'ideas': <Object?>[Idea(id: 1, content: 'ทำแอป').toMap()],
      });

      final BackupPayload payload = BackupService.parse(json);
      expect(payload.ideaBoxes, isEmpty);
      expect(payload.ideas.single.boxId, isNull);
    });
  });

  group('การเลือกไอเดียในกล่อง', () {
    test('แตะเพื่อเลือกและแตะซ้ำเพื่อเอาออก', () {
      final IdeaSelection selection = IdeaSelection();
      addTearDown(selection.dispose);
      expect(selection.isEmpty, isTrue);
      selection.toggle(1);
      selection.toggle(2);
      expect(selection.length, 2);
      expect(selection.contains(1), isTrue);
      selection.toggle(1);
      expect(selection.contains(1), isFalse);
      expect(selection.length, 1);
    });

    test('ไอเดียที่ไม่มี id เลือกไม่ได้', () {
      final IdeaSelection selection = IdeaSelection();
      addTearDown(selection.dispose);
      selection.toggle(null);
      expect(selection.isEmpty, isTrue);
      expect(selection.contains(null), isFalse);
    });

    testWidgets('ใบที่หายไปจากกองถูกปลดออกจากการเลือกให้เอง', (
      WidgetTester tester,
    ) async {
      final IdeaSelection selection = IdeaSelection();
      addTearDown(selection.dispose);
      selection.toggle(1);
      selection.toggle(2);

      int notified = 0;
      selection.addListener(() => notified++);

      // retain ถูกเรียกระหว่าง build ของรายการไอเดีย จึงแจ้งผู้ฟังตอนเฟรมนั้นจบ
      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            selection.retain(<int?>[2, 3]);
            return const SizedBox.shrink();
          },
        ),
      );
      expect(selection.ids, <int>{2});
      expect(notified, 1);
    });
  });
}

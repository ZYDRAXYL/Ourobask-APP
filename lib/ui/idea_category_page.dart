import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import 'widgets/common.dart';
import 'widgets/idea_contents.dart';
import 'widgets/idea_widgets.dart';

/// กล่องหมวดหมู่หนึ่งใบ — เปิดอยู่เสมอ เพราะผู้ใช้เปิดกล่องหลักเข้ามาแล้ว
///
/// ไอเดียในนี้เป็นส่วนหนึ่งของกล่องหลักด้วย กล่องหลักยังรวมทุกใบไว้เหมือนเดิม
class IdeaCategoryPage extends StatefulWidget {
  const IdeaCategoryPage({super.key, required this.boxId});

  final int boxId;

  @override
  State<IdeaCategoryPage> createState() => _IdeaCategoryPageState();
}

class _IdeaCategoryPageState extends State<IdeaCategoryPage> {
  final IdeaSelection _selection = IdeaSelection();
  final Random _random = Random();
  int? _lastRandomId;

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  Future<void> _addIdea() async {
    final Idea? idea = await showIdeaEditor(context, boxId: widget.boxId);
    if (idea == null || !mounted) return;
    showSnack(
      context,
      idea.boxId == widget.boxId
          ? 'หย่อนไอเดียลงกล่องนี้แล้ว'
          : 'เพิ่มไอเดียแล้ว (จัดไว้ในอีกกล่องหนึ่ง)',
    );
  }

  Future<void> _randomIdea(IdeaBox box) async {
    _lastRandomId = await drawRandomIdea(
      context,
      pile: context.read<AppState>().ideasOfBox(box.id),
      excludeId: _lastRandomId,
      random: _random,
      emptyMessage: 'กล่องนี้ยังว่าง ลองหย่อนไอเดียลงไปก่อน',
    );
  }

  Future<void> _editBox(IdeaBox box) async {
    final int before = context.read<AppState>().ideaBoxes.length;
    await showIdeaBoxEditor(context, box: box);
    if (!mounted) return;
    // กล่องถูกลบทิ้งจากในแผ่นแก้ไข — ไม่มีอะไรให้ดูต่อแล้ว
    if (context.read<AppState>().ideaBoxes.length < before) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final IdeaBox? box = state.ideaBoxById(widget.boxId);

    if (box == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('กล่องไอเดีย')),
        body: const EmptyState(
          icon: Icons.inventory_2_rounded,
          title: 'ไม่พบกล่องนี้',
          message: 'กล่องนี้อาจถูกลบไปแล้ว — ไอเดียข้างในยังอยู่ในกล่องหลัก',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Icon(box.icon, color: Color(box.color), size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(box.name, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'สุ่มไอเดียในกล่องนี้',
            icon: const Icon(Icons.casino_rounded),
            onPressed: () => _randomIdea(box),
          ),
          IconButton(
            tooltip: 'แก้ไขกล่อง',
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => _editBox(box),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addIdea,
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('หย่อนไอเดีย'),
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _selection,
        builder: (BuildContext context, _) => _selection.isEmpty
            ? const SizedBox.shrink()
            : IdeaSelectionBar(selection: _selection, box: box),
      ),
      body: IdeaContents(selection: _selection, box: box),
    );
  }
}

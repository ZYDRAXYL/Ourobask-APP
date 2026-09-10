import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import 'idea_category_page.dart';
import 'widgets/common.dart';
import 'widgets/idea_contents.dart';
import 'widgets/idea_widgets.dart';

/// กล่องไอเดีย — โน้ตข้างในจะไม่แสดงจนกว่าจะเปิดกล่อง
///
/// หน้านี้คือ "กล่องหลัก" ซึ่งเป็นกล่องกลางที่รวมไอเดียทุกใบไว้เสมอ
/// ส่วนกล่องหมวดหมู่ที่ผู้ใช้สร้างเพิ่มจะอยู่บนชั้นวางด้านในกล่องหลัก
/// แตะเข้าไปดูทีละกล่องได้ที่ [IdeaCategoryPage]
class IdeaBoxPage extends StatefulWidget {
  const IdeaBoxPage({super.key});

  @override
  State<IdeaBoxPage> createState() => _IdeaBoxPageState();
}

class _IdeaBoxPageState extends State<IdeaBoxPage> {
  bool _open = false;
  final IdeaSelection _selection = IdeaSelection();
  final Random _random = Random();

  /// ใบที่เพิ่งสุ่มได้ ใช้กันไม่ให้สุ่มซ้ำใบเดิมติดกัน
  int? _lastRandomId;

  /// เหมือน [_lastRandomId] แต่แยกเก็บเป็นรายกล่องหมวดหมู่
  final Map<int, int?> _lastRandomIdByBox = <int, int?>{};

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  void _toggleBox() {
    setState(() {
      _open = !_open;
      if (!_open) _selection.clear();
    });
  }

  Future<void> _addIdea() async {
    final Idea? idea = await showIdeaEditor(context);
    if (idea == null || !mounted) return;
    showSnack(context, _open ? 'เพิ่มไอเดียแล้ว' : 'หย่อนไอเดียลงกล่องแล้ว');
  }

  /// สุ่มไอเดียหนึ่งใบจากกองทั้งหมดในกล่องหลัก
  Future<void> _randomIdea() async {
    _lastRandomId = await drawRandomIdea(
      context,
      pile: context.read<AppState>().ideas,
      excludeId: _lastRandomId,
      random: _random,
    );
  }

  void _openCategory(IdeaBox box) {
    final int? id = box.id;
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => IdeaCategoryPage(boxId: id)),
    );
  }

  /// หย่อนไอเดียลงกล่องหมวดหมู่นี้โดยตรง ไม่ต้องเปิดกล่องหลักก่อน
  Future<void> _dropIntoBox(IdeaBox box) async {
    final int? id = box.id;
    if (id == null) return;
    final Idea? idea = await showIdeaEditor(context, boxId: id);
    if (idea == null || !mounted) return;
    showSnack(context, 'หย่อนไอเดียลงกล่อง "${box.name}" แล้ว');
  }

  /// สุ่มไอเดียหนึ่งใบจากกองในกล่องหมวดหมู่นี้เท่านั้น
  Future<void> _randomInBox(IdeaBox box) async {
    final int? id = box.id;
    if (id == null) return;
    _lastRandomIdByBox[id] = await drawRandomIdea(
      context,
      pile: context.read<AppState>().ideasOfBox(id),
      excludeId: _lastRandomIdByBox[id],
      random: _random,
      emptyMessage: 'กล่องนี้ยังว่าง ลองหย่อนไอเดียลงไปก่อน',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('กล่องไอเดีย'),
        actions: <Widget>[
          if (_open)
            IconButton(
              tooltip: 'สุ่มไอเดียหนึ่งใบ',
              icon: const Icon(Icons.casino_rounded),
              onPressed: _randomIdea,
            ),
          if (_open)
            TextButton.icon(
              onPressed: _toggleBox,
              icon: const Icon(Icons.inventory_2_rounded, size: 18),
              label: const Text('ปิดกล่อง'),
            ),
        ],
      ),
      // กล่องปิดอยู่จะใช้ปุ่ม "หย่อนไอเดีย" กลางจอแทน FAB
      floatingActionButton: _open
          ? FloatingActionButton.extended(
              onPressed: _addIdea,
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('หย่อนไอเดีย'),
            )
          : null,
      bottomNavigationBar: ListenableBuilder(
        listenable: _selection,
        builder: (BuildContext context, _) => _selection.isEmpty
            ? const SizedBox.shrink()
            : IdeaSelectionBar(selection: _selection),
      ),
      body: _open
          ? IdeaContents(
              selection: _selection,
              onOpenBox: _openCategory,
              onCloseBox: _toggleBox,
            )
          : _ClosedBox(
              onOpen: _toggleBox,
              onDrop: _addIdea,
              onRandom: _randomIdea,
              onOpenBox: _openCategory,
              onDropBox: _dropIntoBox,
              onRandomBox: _randomInBox,
            ),
    );
  }
}

/// สไตล์ปุ่มเล็กใต้ปุ่ม "หย่อนไอเดีย" — ใช้ร่วมกันเพื่อให้ทุกปุ่มขนาดเท่ากัน
final ButtonStyle _smallBoxButtonStyle = FilledButton.styleFrom(
  elevation: 2,
  minimumSize: Size.zero,
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
);

/// กล่องปิด — ตั้งใจไม่แสดงเนื้อหาหรือจำนวนไอเดียข้างใน
///
/// ปุ่ม "หย่อนไอเดีย" อยู่กลางจอและอยู่หน้ากล่อง ส่วนปุ่ม "เปิดกล่อง"
/// กับ "สุ่มไอเดีย" เป็นปุ่มเล็กกว่าอยู่ใต้ปุ่มหย่อนไอเดีย
/// โดยสองปุ่มล่างกว้างเท่ากันเสมอ
///
/// ใต้กล่องหลักยังแสดงกล่องหมวดหมู่ที่ผู้ใช้สร้างไว้ (ถ้ามี) แต่ละกล่องมีปุ่ม
/// "หย่อน" กับ "สุ่ม" ในตัว เพื่อหย่อน/สุ่มไอเดียในกล่องนั้นได้ทันทีโดยไม่ต้อง
/// เปิดกล่องหลักก่อน
class _ClosedBox extends StatelessWidget {
  const _ClosedBox({
    required this.onOpen,
    required this.onDrop,
    required this.onRandom,
    required this.onOpenBox,
    required this.onDropBox,
    required this.onRandomBox,
  });

  final VoidCallback onOpen;
  final VoidCallback onDrop;
  final VoidCallback onRandom;
  final ValueChanged<IdeaBox> onOpenBox;
  final ValueChanged<IdeaBox> onDropBox;
  final ValueChanged<IdeaBox> onRandomBox;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppState state = context.watch<AppState>();
    final List<IdeaBox> boxes = state.ideaBoxes;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        _BoxArt(onTap: onOpen),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            FilledButton.icon(
                              onPressed: onDrop,
                              style: FilledButton.styleFrom(
                                elevation: 3,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              icon: const Icon(Icons.edit_note_rounded),
                              label: const Text('หย่อนไอเดีย'),
                            ),
                            const SizedBox(height: 14),
                            // สองปุ่มนี้อยู่ใน IntrinsicWidth + stretch จึงกว้างเท่ากัน
                            // ตามปุ่มที่ป้ายยาวกว่า และสูงเท่ากันเพราะใช้สไตล์เดียวกัน
                            IntrinsicWidth(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  FilledButton.tonalIcon(
                                    onPressed: onOpen,
                                    style: _smallBoxButtonStyle,
                                    icon: const Icon(Icons.lock_open_rounded, size: 15),
                                    label: const Text('เปิดกล่อง'),
                                  ),
                                  const SizedBox(height: 10),
                                  FilledButton.tonalIcon(
                                    onPressed: onRandom,
                                    style: _smallBoxButtonStyle,
                                    icon: const Icon(Icons.casino_rounded, size: 15),
                                    label: const Text('สุ่มไอเดีย'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'กล่องปิดอยู่',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ไอเดียข้างในจะไม่แสดงจนกว่าจะเปิดกล่อง\nหย่อนไอเดียใหม่ได้ตลอดโดยไม่ต้องเปิด',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (boxes.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 32),
                      Text(
                        'กล่องหมวดหมู่',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'หย่อนหรือสุ่มไอเดียในแต่ละกล่องได้ทันที โดยไม่ต้องเปิดกล่องหลัก',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: boxes
                            .map(
                              (IdeaBox box) => _ClosedCategoryCard(
                                box: box,
                                count: state.ideaCountOfBox(box.id),
                                onOpen: () => onOpenBox(box),
                                onDrop: () => onDropBox(box),
                                onRandom: () => onRandomBox(box),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// การ์ดกล่องหมวดหมู่หนึ่งใบบนหน้ากล่องปิด
///
/// แตะที่ตัวการ์ดเพื่อเปิดดูกล่องนั้น ส่วนปุ่มเล็กสองปุ่มด้านล่างให้หย่อน/สุ่ม
/// ไอเดียในกล่องนี้ได้ทันทีโดยไม่ต้องเข้าไปเปิดดูก่อน
class _ClosedCategoryCard extends StatelessWidget {
  const _ClosedCategoryCard({
    required this.box,
    required this.count,
    required this.onOpen,
    required this.onDrop,
    required this.onRandom,
  });

  final IdeaBox box;
  final int count;
  final VoidCallback onOpen;
  final VoidCallback onDrop;
  final VoidCallback onRandom;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = Color(box.color);
    return Container(
      width: 136,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(box.icon, size: 16, color: color),
                    const Spacer(),
                    Text(
                      '$count',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  box.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: IconButton.filledTonal(
                  tooltip: 'หย่อนไอเดียลงกล่องนี้',
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: onDrop,
                  icon: const Icon(Icons.edit_note_rounded),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: IconButton.filledTonal(
                  tooltip: 'สุ่มไอเดียในกล่องนี้',
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: onRandom,
                  icon: const Icon(Icons.casino_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// รูปกล่องที่ปิดฝาอยู่ (แตะที่กล่องก็เปิดได้เหมือนกัน)
class _BoxArt extends StatelessWidget {
  const _BoxArt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // สูงพอให้ปุ่มทั้งสามใบ (หย่อนไอเดีย + เปิดกล่อง + สุ่มไอเดีย) วางซ้อนอยู่
        // ในตัวกล่องได้พอดี ไม่เกยขอบกล่องเหมือนตอนกล่องเตี้ยกว่านี้
        width: 240,
        height: 250,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(18),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            Container(
              height: 42,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 44,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 22,
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

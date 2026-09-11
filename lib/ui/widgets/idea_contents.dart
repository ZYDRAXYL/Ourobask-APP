import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import 'common.dart';
import 'idea_widgets.dart';

/// ไอเดียที่ถูกเลือกไว้ในกล่องที่เปิดอยู่
///
/// แยกออกมาเป็น [ChangeNotifier] เพราะรายการไอเดียอยู่ใน body ของ Scaffold
/// แต่แถบปุ่มของการเลือกอยู่ที่ bottomNavigationBar ซึ่งเป็นคนละที่กัน
class IdeaSelection extends ChangeNotifier {
  final Set<int> _ids = <int>{};

  Set<int> get ids => Set<int>.unmodifiable(_ids);

  int get length => _ids.length;

  bool get isEmpty => _ids.isEmpty;

  bool contains(int? id) => id != null && _ids.contains(id);

  void toggle(int? id) {
    if (id == null) return;
    if (!_ids.remove(id)) _ids.add(id);
    notifyListeners();
  }

  void clear() {
    if (_ids.isEmpty) return;
    _ids.clear();
    notifyListeners();
  }

  /// ทิ้งใบที่ไม่อยู่ในกองแล้ว (เช่น ถูกลบหรือย้ายออกจากกล่องนี้ไป)
  void retain(Iterable<int?> availableIds) {
    final Set<int> available = availableIds.whereType<int>().toSet();
    if (_ids.every(available.contains)) return;
    _ids.retainWhere(available.contains);
    // เรียกระหว่าง build ของรายการไอเดีย จึงต้องรอให้เฟรมนี้จบก่อนค่อยแจ้ง
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }
}

/// เนื้อในของกล่องที่เปิดอยู่ — ใช้ร่วมกันทั้งกล่องหลักและกล่องหมวดหมู่
///
/// [box] == null คือกล่องหลัก ซึ่งรวมไอเดียทุกใบไว้เหมือนเดิม
/// และมีชั้นวางกล่องหมวดหมู่อยู่ด้านบนให้แตะเข้าไปดูทีละกล่อง
class IdeaContents extends StatelessWidget {
  const IdeaContents({
    super.key,
    required this.selection,
    this.box,
    this.onOpenBox,
    this.onCloseBox,
  });

  final IdeaSelection selection;
  final IdeaBox? box;

  /// แตะกล่องหมวดหมู่บนชั้นวาง (มีเฉพาะในกล่องหลัก)
  final ValueChanged<IdeaBox>? onOpenBox;

  /// ปุ่ม "ปิดกล่อง" ตอนกล่องหลักยังว่างเปล่า
  final VoidCallback? onCloseBox;

  bool get _isMain => box == null;

  Future<void> _createBox(BuildContext context) async {
    final IdeaBox? created = await showIdeaBoxEditor(context);
    if (created == null || !context.mounted) return;
    showSnack(context, 'สร้างกล่อง "${created.name}" แล้ว');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppState state = context.watch<AppState>();
    final List<IdeaBox> boxes = state.ideaBoxes;
    final List<Idea> ideas = state.ideasOfBox(box?.id);
    final IdeaListFilter filter = state.ideaListFilter;
    // ตัวกรอง "มี/ไม่มีหมวดหมู่" มีความหมายเฉพาะในกล่องหลักเท่านั้น
    // เพราะกล่องหมวดหมู่หนึ่งใบมีแต่ไอเดียที่จัดหมวดแล้วทั้งนั้น
    final List<Idea> visibleIdeas = _isMain
        ? filterIdeasByCategory(ideas, filter)
        : ideas;
    selection.retain(ideas.map((Idea i) => i.id));

    if (ideas.isEmpty && (!_isMain || boxes.isEmpty)) {
      return EmptyState(
        icon: Icons.lightbulb_outline_rounded,
        title: _isMain ? 'กล่องว่างเปล่า' : 'กล่องนี้ยังว่าง',
        message: _isMain
            ? 'กด "หย่อนไอเดีย" เพื่อเขียนไอเดียเก็บไว้ก่อน'
            : 'หย่อนไอเดียใหม่ลงกล่องนี้ '
                  'หรือเลือกไอเดียในกล่องหลักแล้วจัดเข้ามาก็ได้',
        // กล่องหมวดหมู่ที่ว่างไม่มีปุ่มอะไรให้กดเพิ่ม (ใช้ FAB หย่อนไอเดียแทน)
        action: _isMain
            ? Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () => _createBox(context),
                    icon: const Icon(Icons.add_box_rounded),
                    label: const Text('สร้างกล่องหมวดหมู่'),
                  ),
                  if (onCloseBox != null)
                    OutlinedButton.icon(
                      onPressed: onCloseBox,
                      icon: const Icon(Icons.inventory_2_rounded),
                      label: const Text('ปิดกล่อง'),
                    ),
                ],
              )
            : null,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 100),
      children: <Widget>[
        if (_isMain) ...<Widget>[
          const SectionHeader(
            title: 'กล่องหมวดหมู่',
            subtitle: 'แตะเพื่อเปิดกล่อง • แตะค้างเพื่อแก้ไข',
            icon: Icons.inventory_2_rounded,
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              ...boxes.map(
                (IdeaBox item) => IdeaBoxCard(
                  box: item,
                  count: state.ideaCountOfBox(item.id),
                  onTap: () => onOpenBox?.call(item),
                  onLongPress: () => showIdeaBoxEditor(context, box: item),
                ),
              ),
              NewIdeaBoxCard(onTap: () => _createBox(context)),
            ],
          ),
        ],
        SectionHeader(
          title: _isMain ? 'ไอเดียทั้งหมด' : 'ไอเดียในกล่องนี้',
          subtitle: _isMain
              ? 'กล่องหลักรวมไอเดียทุกใบ • แตะเพื่อเลือก • แตะค้างเพื่อแก้ไข'
              : 'แตะเพื่อเลือก • แตะค้างเพื่อแก้ไข',
          icon: Icons.lightbulb_rounded,
          color: box == null ? null : Color(box!.color),
          count: visibleIdeas.length,
          trailing: _isMain && ideas.isNotEmpty
              ? IdeaListFilterButton(
                  value: filter,
                  onChanged: (IdeaListFilter value) =>
                      context.read<AppState>().setIdeaListFilter(value),
                )
              : null,
        ),
        if (ideas.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text(
              'ยังไม่มีไอเดียในกล่องนี้ กด "หย่อนไอเดีย" เพื่อเขียนเก็บไว้ก่อน',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else if (visibleIdeas.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              children: <Widget>[
                Text(
                  'ไม่มีไอเดียตรงกับตัวกรอง "${filter.label}"',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => context.read<AppState>().setIdeaListFilter(
                    IdeaListFilter.all,
                  ),
                  child: const Text('แสดงทั้งหมด'),
                ),
              ],
            ),
          )
        else
          ListenableBuilder(
            listenable: selection,
            builder: (BuildContext context, _) => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: visibleIdeas
                  .map(
                    (Idea idea) => IdeaNoteCard(
                      idea: idea,
                      // ในกล่องหมวดหมู่ไม่ต้องติดป้ายซ้ำว่าอยู่กล่องไหน
                      box: _isMain ? state.ideaBoxById(idea.boxId) : null,
                      selected: selection.contains(idea.id),
                      onTap: () => selection.toggle(idea.id),
                      onLongPress: () => showIdeaEditor(context, idea: idea),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

/// แถบปุ่มที่โผล่ขึ้นมาตอนเลือกไอเดียไว้ (ใช้เป็น bottomNavigationBar)
class IdeaSelectionBar extends StatelessWidget {
  const IdeaSelectionBar({super.key, required this.selection, this.box});

  final IdeaSelection selection;

  /// กล่องที่กำลังเปิดอยู่ (null = กล่องหลัก) ใช้เป็นค่าตั้งต้นของการจัดเข้ากล่อง
  final IdeaBox? box;

  List<Idea> _selectedIdeas(AppState state) =>
      state.ideas.where((Idea i) => selection.contains(i.id)).toList();

  Future<void> _delete(BuildContext context) async {
    final AppState state = context.read<AppState>();
    final List<Idea> ideas = _selectedIdeas(state);
    if (ideas.isEmpty) return;
    final bool ok = await confirmDialog(
      context,
      title: 'ลบไอเดีย ${ideas.length} รายการ?',
      message: 'ไอเดียที่ลบแล้วจะกู้คืนไม่ได้',
      confirmLabel: 'ลบ',
      destructive: true,
    );
    if (!ok) return;
    for (final Idea idea in ideas) {
      await state.deleteIdea(idea);
    }
    selection.clear();
  }

  Future<void> _moveToBox(BuildContext context) async {
    final AppState state = context.read<AppState>();
    final List<Idea> ideas = _selectedIdeas(state);
    if (ideas.isEmpty) return;
    final IdeaBoxChoice? choice = await showIdeaBoxPicker(
      context,
      currentBoxId: box?.id,
      title: 'จัดไอเดีย ${ideas.length} ใบเข้ากล่องไหน?',
    );
    if (choice == null) return;
    await state.moveIdeasToBox(ideas, choice.boxId);
    selection.clear();
    if (!context.mounted) return;
    final IdeaBox? target = state.ideaBoxById(choice.boxId);
    showSnack(
      context,
      target == null
          ? 'เอาไอเดียออกจากกล่องหมวดหมู่แล้ว (ยังอยู่ในกล่องหลัก)'
          : 'จัดไอเดียเข้ากล่อง "${target.name}" แล้ว',
    );
  }

  Future<void> _convert(BuildContext context) async {
    final AppState state = context.read<AppState>();
    final List<Idea> ideas = _selectedIdeas(state);
    if (ideas.isEmpty) return;
    final IdeaConvertOptions? options = await showIdeaConvertSheet(
      context,
      count: ideas.length,
    );
    if (options == null) return;
    for (final Idea idea in ideas) {
      await state.convertIdeaToTask(
        idea,
        projectId: options.projectId,
        due: options.due,
        hasTime: options.hasTime,
        keepIdea: false,
      );
    }
    selection.clear();
    if (context.mounted) {
      showSnack(context, 'ย้าย ${ideas.length} ไอเดียไปเป็นงานแล้ว');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        children: <Widget>[
          Text('เลือกไว้ ${selection.length}'),
          // ปุ่มชิดขวาเสมอ และเลื่อนได้เมื่อจอแคบจนวางไม่พอ
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                children: <Widget>[
                  IconButton(
                    tooltip: 'ลบไอเดียที่เลือก',
                    color: Theme.of(context).colorScheme.error,
                    onPressed: () => _delete(context),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                  TextButton.icon(
                    onPressed: () => _moveToBox(context),
                    icon: const Icon(Icons.inventory_2_rounded, size: 18),
                    label: const Text('จัดเข้ากล่อง'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _convert(context),
                    icon: const Icon(Icons.move_to_inbox_rounded, size: 18),
                    label: const Text('เป็นงาน'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

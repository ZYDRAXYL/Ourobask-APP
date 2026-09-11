import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../utils/formatters.dart';
import '../idea_random_sheet.dart';
import 'common.dart';

/// กระดาษโน้ตหนึ่งใบในกล่องไอเดีย
class IdeaNoteCard extends StatelessWidget {
  const IdeaNoteCard({
    super.key,
    required this.idea,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    this.box,
  });

  final Idea idea;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  /// กล่องหมวดหมู่ที่ไอเดียใบนี้ถูกจัดใส่ไว้ (null = ยังไม่จัดหมวด หรือไม่ต้องแสดง)
  final IdeaBox? box;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = Color(idea.color);
    final double width = (MediaQuery.of(context).size.width - 38) / 2;
    final IdeaBox? filed = box;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: width,
        constraints: const BoxConstraints(minHeight: 92),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : Colors.transparent, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.sticky_note_2_rounded, size: 14, color: color),
                const Spacer(),
                if (selected) Icon(Icons.check_circle_rounded, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              idea.content,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            if (filed != null) ...<Widget>[
              IdeaBoxChip(box: filed),
              const SizedBox(height: 6),
            ],
            Text(
              Fmt.date(idea.createdAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ปุ่มเลือกตัวกรองการแสดงผลของลิสไอเดียในกล่องหลัก
/// (แสดงทั้งหมด / มีหมวดหมู่ / ไม่มีหมวดหมู่)
class IdeaListFilterButton extends StatelessWidget {
  const IdeaListFilterButton({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final IdeaListFilter value;
  final ValueChanged<IdeaListFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool active = value != IdeaListFilter.all;
    return PopupMenuButton<IdeaListFilter>(
      tooltip: 'ตัวกรองการแสดงผล',
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (BuildContext context) => IdeaListFilter.values
          .map(
            (IdeaListFilter option) => PopupMenuItem<IdeaListFilter>(
              value: option,
              child: Row(
                children: <Widget>[
                  if (option == value)
                    Icon(Icons.check_rounded, size: 18, color: theme.colorScheme.primary)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 8),
                  Text(option.label),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.filter_list_rounded,
              size: 16,
              color: active
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              value.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: active
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ป้ายเล็ก ๆ บอกว่าไอเดียใบนี้ถูกจัดอยู่ในกล่องหมวดหมู่ไหน
class IdeaBoxChip extends StatelessWidget {
  const IdeaBoxChip({super.key, required this.box});

  final IdeaBox box;

  @override
  Widget build(BuildContext context) {
    final Color color = Color(box.color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(box.icon, size: 11, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              box.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// กล่องหมวดหมู่หนึ่งใบบนชั้นวางในกล่องหลัก
class IdeaBoxCard extends StatelessWidget {
  const IdeaBoxCard({
    super.key,
    required this.box,
    required this.count,
    required this.onTap,
    this.onLongPress,
  });

  final IdeaBox box;
  final int count;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = Color(box.color);
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 138,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(box.icon, size: 18, color: color),
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
            const SizedBox(height: 8),
            Text(
              box.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// การ์ดจุด ๆ สำหรับสร้างกล่องหมวดหมู่ใหม่ (ขนาดเท่ากล่องอื่นบนชั้นวาง)
class NewIdeaBoxCard extends StatelessWidget {
  const NewIdeaBoxCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 138,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.add_box_rounded,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'สร้างกล่องใหม่',
              maxLines: 2,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// เขียน/แก้ไขไอเดีย พร้อมเลือกได้ว่าจะจัดใส่กล่องหมวดหมู่ไหน
///
/// [boxId] คือกล่องตั้งต้นของไอเดียใบใหม่ (null = ยังไม่จัดหมวด)
Future<Idea?> showIdeaEditor(BuildContext context, {Idea? idea, int? boxId}) async {
  final TextEditingController controller = TextEditingController(
    text: idea?.content ?? '',
  );
  int color = idea?.color ?? kPalette[4];
  int? targetBoxId = idea?.boxId ?? boxId;
  final AppState state = context.read<AppState>();

  final bool? saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => StatefulBuilder(
      builder: (BuildContext context, StateSetter setSheetState) {
        final List<IdeaBox> boxes = state.ideaBoxes;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    idea == null ? 'หย่อนไอเดียใหม่' : 'แก้ไขไอเดีย',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    minLines: 3,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: 'คิดอะไรอยู่? เขียนทิ้งไว้ก่อนได้เลย',
                    ),
                  ),
                  const SizedBox(height: 14),
                  ColorChoiceRow(
                    value: color,
                    onChanged: (int value) => setSheetState(() => color = value),
                  ),
                  if (boxes.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int?>(
                      initialValue: targetBoxId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'จัดใส่กล่อง',
                        helperText: 'ไอเดียยังอยู่ในกล่องหลักเสมอ',
                        prefixIcon: Icon(Icons.inventory_2_rounded),
                      ),
                      items: <DropdownMenuItem<int?>>[
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('กล่องหลัก (ยังไม่จัดหมวด)'),
                        ),
                        ...boxes.map(
                          (IdeaBox box) => DropdownMenuItem<int?>(
                            value: box.id,
                            child: Text(box.name, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                      onChanged: (int? value) =>
                          setSheetState(() => targetBoxId = value),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      if (idea != null)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () async {
                            await state.deleteIdea(idea);
                            if (context.mounted) Navigator.pop(context, false);
                          },
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          label: const Text('ลบ'),
                        ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('บันทึก'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  if (saved != true) return null;
  final String content = controller.text.trim();
  if (content.isEmpty) return null;
  final Idea result = idea ?? Idea(content: content);
  result
    ..content = content
    ..color = color
    ..boxId = targetBoxId;
  await state.saveIdea(result);
  return result;
}

/// สร้าง/แก้ไขกล่องหมวดหมู่ — คืนกล่องที่บันทึกแล้ว (null = ยกเลิกหรือลบทิ้ง)
Future<IdeaBox?> showIdeaBoxEditor(BuildContext context, {IdeaBox? box}) async {
  final TextEditingController controller = TextEditingController(text: box?.name ?? '');
  final AppState state = context.read<AppState>();
  int color = box?.color ?? paletteAt(state.ideaBoxes.length);
  int iconIndex = box?.iconIndex ?? 0;
  String? error;

  final bool? saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => StatefulBuilder(
      builder: (BuildContext context, StateSetter setSheetState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  box == null ? 'สร้างกล่องใหม่' : 'แก้ไขกล่อง',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'กล่องหมวดหมู่ช่วยจัดไอเดียเป็นกอง ๆ '
                  'แต่ทุกใบยังรวมอยู่ในกล่องหลักเหมือนเดิม',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'ชื่อกล่อง',
                    hintText: 'เช่น งานอดิเรก, ของอยากซื้อ',
                    errorText: error,
                    prefixIcon: const Icon(Icons.label_rounded),
                  ),
                  onChanged: (_) {
                    if (error != null) setSheetState(() => error = null);
                  },
                ),
                const SizedBox(height: 14),
                ColorChoiceRow(
                  value: color,
                  onChanged: (int value) => setSheetState(() => color = value),
                ),
                const SizedBox(height: 12),
                IdeaBoxIconRow(
                  value: iconIndex,
                  color: color,
                  onChanged: (int value) => setSheetState(() => iconIndex = value),
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    if (box != null)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () async {
                          final bool ok = await confirmIdeaBoxDelete(context, box);
                          if (!ok || !context.mounted) return;
                          Navigator.pop(context, false);
                        },
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('ลบกล่อง'),
                      ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        if (controller.text.trim().isEmpty) {
                          setSheetState(() => error = 'ตั้งชื่อกล่องก่อนนะ');
                          return;
                        }
                        Navigator.pop(context, true);
                      },
                      child: const Text('บันทึก'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  if (saved != true) return null;
  final String name = controller.text.trim();
  if (name.isEmpty) return null;
  final IdeaBox result = box ?? IdeaBox(name: name);
  result
    ..name = name
    ..color = color
    ..iconIndex = iconIndex;
  await state.saveIdeaBox(result);
  return result;
}

/// ยืนยันการลบกล่องหมวดหมู่ — ไอเดียข้างในไม่หายตาม แต่กลับไปอยู่ในกล่องหลัก
Future<bool> confirmIdeaBoxDelete(BuildContext context, IdeaBox box) async {
  final AppState state = context.read<AppState>();
  final int count = state.ideaCountOfBox(box.id);
  final bool ok = await confirmDialog(
    context,
    title: 'ลบกล่อง "${box.name}"?',
    message: count == 0
        ? 'กล่องนี้ยังไม่มีไอเดียข้างใน'
        : 'ไอเดีย $count ใบข้างในจะไม่ถูกลบ '
              'แต่จะกลับไปเป็นไอเดียที่ยังไม่จัดหมวดในกล่องหลัก',
    confirmLabel: 'ลบกล่อง',
    destructive: true,
  );
  if (!ok) return false;
  await state.deleteIdeaBox(box);
  return true;
}

/// แถวเลือกไอคอนของกล่องไอเดีย
class IdeaBoxIconRow extends StatelessWidget {
  const IdeaBoxIconRow({
    super.key,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final int value;
  final int color;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kIdeaBoxIcons.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int index) {
          final bool selected = index == value;
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onChanged(index),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? Color(color).withValues(alpha: 0.18)
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: selected ? Border.all(color: Color(color), width: 2) : null,
              ),
              child: Icon(
                kIdeaBoxIcons[index],
                color: selected ? Color(color) : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// กล่องปลายทางที่ผู้ใช้เลือกจาก [showIdeaBoxPicker]
///
/// ห่อไว้อีกชั้นเพื่อแยก "เลือกกล่องหลัก" ([boxId] == null) ออกจาก "ยกเลิก" (null)
class IdeaBoxChoice {
  const IdeaBoxChoice(this.boxId);

  /// null = กล่องหลัก (เอาไอเดียออกจากหมวด)
  final int? boxId;
}

/// เลือกกล่องหมวดหมู่ปลายทาง — สร้างกล่องใหม่จากในแผ่นนี้ได้เลย
Future<IdeaBoxChoice?> showIdeaBoxPicker(
  BuildContext context, {
  int? currentBoxId,
  String title = 'จัดเข้ากล่องไหน?',
}) {
  return showModalBottomSheet<IdeaBoxChoice>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext sheetContext) {
      final ThemeData theme = Theme.of(sheetContext);
      final AppState state = sheetContext.watch<AppState>();
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.inbox_rounded),
                    title: const Text('กล่องหลัก (ไม่จัดหมวด)'),
                    subtitle: Text(
                      'เก็บไว้ในกองกลาง — ตอนนี้ยังไม่จัดหมวด '
                      '${state.unfiledIdeaCount} ใบ',
                    ),
                    trailing: currentBoxId == null
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () =>
                        Navigator.pop(sheetContext, const IdeaBoxChoice(null)),
                  ),
                  ...state.ideaBoxes.map(
                    (IdeaBox box) => ListTile(
                      leading: Icon(box.icon, color: Color(box.color)),
                      title: Text(box.name, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${state.ideaCountOfBox(box.id)} ไอเดีย'),
                      trailing: currentBoxId == box.id
                          ? const Icon(Icons.check_rounded)
                          : null,
                      onTap: () => Navigator.pop(sheetContext, IdeaBoxChoice(box.id)),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_box_rounded),
                    title: const Text('สร้างกล่องใหม่'),
                    onTap: () async {
                      final IdeaBox? created = await showIdeaBoxEditor(sheetContext);
                      if (created?.id == null || !sheetContext.mounted) return;
                      Navigator.pop(sheetContext, IdeaBoxChoice(created!.id));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}

/// ตัวเลือกตอนย้ายไอเดียไปเป็นงาน
class IdeaConvertOptions {
  const IdeaConvertOptions({this.projectId, this.due, this.hasTime = false});

  final int? projectId;
  final DateTime? due;
  final bool hasTime;
}

/// ถามโฟลเดอร์ปลายทางและกำหนดส่งก่อนย้ายไอเดียไปเป็นงาน
Future<IdeaConvertOptions?> showIdeaConvertSheet(
  BuildContext context, {
  required int count,
}) {
  return showModalBottomSheet<IdeaConvertOptions>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => _ConvertSheet(count: count),
  );
}

class _ConvertSheet extends StatefulWidget {
  const _ConvertSheet({required this.count});

  final int count;

  @override
  State<_ConvertSheet> createState() => _ConvertSheetState();
}

class _ConvertSheetState extends State<_ConvertSheet> {
  int? _projectId;
  DateTime? _date;
  TimeOfDay? _time;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppState state = context.watch<AppState>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'ย้าย ${widget.count} ไอเดียไปเป็นงาน',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'เลือกโฟลเดอร์ปลายทางและกำหนดส่ง (ไม่บังคับ)',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              initialValue: _projectId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'โยนใส่โฟลเดอร์',
                prefixIcon: Icon(Icons.folder_rounded),
              ),
              items: <DropdownMenuItem<int?>>[
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('ไม่อยู่ในโฟลเดอร์'),
                ),
                ...state.projects.map(
                  (Project project) => DropdownMenuItem<int?>(
                    value: project.id,
                    child: Text(project.name, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (int? value) => setState(() => _projectId = value),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_rounded),
              title: const Text('วันครบกำหนด'),
              subtitle: Text(_date == null ? 'ไม่ระบุ' : Fmt.dateFull(_date!)),
              trailing: Wrap(
                children: <Widget>[
                  if (_date != null)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => setState(() {
                        _date = null;
                        _time = null;
                      }),
                    ),
                  TextButton(
                    onPressed: () async {
                      final DateTime now = DateTime.now();
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _date ?? now,
                        firstDate: DateTime(now.year - 1),
                        lastDate: DateTime(now.year + 10),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    child: const Text('เลือก'),
                  ),
                ],
              ),
            ),
            if (_date != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_rounded),
                title: const Text('เวลา'),
                subtitle: Text(_time == null ? 'ทั้งวัน' : '${Fmt.timeOfDay(_time!)} น.'),
                trailing: TextButton(
                  onPressed: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0),
                    );
                    if (picked != null) setState(() => _time = picked);
                  },
                  child: const Text('เลือก'),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    DateTime? due;
                    if (_date != null) {
                      due = _time == null
                          ? DateTime(_date!.year, _date!.month, _date!.day)
                          : DateTime(
                              _date!.year,
                              _date!.month,
                              _date!.day,
                              _time!.hour,
                              _time!.minute,
                            );
                    }
                    Navigator.pop(
                      context,
                      IdeaConvertOptions(
                        projectId: _projectId,
                        due: due,
                        hasTime: _time != null,
                      ),
                    );
                  },
                  child: const Text('ย้ายไปเป็นงาน'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// เอาไอเดียใบเดียวไปสร้างเป็นงานหรือโน้ต (ไอเดียจะออกจากกล่องไปเลย)
Future<void> createFromIdea(BuildContext context, Idea idea) async {
  final AppState state = context.read<AppState>();
  final IdeaTarget? target = await showIdeaTargetSheet(context);
  if (target == null || !context.mounted) return;

  if (target == IdeaTarget.task) {
    final IdeaConvertOptions? options = await showIdeaConvertSheet(context, count: 1);
    if (options == null) return;
    await state.convertIdeaToTask(
      idea,
      projectId: options.projectId,
      due: options.due,
      hasTime: options.hasTime,
    );
    if (context.mounted) showSnack(context, 'สร้างงานจากไอเดียนี้แล้ว');
    return;
  }

  if (state.projects.isEmpty) {
    showSnack(context, 'โน้ตต้องอยู่ในโฟลเดอร์งาน — สร้างโฟลเดอร์ก่อนนะ');
    return;
  }
  final int? projectId = await showNoteProjectPicker(context);
  if (projectId == null || !context.mounted) return;
  await state.convertIdeaToNote(idea, projectId: projectId);
  if (!context.mounted) return;
  final Project? project = state.projectById(projectId);
  showSnack(
    context,
    project == null
        ? 'สร้างโน้ตจากไอเดียนี้แล้ว'
        : 'สร้างโน้ตไว้ในโฟลเดอร์ "${project.name}" แล้ว',
  );
}

/// สุ่มไอเดียขึ้นมาหนึ่งใบจาก [pile] แล้วเปิดดูแบบอ่านอย่างเดียว
///
/// คืน id ของใบที่สุ่มได้ เพื่อเอาไปกันไม่ให้สุ่มซ้ำใบเดิมในครั้งถัดไป
/// (คืน [excludeId] เดิมถ้ากองว่าง)
Future<int?> drawRandomIdea(
  BuildContext context, {
  required List<Idea> pile,
  int? excludeId,
  Random? random,
  String emptyMessage = 'กล่องยังว่างอยู่ ลองหย่อนไอเดียลงไปก่อน',
}) async {
  final Idea? idea = randomIdeaFrom(pile, excludeId: excludeId, random: random);
  if (idea == null) {
    showSnack(context, emptyMessage);
    return excludeId;
  }
  final RandomIdeaAction? action = await showRandomIdeaSheet(context, idea);
  if (action == RandomIdeaAction.create && context.mounted) {
    await createFromIdea(context, idea);
  }
  return idea.id;
}

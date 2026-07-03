import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../crop_schedule_page.dart';
import '../widgets/section_header.dart';

const _green = Color(0xFF4C9A52);
const _weekdayJp = ['月', '火', '水', '木', '金', '土', '日'];
DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);
String _fmt(DateTime d) =>
    '${d.year}/${d.month}/${d.day}(${_weekdayJp[d.weekday - 1]})';

enum _StatusFilter { all, planned, done, overdue }

/// 「暦」セクション。全作付けの予定を時系列で横断表示（状態/作業で絞り込み）。
class CalendarSection extends ConsumerStatefulWidget {
  const CalendarSection({super.key});

  @override
  ConsumerState<CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends ConsumerState<CalendarSection> {
  _StatusFilter _status = _StatusFilter.all;
  final Set<CropEventType> _types = {};

  bool _match(CropEvent e, DateTime today) {
    switch (_status) {
      case _StatusFilter.planned:
        if (e.isDone) return false;
      case _StatusFilter.done:
        if (!e.isDone) return false;
      case _StatusFilter.overdue:
        if (e.isDone || !e.plannedDate.isBefore(today)) return false;
      case _StatusFilter.all:
        break;
    }
    if (_types.isNotEmpty && !_types.contains(e.type)) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(allEventsSortedProvider);
    final crops = ref.watch(cropsProvider);
    final plots = ref.watch(plotsProvider);
    final today = _dayKey(DateTime.now());
    final list = all.where((e) => _match(e, today)).toList();

    String plotName(String id) =>
        plots.firstWhere((p) => p.id == id, orElse: () => plots.first).name;

    return Column(
      children: [
        SectionHeader(title: '暦', subtitle: 'すべての予定（${list.length}）'),
        _filters(),
        const Divider(height: 1),
        Expanded(
          child: list.isEmpty
              ? const Center(
                  child: Text('条件に合う予定はありません',
                      style: TextStyle(color: Color(0xFF999999))))
              : ListView(
                  children: _buildList(list, crops, plotName, today),
                ),
        ),
      ],
    );
  }

  List<Widget> _buildList(
    List<CropEvent> list,
    Map<String, Crop> crops,
    String Function(String) plotName,
    DateTime today,
  ) {
    final widgets = <Widget>[];
    DateTime? last;
    for (final e in list) {
      final d = _dayKey(e.plannedDate);
      if (last == null || d != last) {
        widgets.add(Container(
          width: double.infinity,
          color: d == today ? const Color(0xFFE3F0E4) : const Color(0xFFF3F1EA),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: Text(_fmt(d),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: d == today ? _green : const Color(0xFF666666),
              )),
        ));
        last = d;
      }
      final crop = crops[e.cropId]!;
      widgets.add(ListTile(
        dense: true,
        leading: Icon(e.type.icon, color: e.type.color),
        title: Text('${crop.icon}${crop.name}　${e.type.label}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${plotName(e.plotId)}'
          '${e.isDone ? '・実施済み' : (e.plannedDate.isBefore(today) ? '・遅れ' : '')}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Icon(
          e.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
          color: e.isDone ? _green : const Color(0xFFCCCCCC),
          size: 20,
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlantingSchedulePage(
              plotId: e.plotId,
              cropId: e.cropId,
            ),
          ),
        ),
      ));
    }
    return widgets;
  }

  Widget _filters() {
    Widget statusChip(String label, _StatusFilter v) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            label: Text(label, style: const TextStyle(fontSize: 12)),
            selected: _status == v,
            visualDensity: VisualDensity.compact,
            onSelected: (_) => setState(() => _status = v),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Wrap(
            children: [
              statusChip('すべて', _StatusFilter.all),
              statusChip('予定', _StatusFilter.planned),
              statusChip('実施済み', _StatusFilter.done),
              statusChip('遅れ', _StatusFilter.overdue),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            children: [
              for (final t in CropEventType.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(t.label, style: const TextStyle(fontSize: 12)),
                    avatar: Icon(t.icon, size: 16, color: t.color),
                    selected: _types.contains(t),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    onSelected: (s) =>
                        setState(() => s ? _types.add(t) : _types.remove(t)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../crop_schedule_page.dart';
import '../widgets/section_header.dart';

const _green = Color(0xFF4C9A52);
const _weekdayJp = ['月', '火', '水', '木', '金', '土', '日'];
DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);
String _fmtShort(DateTime d) => '${d.month}/${d.day}(${_weekdayJp[d.weekday - 1]})';

/// 「ホーム」セクション。全作付けの直近の未実施予定を「遅れ/今日/近日」で表示。
class HomeSection extends ConsumerWidget {
  const HomeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(allEventsSortedProvider);
    final crops = ref.watch(cropsProvider);
    final plots = ref.watch(plotsProvider);
    final today = _dayKey(DateTime.now());
    final soon = today.add(const Duration(days: 7));

    String plotName(String id) =>
        plots.firstWhere((p) => p.id == id, orElse: () => plots.first).name;

    final pending = all.where((e) => !e.isDone).toList();
    final overdue =
        pending.where((e) => e.plannedDate.isBefore(today)).toList();
    final todays =
        pending.where((e) => _dayKey(e.plannedDate) == today).toList();
    final upcoming = pending
        .where((e) =>
            e.plannedDate.isAfter(today) && !e.plannedDate.isAfter(soon))
        .toList();

    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');

    return Column(
      children: [
        SectionHeader(
          title: 'やさい日記',
          subtitle: 'ホーム　${now.year}/${two(now.month)}/${two(now.day)}',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              if (overdue.isEmpty && todays.isEmpty && upcoming.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('直近の予定はありません',
                        style: TextStyle(color: Color(0xFF999999))),
                  ),
                ),
              _group('遅れ（${overdue.length}）', overdue, crops, plotName,
                  const Color(0xFFB5453B)),
              _group('今日やること（${todays.length}）', todays, crops, plotName,
                  _green),
              _group('近日（7日以内）（${upcoming.length}）', upcoming, crops,
                  plotName, const Color(0xFF666666)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _group(
    String title,
    List<CropEvent> events,
    Map<String, Crop> crops,
    String Function(String) plotName,
    Color accent,
  ) {
    if (events.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: accent, fontSize: 13)),
        ),
        for (final e in events)
          Builder(builder: (context) {
            final crop = crops[e.cropId]!;
            return ListTile(
              dense: true,
              leading: Icon(e.type.icon, color: e.type.color),
              title: Text('${crop.icon}${crop.name}　${e.type.label}',
                  style:
                      const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text('${plotName(e.plotId)}・${_fmtShort(e.plannedDate)}',
                  style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlantingSchedulePage(
                    plotId: e.plotId,
                    cropId: e.cropId,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

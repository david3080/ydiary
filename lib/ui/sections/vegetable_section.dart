import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/providers.dart';
import '../crop_schedule_page.dart';
import '../widgets/section_header.dart';

const _weekdayJp = ['月', '火', '水', '木', '金', '土', '日'];
String _fmtShort(DateTime d) => '${d.month}/${d.day}(${_weekdayJp[d.weekday - 1]})';

/// 「野菜」セクション。作付け（区画×野菜）の一覧。タップでスケジュールへ。
class VegetableSection extends ConsumerWidget {
  const VegetableSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantings = ref.watch(plantingsProvider);
    final plots = ref.watch(plotsProvider);
    final crops = ref.watch(cropsProvider);
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return Column(
      children: [
        SectionHeader(
          title: '野菜',
          subtitle: '作付け一覧（${plantings.length}）',
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: plantings.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final key = plantings[i];
              final crop = crops[key.cropId]!;
              final plot = plots.firstWhere((p) => p.id == key.plotId,
                  orElse: () => plots.first);
              final cells =
                  plot.cells.where((c) => c == key.cropId).length;
              final events = ref.watch(eventsForPlantingProvider(key));
              final upcoming = events
                  .where((e) => !e.isDone && !e.plannedDate.isBefore(today))
                  .toList();
              final next = upcoming.isNotEmpty ? upcoming.first : null;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: crop.soft,
                  child: Text(crop.icon),
                ),
                title: Text('${crop.name}　${plot.name}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  next == null
                      ? '$cellsマス・予定なし'
                      : '$cellsマス・次: ${next.type.label} ${_fmtShort(next.plannedDate)}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PlantingSchedulePage(
                      plotId: key.plotId,
                      cropId: key.cropId,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

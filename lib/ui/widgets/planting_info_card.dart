import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/providers.dart';
import '../crop_schedule_page.dart';

/// 選択マスの作付け情報カード。選択が無い/空きマスならプレースホルダ。
class PlantingInfoCard extends ConsumerWidget {
  const PlantingInfoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sel = ref.watch(selectedCellProvider);
    final crops = ref.watch(cropsProvider);
    final plantings = ref.watch(plantingInfoProvider);

    if (sel == null || sel.cropId == null) {
      final text = sel?.cropId == null && sel != null
          ? '空きマス（${sel.c + 1},${sel.r + 1}）— 作付けを追加できます'
          : 'マスをタップすると作付け情報を表示します';
      return _card(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF999999), fontSize: 12),
        ),
      );
    }

    final crop = crops[sel.cropId]!;
    final info = plantings[sel.cropId];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${crop.icon} ${crop.name}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          _row('マス', '${sel.c + 1}列 ${sel.r + 1}行目'),
          _row('植付日', info?.date ?? '-'),
          _row('植え方', info?.method ?? '-'),
          _row('状態', '育成中'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.event_note, size: 18),
              label: const Text('スケジュール'),
              onPressed: () {
                final plotId = ref.read(currentPlotProvider).id;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PlantingSchedulePage(
                      plotId: plotId,
                      cropId: sel.cropId!,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF999999), fontSize: 13)),
            Text(value, style: const TextStyle(color: Color(0xFF555555), fontSize: 13)),
          ],
        ),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: child,
      );
}

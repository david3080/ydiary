import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/providers.dart';

/// 作物ごとの色・マス数・面積の凡例。タップでハイライトを切り替える。
class CropLegend extends ConsumerWidget {
  const CropLegend({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(cropCountsProvider);

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Text(
            '作付け（タップでハイライト）',
            style: TextStyle(fontSize: 12, color: Color(0xFF666666), fontWeight: FontWeight.w600),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 5.0;
            final itemW = (constraints.maxWidth - spacing) / 2;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final e in entries)
                  SizedBox(
                    width: itemW,
                    child: _LegendItem(cropId: e.key, count: e.value),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LegendItem extends ConsumerWidget {
  final String cropId;
  final int count;
  const _LegendItem({required this.cropId, required this.count});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crop = ref.watch(cropsProvider)[cropId]!;
    final highlighted = ref.watch(highlightedCropProvider) == cropId;
    final area = (count * 0.25).toStringAsFixed(1);

    return GestureDetector(
      onTap: () => toggleCropFocus(ref, cropId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: highlighted
              ? Border.all(color: const Color(0xFFFF8A3D), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: crop.soft,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${crop.icon}${crop.name}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Text(
              '$count/$area㎡',
              style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
            ),
          ],
        ),
      ),
    );
  }
}

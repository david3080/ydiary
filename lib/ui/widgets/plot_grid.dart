import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import 'crop_icon.dart';

/// 区画のマス目グリッド。正方形セルを維持して領域いっぱいに最大化する。
class PlotGrid extends ConsumerWidget {
  /// グリッドに割り当てる高さの上限（レスポンシブに算出して渡す）。
  final double maxHeight;
  const PlotGrid({super.key, required this.maxHeight});

  static const double _gap = 1.5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plot = ref.watch(currentPlotProvider);
    final matrix = ref.watch(currentMatrixProvider);
    final crops = ref.watch(cropsProvider);
    final highlight = ref.watch(highlightedCropProvider);
    final selected = ref.watch(selectedCellProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // パディング(両端)＋マス間ギャップの合計を差し引いてからセル寸法を決める
        final gapW = _gap * 2 + _gap * (plot.cols - 1);
        final gapH = _gap * 2 + _gap * (plot.rows - 1);
        final cellW = (constraints.maxWidth - gapW) / plot.cols;
        final cellH = (maxHeight - gapH) / plot.rows;
        final cell = min(cellW, cellH).floorToDouble();

        return Center(
          child: Container(
            padding: const EdgeInsets.all(_gap),
            decoration: BoxDecoration(
              color: const Color(0xFFCFC7B5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var r = 0; r < plot.rows; r++)
                  Padding(
                    padding: EdgeInsets.only(top: r == 0 ? 0 : _gap),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var c = 0; c < plot.cols; c++)
                          Padding(
                            padding: EdgeInsets.only(left: c == 0 ? 0 : _gap),
                            child: _CellTile(
                              cropId: matrix[r][c],
                              crop: matrix[r][c] == null
                                  ? null
                                  : crops[matrix[r][c]],
                              c: c,
                              r: r,
                              size: cell,
                              highlight: highlight,
                              selected: selected,
                              ref: ref,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CellTile extends StatelessWidget {
  final String? cropId;
  final Crop? crop;
  final int c;
  final int r;
  final double size;
  final String? highlight;
  final CellSelection? selected;
  final WidgetRef ref;

  const _CellTile({
    required this.cropId,
    required this.crop,
    required this.c,
    required this.r,
    required this.size,
    required this.highlight,
    required this.selected,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final hasHighlight = highlight != null;
    final isHighlighted = hasHighlight && cropId == highlight;
    final isDimmed = hasHighlight && cropId != highlight;
    final bg = crop?.soft ?? const Color(0xFFEFEAE0);

    Widget tile = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        border: isHighlighted
            ? Border.all(color: const Color(0xFFFF8A3D), width: 3)
            : null,
      ),
      child: (crop != null && size >= 22)
          ? CropIcon(crop: crop!, size: size * 0.82)
          : null,
    );

    if (isDimmed) tile = Opacity(opacity: 0.28, child: tile);

    return GestureDetector(
      onTap: () {
        ref.read(selectedCellProvider.notifier).select(CellSelection(c, r, cropId));
        // 空きマスをタップしたらハイライト解除（cropId=null）
        ref.read(highlightedCropProvider.notifier).set(cropId);
      },
      child: tile,
    );
  }
}

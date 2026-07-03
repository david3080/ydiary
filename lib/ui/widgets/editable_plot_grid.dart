import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';

/// 編集用グリッド。タップ／ドラッグでパレットの作物を塗る。
class EditablePlotGrid extends ConsumerWidget {
  final int plotIndex;
  final double maxHeight;
  const EditablePlotGrid({
    super.key,
    required this.plotIndex,
    required this.maxHeight,
  });

  static const double _gap = 1.5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plot = ref.watch(plotsProvider)[plotIndex];
    final crops = ref.watch(cropsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final gapW = _gap * 2 + _gap * (plot.cols - 1);
        final gapH = _gap * 2 + _gap * (plot.rows - 1);
        final cellW = (constraints.maxWidth - gapW) / plot.cols;
        final cellH = (maxHeight - gapH) / plot.rows;
        final cell = min(cellW, cellH).floorToDouble();

        void paintAt(Offset pos) {
          final step = cell + _gap;
          final c = ((pos.dx - _gap) / step).floor();
          final r = ((pos.dy - _gap) / step).floor();
          if (c < 0 || c >= plot.cols || r < 0 || r >= plot.rows) return;
          final paint = ref.read(paintCropProvider);
          ref.read(plotsProvider.notifier).paintCell(plotIndex, c, r, paint);
        }

        return Center(
          child: GestureDetector(
            onTapDown: (d) => paintAt(d.localPosition),
            onPanStart: (d) => paintAt(d.localPosition),
            onPanUpdate: (d) => paintAt(d.localPosition),
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
                              child: _cell(plot.at(c, r), crops, cell),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cell(String? cropId, Map<String, Crop> crops, double size) {
    final crop = cropId == null ? null : crops[cropId];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: crop?.soft ?? const Color(0xFFEFEAE0),
      child: (crop != null && size >= 20)
          ? Text(crop.icon, style: TextStyle(fontSize: size * 0.5))
          : null,
    );
  }
}

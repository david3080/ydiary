import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';
import 'widgets/crop_palette.dart';
import 'widgets/editable_plot_grid.dart';

const _green = Color(0xFF4C9A52);

/// 区画の登録・編集エディタ。編集はプロバイダに即時反映される（UI=f(状態)）。
class PlotEditorPage extends ConsumerStatefulWidget {
  final int plotIndex;
  const PlotEditorPage({super.key, required this.plotIndex});

  @override
  ConsumerState<PlotEditorPage> createState() => _PlotEditorPageState();
}

class _PlotEditorPageState extends ConsumerState<PlotEditorPage> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    final plot = ref.read(plotsProvider)[widget.plotIndex];
    _nameCtrl = TextEditingController(text: plot.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _delete() {
    final plots = ref.read(plotsProvider);
    if (plots.length <= 1) return;
    final removeIndex = widget.plotIndex;
    final sel = ref.read(selectedPlotIndexProvider);
    // 削除後の残り件数(plots.length-1)で有効なインデックスに先に補正しておく
    final newSel =
        (sel > removeIndex ? sel - 1 : sel).clamp(0, plots.length - 2);
    ref.read(selectedPlotIndexProvider.notifier).select(newSel);
    ref.read(plotsProvider.notifier).removeAt(removeIndex);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final plots = ref.watch(plotsProvider);
    // 削除直後などインデックスが範囲外なら何も描かない
    if (widget.plotIndex >= plots.length) return const SizedBox.shrink();
    final plot = plots[widget.plotIndex];
    final notifier = ref.read(plotsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: const Text('区画の編集', style: TextStyle(fontSize: 16)),
        actions: [
          if (plots.length > 1)
            IconButton(
              tooltip: '区画を削除',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('完了', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '区画名',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => notifier.rename(widget.plotIndex, v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Stepper(
                  label: '横（列）',
                  value: plot.cols,
                  onChanged: (v) => notifier.resize(widget.plotIndex, cols: v),
                ),
                const SizedBox(width: 12),
                _Stepper(
                  label: '縦（行）',
                  value: plot.rows,
                  onChanged: (v) => notifier.resize(widget.plotIndex, rows: v),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '広さ ${plot.sizeLabel}（${plot.cols}×${plot.rows}マス・1マス50cm）',
              style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
            ),
            const Divider(height: 24),
            const Text(
              '作物を選んでマスをなぞって塗る（「空き」で消す）',
              style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 6),
            const CropPalette(),
            const SizedBox(height: 10),
            EditablePlotGrid(
              plotIndex: widget.plotIndex,
              maxHeight:
                  (MediaQuery.sizeOf(context).height * 0.45).clamp(220.0, 480.0),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _Stepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  static const _min = 1;
  static const _max = 20;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
          const SizedBox(height: 4),
          Row(
            children: [
              _btn(Icons.remove, value > _min, () => onChanged(max(_min, value - 1))),
              Expanded(
                child: Center(
                  child: Text('$value',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              _btn(Icons.add, value < _max, () => onChanged(min(_max, value + 1))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, bool enabled, VoidCallback onTap) => InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFE2DDD0) : const Color(0xFFEFEDE6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: enabled ? const Color(0xFF444444) : const Color(0xFFBBBBBB)),
        ),
      );
}

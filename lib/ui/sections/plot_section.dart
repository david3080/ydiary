import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/providers.dart';
import '../plot_editor_page.dart';
import '../widgets/account_menu_button.dart';
import '../widgets/plot_grid.dart';
import '../widgets/crop_legend.dart';
import '../widgets/planting_info_card.dart';

const _green = Color(0xFF4C9A52);

/// 「区画」セクション（土地利用状況）。ナビはシェル側が持つ。
/// 画面が横長なら野菜リストを右に、縦長なら下に置く。
class PlotSection extends StatelessWidget {
  const PlotSection({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wide = size.width > size.height;
    return Column(
      children: [
        const _Header(),
        const _PlotSegments(),
        const _SummaryRow(),
        Expanded(child: wide ? const _WideBody() : const _NarrowBody()),
      ],
    );
  }
}

class _NarrowBody extends StatelessWidget {
  const _NarrowBody();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gridBudget = (constraints.maxHeight * 0.62).clamp(200.0, 520.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
          child: Column(
            children: [
              _GridSection(maxHeight: gridBudget),
              const SizedBox(height: 4),
              const CropLegend(),
            ],
          ),
        );
      },
    );
  }
}

class _WideBody extends StatelessWidget {
  const _WideBody();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gridBudget =
                  (constraints.maxHeight - 150).clamp(220.0, 700.0);
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                child: _GridSection(maxHeight: gridBudget),
              );
            },
          ),
        ),
        const _LegendPanel(),
      ],
    );
  }
}

class _LegendPanel extends StatelessWidget {
  const _LegendPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFFE2DDD0))),
      ),
      child: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 16),
        child: CropLegend(),
      ),
    );
  }
}

class _GridSection extends StatelessWidget {
  final double maxHeight;
  const _GridSection({required this.maxHeight});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _AxisLabel('↑ 奥'),
        PlotGrid(maxHeight: maxHeight),
        const _AxisLabel('手前 ↓'),
        const PlantingInfoCard(),
      ],
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  void _openEditor(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlotEditorPage(plotIndex: index)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return Container(
      width: double.infinity,
      color: _green,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('やさい日記',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    )),
                const SizedBox(height: 2),
                Text('土地利用状況　${now.year}/${two(now.month)}/${two(now.day)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'この区画を編集',
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () =>
                _openEditor(context, ref.read(selectedPlotIndexProvider)),
          ),
          IconButton(
            tooltip: '区画を追加',
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () {
              final index = ref.read(plotsProvider.notifier).addNew();
              selectPlot(ref, index);
              _openEditor(context, index);
            },
          ),
          const AccountMenuButton(),
        ],
      ),
    );
  }
}

class _PlotSegments extends ConsumerWidget {
  const _PlotSegments();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plots = ref.watch(plotsProvider);
    final selected = ref.watch(selectedPlotIndexProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Row(
        children: [
          for (var i = 0; i < plots.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: GestureDetector(
                onTap: () => selectPlot(ref, i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == i ? _green : const Color(0xFFE2DDD0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${plots[i].name}（${plots[i].sizeLabel}）',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          selected == i ? Colors.white : const Color(0xFF6B6B6B),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends ConsumerWidget {
  const _SummaryRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plot = ref.watch(currentPlotProvider);
    final usage = ref.watch(usageRateProvider);
    final w = plot.cols * 0.5;
    final h = plot.rows * 0.5;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _kv('広さ ', '$w×${h}m（${plot.cols}×${plot.rows}マス）'),
          _kv('利用 ', '$usage%'),
        ],
      ),
    );
  }

  Widget _kv(String label, String value) => RichText(
        text: TextSpan(
          style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
          children: [
            TextSpan(text: label),
            TextSpan(
              text: value,
              style: const TextStyle(
                  color: Color(0xFF2B2B2B), fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
}

class _AxisLabel extends StatelessWidget {
  final String text;
  const _AxisLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(text,
            style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
      );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';
import 'sections/home_section.dart';
import 'sections/plot_section.dart';
import 'sections/calendar_section.dart';
import 'sections/vegetable_section.dart';
import 'sections/settings_section.dart';

const _green = Color(0xFF4C9A52);

const _navItems = [
  ('🏠', 'ホーム'),
  ('🗺️', '区画'),
  ('📅', '暦'),
  ('🥬', '野菜'),
  ('⚙️', '設定'),
];

/// アプリのシェル。ナビ（横長=サイドレール／縦長=ボトムバー）で
/// 5セクションを切り替える。
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  Widget _section(int index) {
    switch (index) {
      case 0:
        return const HomeSection();
      case 2:
        return const CalendarSection();
      case 3:
        return const VegetableSection();
      case 4:
        return const SettingsSection();
      case 1:
      default:
        return const PlotSection();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navIndexProvider);
    final size = MediaQuery.sizeOf(context);
    final wide = size.width > size.height;
    void go(int i) => ref.read(navIndexProvider.notifier).select(i);

    if (wide) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NavigationRail(
                selectedIndex: index,
                onDestinationSelected: go,
                labelType: NavigationRailLabelType.all,
                backgroundColor: Colors.white,
                destinations: [
                  for (final (icon, label) in _navItems)
                    NavigationRailDestination(
                      icon: Text(icon, style: const TextStyle(fontSize: 20)),
                      label: Text(label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: _section(index)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(bottom: false, child: _section(index)),
      bottomNavigationBar: _BottomBar(index: index, onTap: go),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomBar({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2DDD0))),
      ),
      padding: EdgeInsets.only(
        top: 6,
        bottom: 6 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          for (var i = 0; i < _navItems.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onTap(i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_navItems[i].$1, style: const TextStyle(fontSize: 18)),
                    Text(
                      _navItems[i].$2,
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            i == index ? _green : const Color(0xFF9A9A9A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

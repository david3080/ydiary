import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/providers.dart';

/// エディタ用の作物パレット。選ぶと paintCropProvider が切り替わる。
/// 先頭は消しゴム（空きにする）。
class CropPalette extends ConsumerWidget {
  const CropPalette({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crops = ref.watch(cropsProvider);
    final selected = ref.watch(paintCropProvider);

    final ids = crops.keys.toList();

    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        children: [
          _PaletteChip(
            label: '空き',
            icon: '🧽',
            bg: const Color(0xFFEFEAE0),
            selected: selected == null,
            onTap: () => ref.read(paintCropProvider.notifier).select(null),
          ),
          for (final id in ids)
            _PaletteChip(
              label: crops[id]!.name,
              icon: crops[id]!.icon,
              bg: crops[id]!.soft,
              selected: selected == id,
              onTap: () => ref.read(paintCropProvider.notifier).select(id),
            ),
        ],
      ),
    );
  }
}

class _PaletteChip extends StatelessWidget {
  final String label;
  final String icon;
  final Color bg;
  final bool selected;
  final VoidCallback onTap;

  const _PaletteChip({
    required this.label,
    required this.icon,
    required this.bg,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFFFF8A3D) : const Color(0x11000000),
            width: selected ? 2.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, color: Color(0xFF444444)),
            ),
          ],
        ),
      ),
    );
  }
}

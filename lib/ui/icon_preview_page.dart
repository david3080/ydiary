import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';
import 'widgets/crop_icon.dart';

const _green = Color(0xFF4C9A52);

/// 野菜アイコンを大きく一覧するプレビュー（スタイル確認用）。
class IconPreviewPage extends ConsumerWidget {
  const IconPreviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crops = ref.watch(cropsProvider).values.toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: const Text('アイコンプレビュー', style: TextStyle(fontSize: 16)),
      ),
      body: GridView.extent(
        maxCrossAxisExtent: 150,
        childAspectRatio: 0.82,
        padding: const EdgeInsets.all(12),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          for (final crop in crops)
            Container(
              decoration: BoxDecoration(
                color: crop.soft.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x22000000)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CropIcon(crop: crop, size: 84),
                  const SizedBox(height: 6),
                  Text(crop.name,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

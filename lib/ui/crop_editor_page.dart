import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models.dart';
import '../state/providers.dart';
import 'widgets/crop_icon.dart';

const _green = Color(0xFF4C9A52);

const _presetColors = [
  Color(0xFFE5544B),
  Color(0xFF7CAE4A),
  Color(0xFF7D5BA6),
  Color(0xFF5B8C3E),
  Color(0xFFC56B8A),
  Color(0xFF9AB84E),
  Color(0xFFA7C957),
  Color(0xFFA3855F),
  Color(0xFFC2A34E),
  Color(0xFFB06B3A),
  Color(0xFF5AA469),
  Color(0xFF8FBF6A),
  Color(0xFFE6A92E),
  Color(0xFFDD7B3A),
  Color(0xFF88B04A),
  Color(0xFF5F9A3C),
  Color(0xFF9C4A7A),
  Color(0xFF6FAE52),
  Color(0xFF3F8F4A),
  Color(0xFF4C6FA5),
];

/// 野菜マスタ（名前・色・絵文字）の一覧・追加・編集・削除。
class CropEditorPage extends ConsumerWidget {
  const CropEditorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crops = ref.watch(cropsProvider);
    final entries = crops.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: const Text('野菜マスタ', style: TextStyle(fontSize: 16)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('野菜を追加'),
        onPressed: () => _showEditDialog(context, ref, null),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final crop = entries[i];
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: crop.soft,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: CropIcon(crop: crop, size: 28),
            ),
            title: Text(crop.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: '編集',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _showEditDialog(context, ref, crop),
                ),
                IconButton(
                  tooltip: '削除',
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _confirmDelete(context, ref, crop),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Crop crop) async {
    final inUse = ref
        .read(plantingsProvider)
        .any((p) => p.cropId == crop.id);
    if (inUse) {
      ShowSnack.of(context, '${crop.name}は区画で使用中のため削除できません');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${crop.name}を削除しますか？'),
        content: const Text('この操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(cropsProvider.notifier).remove(crop.id);
    }
  }

  Future<void> _showEditDialog(
      BuildContext context, WidgetRef ref, Crop? existing) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final iconCtrl = TextEditingController(text: existing?.icon ?? '🌱');
    Color selectedColor = existing?.color ?? _presetColors.first;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existing == null ? '野菜を追加' : '${existing.name}を編集',
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: '名前',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: iconCtrl,
                decoration: const InputDecoration(
                  labelText: '絵文字（例: 🥬）',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('色', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in _presetColors)
                    GestureDetector(
                      onTap: () => setModalState(() => selectedColor = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor.toARGB32() == c.toARGB32()
                                ? Colors.black
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _green),
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    Navigator.of(context).pop(true);
                  },
                  child: Text(existing == null ? '追加' : '保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      final name = nameCtrl.text.trim();
      final icon = iconCtrl.text.trim().isEmpty ? '🌱' : iconCtrl.text.trim();
      if (existing == null) {
        ref
            .read(cropsProvider.notifier)
            .add(name: name, color: selectedColor, icon: icon);
      } else {
        ref.read(cropsProvider.notifier).update(
              existing.id,
              name: name,
              color: selectedColor,
              icon: icon,
            );
      }
    }
  }
}

/// SnackBarを出すだけの小さなヘルパー（コンテキストのasync gapを気にせず使える）。
class ShowSnack {
  static void of(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

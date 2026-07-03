import 'package:flutter/material.dart';
import '../../data/seed_data.dart';
import '../icon_preview_page.dart';
import '../widgets/section_header.dart';

/// 「設定」セクション。アカウント操作はヘッダーのアイコンから行う。
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(title: '設定'),
        Expanded(
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('アイコンプレビュー'),
                subtitle: const Text('野菜アイコンを大きく確認'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const IconPreviewPage()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.place_outlined),
                title: const Text('天気予報の地域'),
                subtitle: Text(kWeatherPlaceName),
              ),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('やさい日記'),
                subtitle: Text('家庭菜園の区画・作付け・作業スケジュール管理'),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('※ 通知・共有などは今後追加予定',
                    style: TextStyle(color: Color(0xFF999999), fontSize: 12)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

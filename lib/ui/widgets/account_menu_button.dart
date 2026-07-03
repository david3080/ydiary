import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../data/auth_repo.dart';

/// ヘッダーに常時表示するアカウントアイコン。タップでサインアウト等のメニューを開く。
/// 未サインイン・Firebase未初期化（テスト環境など）では何も表示しない。
class AccountMenuButton extends StatelessWidget {
  const AccountMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) return const SizedBox.shrink();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      tooltip: user.email ?? 'アカウント',
      onSelected: (value) {
        if (value == 'signout') signOut();
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            user.email ?? user.displayName ?? 'サインイン中',
            style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'signout',
          child: Text('サインアウト'),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: _AccountAvatar(photoURL: user.photoURL),
      ),
    );
  }
}

/// プロフィール画像を永続キャッシュ付きで表示する。
/// 読み込み中・失敗時は人型アイコンにフォールバックする。
class _AccountAvatar extends StatelessWidget {
  final String? photoURL;
  const _AccountAvatar({required this.photoURL});

  static const _fallback = CircleAvatar(
    radius: 15,
    backgroundColor: Colors.white,
    child: Icon(Icons.person, size: 16, color: Color(0xFF4C9A52)),
  );

  @override
  Widget build(BuildContext context) {
    if (photoURL == null) return _fallback;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: photoURL!,
        width: 30,
        height: 30,
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        placeholder: (context, url) => _fallback,
        errorWidget: (context, url, error) => _fallback,
      ),
    );
  }
}

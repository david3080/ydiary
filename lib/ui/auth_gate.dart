import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../data/auth_repo.dart';
import 'home_shell.dart';

const _green = Color(0xFF4C9A52);

/// ログイン状態に応じて SignInPage / HomeShell を切り替える。
/// Firebase未初期化（テスト環境など）では認証なしで HomeShell を直接表示する。
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Firebase.apps は未初期化でも例外を投げない安全な判定。
    // （try-catchで囲むと本物の実行時エラーまで握りつぶしてしまうため使わない）
    if (Firebase.apps.isEmpty) return const HomeShell();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F2EA),
            body: Center(child: CircularProgressIndicator(color: _green)),
          );
        }
        if (snapshot.data == null) return const SignInPage();
        return const HomeShell();
      },
    );
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await signInWithGoogle();
    } catch (e) {
      setState(() => _error = 'サインインできませんでした: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🥬', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              const Text(
                'やさい日記',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: _green),
              ),
              const SizedBox(height: 6),
              const Text(
                'Googleアカウントでサインインすると\nどの端末からでも同じデータを使えます',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 28),
              if (_loading)
                const CircularProgressIndicator(color: _green)
              else
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onPressed: _signIn,
                  icon: const Icon(Icons.login),
                  label: const Text('Googleでサインイン'),
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

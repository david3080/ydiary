import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

bool _googleSignInInitialized = false;

/// Googleサインイン。Webはポップアップ、iOS等はネイティブのGoogleSignInフローを使う。
/// 同じGoogleアカウントであれば端末・ブラウザが変わっても同じuidになる。
Future<void> signInWithGoogle() async {
  if (kIsWeb) {
    await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
    return;
  }
  if (!_googleSignInInitialized) {
    await GoogleSignIn.instance.initialize();
    _googleSignInInitialized = true;
  }
  final googleUser = await GoogleSignIn.instance.authenticate();
  final idToken = googleUser.authentication.idToken;
  final credential = GoogleAuthProvider.credential(idToken: idToken);
  await FirebaseAuth.instance.signInWithCredential(credential);
}

Future<void> signOut() async {
  if (!kIsWeb) {
    await GoogleSignIn.instance.signOut();
  }
  await FirebaseAuth.instance.signOut();
}

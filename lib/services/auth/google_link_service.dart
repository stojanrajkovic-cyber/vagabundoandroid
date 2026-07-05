import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Ekvivalent AccountLinkingService.swift (Google-only na Androidu —
/// Apple linking ne postoji ovdje).
class GoogleLinkService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool isGoogleLinked() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.providerData.any((p) => p.providerId == 'google.com') ??
        false;
  }

  bool canUnlinkGoogle() {
    final user = FirebaseAuth.instance.currentUser;
    return (user?.providerData.length ?? 0) > 1 && isGoogleLinked();
  }

  Future<void> linkGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return; // korisnik otkazao
    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not signed in');

    try {
      await user.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapLinkError(e.code));
    }
  }

  Future<void> unlinkGoogle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if ((user.providerData.length) <= 1) {
      throw StateError('Cannot unlink your only sign-in method.');
    }
    await user.unlink('google.com');
    await _googleSignIn.signOut();
  }

  String _mapLinkError(String code) {
    switch (code) {
      case 'credential-already-in-use':
        return 'This Google account is already linked to another user.';
      case 'provider-already-linked':
        return 'Google is already linked to your account.';
      case 'requires-recent-login':
        return 'Please sign in again before making this change.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      default:
        return 'Could not link Google account. Please try again.';
    }
  }
}

final googleLinkServiceProvider =
    Provider<GoogleLinkService>((ref) => GoogleLinkService());

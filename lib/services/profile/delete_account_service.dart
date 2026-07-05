import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../widgets/profile/password_reauth_dialog.dart';
import '../storage/local_plan_mirror.dart';

/// Ekvivalent account deletion logike u FirebaseAuthService.swift.
///
/// VAN OBIMA (deferred): slanje "account deletion" email-a
/// (FunctionsService.sendAccountDeletionEmail) — Cloud Function postoji na
/// iOS strani ali nemamo Dart wrapper niti je tražena.
/// TODO: account deletion email ako se ispostavi da treba.
class DeleteAccountService {
  Future<bool> deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final uid = user.uid;

    try {
      if (!await _reauthenticateIfNeeded(context, user)) return false;

      await _deleteUserFirestoreData(uid);

      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          if (!context.mounted) return false;
          if (!await _reauthenticateIfNeeded(context, user)) return false;
          await user.delete();
        } else {
          rethrow;
        }
      }

      await LocalPlanMirror.deleteAll();
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('❌ deleteAccount error: $e');
      return false;
    }
  }

  Future<bool> _reauthenticateIfNeeded(BuildContext context, User user) async {
    final providers = user.providerData.map((p) => p.providerId).toList();

    if (providers.contains('password')) {
      final email = user.email;
      if (email == null) return false;
      if (!context.mounted) return false;
      final password = await promptPassword(context, email);
      if (password == null || password.isEmpty) return false;
      final credential = EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);
      return true;
    }

    if (providers.contains('google.com')) {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return false;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      await user.reauthenticateWithCredential(credential);
      return true;
    }

    return false; // nepoznat provider — ne možemo reauth-ovati, odbij deletion
  }

  Future<void> _deleteUserFirestoreData(String uid) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    for (final sub in ['plans', 'visits', 'stats', 'achievements', 'purchases']) {
      await _deleteCollection(userRef.collection(sub));
    }
    await userRef.delete();
  }

  Future<void> _deleteCollection(CollectionReference ref, {int batchSize = 50}) async {
    final snapshot = await ref.limit(batchSize).get();
    if (snapshot.docs.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    if (snapshot.docs.length == batchSize) {
      await _deleteCollection(ref, batchSize: batchSize);
    }
  }
}

final deleteAccountServiceProvider =
    Provider<DeleteAccountService>((ref) => DeleteAccountService());

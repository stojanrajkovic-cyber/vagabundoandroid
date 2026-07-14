import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../analytics/analytics_service.dart';

/// Ekvivalent AuthSession.swift — tanki wrapper oko FirebaseAuth-a.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    AnalyticsService.instance.logLogin(method: 'email');
    return credential;
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    AnalyticsService.instance.logSignUp(method: 'email');
    return credential;
  }

  /// Ekvivalent "Continue with Google" — NOVI/alternativni način prijave
  /// (signInWithCredential), NIJE isto što i GoogleLinkService.linkGoogle()
  /// iz Settings faze (koji radi linkWithCredential na POSTOJEĆI ulogovan
  /// nalog).
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Sign-in cancelled.',
      );
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    if (userCredential.additionalUserInfo?.isNewUser == true) {
      AnalyticsService.instance.logSignUp(method: 'google');
    } else {
      AnalyticsService.instance.logLogin(method: 'google');
    }
    return userCredential;
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }
}

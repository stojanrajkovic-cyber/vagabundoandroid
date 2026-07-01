import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Ekvivalent `@EnvironmentObject var session: AuthSession`.
/// StreamProvider automatski rebuilda UI kad se promijeni auth stanje —
/// isto kao @Published var user na iOS-u.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Ekvivalent `session.isAuthenticated`.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).asData?.value != null;
});

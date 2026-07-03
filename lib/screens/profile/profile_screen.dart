import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';

/// Placeholder — puna implementacija dolazi u Fazi 7
/// (travel stats, achievements, journey map, settings).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final user = ref.watch(authStateProvider).asData?.value;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Profile — coming in Phase 7'),
            const SizedBox(height: 16),
            Text(user?.email ?? ''),
            const SizedBox(height: 16),
            TextButton(
              onPressed: authService.signOut,
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

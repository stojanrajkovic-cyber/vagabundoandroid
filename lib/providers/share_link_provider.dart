import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/share/share_link_service.dart';
import 'auth_provider.dart';

final shareLinkServiceProvider = Provider<ShareLinkService>((ref) {
  return ShareLinkService();
});

/// Učitava POSTOJEĆI share za dati planId — NE kreira novi automatski
/// (kreiranje je eksplicitna akcija preko `createOrGetShareForPlan`, npr.
/// na tap share dugmeta u ResultScreen-u).
final shareInfoProvider =
    FutureProvider.family<ShareInfo?, String>((ref, planId) async {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) return null;

  final service = ref.watch(shareLinkServiceProvider);
  return service.loadShareForPlan(uid: uid, planId: planId);
});

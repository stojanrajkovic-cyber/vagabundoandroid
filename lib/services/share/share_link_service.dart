import 'package:cloud_firestore/cloud_firestore.dart';

/// Ekvivalent ShareInfo sa iOS-a. `id` = token = doc id u `/shares/{token}`.
class ShareInfo {
  const ShareInfo({
    required this.id,
    required this.planId,
    required this.ownerUid,
    required this.revoked,
  });

  final String id;
  final String planId;
  final String ownerUid;
  final bool revoked;

  static ShareInfo? fromFirestore(String id, Map<String, dynamic> data) {
    final planId = data['planId'] as String?;
    final ownerUid = data['ownerUid'] as String?;
    if (planId == null || ownerUid == null) return null;

    return ShareInfo(
      id: id,
      planId: planId,
      ownerUid: ownerUid,
      revoked: data['revoked'] as bool? ?? false,
    );
  }

  ShareInfo copyWith({bool? revoked}) {
    return ShareInfo(
      id: id,
      planId: planId,
      ownerUid: ownerUid,
      revoked: revoked ?? this.revoked,
    );
  }
}

/// Ekvivalent ShareLinkService sa iOS-a — direktno preko cloud_firestore,
/// kolekcija `/shares/{token}` (šema dogovorena u security rules-ima ranije:
/// `{ ownerUid: string, planId: string, revoked: bool, createdAt: Timestamp }`).
class ShareLinkService {
  CollectionReference<Map<String, dynamic>> get _sharesCol =>
      FirebaseFirestore.instance.collection('shares');

  /// Kreira novi share dokument za dati planId ako ne postoji, ili vraća
  /// postojeći (owner + planId par je jedinstven po dizajnu).
  Future<ShareInfo> createOrGetShareForPlan({
    required String uid,
    required String planId,
  }) async {
    final existing = await loadShareForPlan(uid: uid, planId: planId);
    if (existing != null) return existing;

    // Firestore auto-id preko .doc() bez argumenta -> .id se koristi kao token.
    final docRef = _sharesCol.doc();
    await docRef.set({
      'ownerUid': uid,
      'planId': planId,
      'revoked': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return ShareInfo(id: docRef.id, planId: planId, ownerUid: uid, revoked: false);
  }

  Future<ShareInfo?> loadShareForPlan({
    required String uid,
    required String planId,
  }) async {
    final qs = await _sharesCol
        .where('planId', isEqualTo: planId)
        .where('ownerUid', isEqualTo: uid)
        .limit(1)
        .get();

    if (qs.docs.isEmpty) return null;
    final doc = qs.docs.first;
    return ShareInfo.fromFirestore(doc.id, doc.data());
  }

  Future<void> setRevoked({required String token, required bool revoked}) {
    return _sharesCol.doc(token).update({'revoked': revoked});
  }

  Future<void> deleteShare({required String token}) {
    return _sharesCol.doc(token).delete();
  }
}

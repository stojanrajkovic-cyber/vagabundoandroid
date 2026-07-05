import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Ekvivalent saveProfileImage/loadProfileImageIfNeeded/deleteLocalProfileImage
/// sa iOS-a — lokalno keširana profilna slika (Application Documents Directory).
class ProfileAvatarService {
  Future<File?> loadIfExists(String uid) async {
    final path = await _pathFor(uid);
    final file = File(path);
    return await file.exists() ? file : null;
  }

  Future<File> save(String uid, File pickedImage) async {
    final path = await _pathFor(uid);
    return pickedImage.copy(path);
  }

  Future<void> delete(String uid) async {
    final file = File(await _pathFor(uid));
    if (await file.exists()) await file.delete();
  }

  Future<String> _pathFor(String uid) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/profile_$uid.jpg';
  }
}

final profileAvatarServiceProvider =
    Provider<ProfileAvatarService>((ref) => ProfileAvatarService());

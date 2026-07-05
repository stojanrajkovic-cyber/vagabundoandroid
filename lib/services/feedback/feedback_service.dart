import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../models/feedback_item.dart';

/// Ekvivalent FeedbackService.swift — ista Firestore šema kao već
/// postojeće rules za `feedback` kolekciju.
class FeedbackService {
  Future<void> submitFeedback({
    required FeedbackType type,
    required String message,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not signed in');

    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;

    await FirebaseFirestore.instance.collection('feedback').add({
      'uid': user.uid,
      'userEmail': user.email ?? '',
      'displayName': user.displayName ?? '',
      'type': type.name,
      'message': message,
      'appVersion': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
      'platform': 'Android',
      'systemVersion': androidInfo.version.release,
      'deviceModel': androidInfo.model,
      'localeIdentifier': Platform.localeName,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'open',
    });
  }
}

final feedbackServiceProvider =
    Provider<FeedbackService>((ref) => FeedbackService());

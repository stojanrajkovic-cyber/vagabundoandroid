import 'package:flutter/material.dart';

import '../../services/review/review_manager.dart';

/// Custom "Rate Vagabundo" milestone dijalog — prikazan nakon 2./5./10.
/// završenog putovanja. "Rate now" pokreće tihi In-App Review poziv.
Future<void> showRateAppDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Enjoying Vagabundo?'),
      content: const Text(
        'If you\'re enjoying planning trips with Vagabundo, we\'d love a quick rating!',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            ReviewManager.instance.requestReview();
          },
          child: const Text('Rate now'),
        ),
      ],
    ),
  );
}

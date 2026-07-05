import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';

/// Ekvivalent PasswordReauthView.swift.
///
/// ARHITEKTONSKO POJEDNOSTAVLJENJE: iOS koristi PasswordSheetController
/// (singleton + CheckedContinuation bridge) da premosti SwiftUI sheet
/// prezentaciju u async/await. Flutter-ov showDialog<String>() već vraća
/// Future koji se resolvuje kad se dijalog zatvori (Navigator.pop(context,
/// password)) — isti efekat, bez potrebe za dodatnim ObservableObject/
/// continuation ekvivalentom.
Future<String?> promptPassword(BuildContext context, String email) {
  return showDialog<String>(
    context: context,
    builder: (context) => _PasswordReauthDialog(email: email),
  );
}

class _PasswordReauthDialog extends StatefulWidget {
  const _PasswordReauthDialog({required this.email});

  final String email;

  @override
  State<_PasswordReauthDialog> createState() => _PasswordReauthDialogState();
}

class _PasswordReauthDialogState extends State<_PasswordReauthDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Confirm your password',
              style: AppTypography.cardTitle.copyWith(color: context.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'To delete your account, please enter your password for ${widget.email}.',
              style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _controller,
              obscureText: true,
              autofocus: true,
              style: AppTypography.body.copyWith(color: context.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _controller.text),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

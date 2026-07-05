import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../models/feedback_item.dart';
import '../../services/feedback/feedback_service.dart';
import '../../utils/haptics.dart';
import '../primary_button.dart';

/// Ekvivalent FeedbackSheet.swift — bug/idea toggle + poruka → Firestore.
Future<void> showFeedbackSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _FeedbackSheet(),
  );
}

class _FeedbackSheet extends ConsumerStatefulWidget {
  const _FeedbackSheet();

  @override
  ConsumerState<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends ConsumerState<_FeedbackSheet> {
  FeedbackType _type = FeedbackType.bug;
  final _controller = TextEditingController();
  bool _isSending = false;
  bool _didSucceed = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _controller.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      await ref.read(feedbackServiceProvider).submitFeedback(
            type: _type,
            message: message,
          );
      if (!mounted) return;
      Haptics.medium();
      setState(() {
        _isSending = false;
        _didSucceed = true;
      });
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) Navigator.of(context).pop();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _error = 'Could not send feedback. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.cardRadius),
          ),
        ),
        child: SafeArea(
          top: false,
          child: _didSucceed ? _buildSuccess(context) : _buildForm(context),
        ),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: context.accent, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Thanks for your feedback!',
            style: AppTypography.cardTitle.copyWith(color: context.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Send feedback',
          style: AppTypography.sectionTitle.copyWith(color: context.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
            border: Border.all(color: context.cardStroke),
          ),
          child: Row(
            children: [
              for (final type in FeedbackType.values)
                Expanded(
                  child: _TypeButton(
                    type: type,
                    isSelected: type == _type,
                    onTap: () {
                      Haptics.selection();
                      setState(() => _type = type);
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _controller,
          minLines: 4,
          maxLines: null,
          style: AppTypography.body.copyWith(color: context.textPrimary),
          decoration: InputDecoration(
            hintText: _type == FeedbackType.bug
                ? 'What went wrong?'
                : 'What would you like to see?',
            hintStyle: AppTypography.body.copyWith(color: context.textSecondary),
            filled: true,
            fillColor: context.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              borderSide: BorderSide(color: context.cardStroke),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_error!, style: AppTypography.bodySecondary.copyWith(color: Colors.red)),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: 'Send',
          isLoading: _isSending,
          onPressed:
              _controller.text.trim().isEmpty || _isSending ? null : _send,
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final FeedbackType type;
  final bool isSelected;
  final VoidCallback onTap;

  String get _label => type == FeedbackType.bug ? 'Bug' : 'Idea';

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? context.accent : context.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? context.accent.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        ),
        child: Text(
          _label,
          textAlign: TextAlign.center,
          style: AppTypography.chip.copyWith(color: color),
        ),
      ),
    );
  }
}

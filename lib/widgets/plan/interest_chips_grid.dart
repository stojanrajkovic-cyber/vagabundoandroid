import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/language.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../providers/plan_config_provider.dart';
import '../../utils/haptics.dart';
import '../pill_chip.dart';

/// Port InterestChipsGrid.swift — FlowLayout -> Flutter Wrap. Dva Wrap-a:
/// "loaded" (neselektovani, tapom se selektuju) i "selected" (sa X dugmetom
/// za uklanjanje). "Add custom interest" otvara bottom sheet sa comma-separated
/// unosom (ekvivalent AddInterestsSheet).
class InterestChipsGrid extends ConsumerWidget {
  const InterestChipsGrid({super.key, this.languageCode = kAppLanguageCode});

  final String languageCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(planConfigProvider);
    final notifier = ref.read(planConfigProvider.notifier);

    final selectedKeys = config.selectedInterestKeys.toList()..sort();
    final loaded = config.loadedInterests;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Interests',
                style: AppTypography.sectionTitle.copyWith(color: context.textPrimary),
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              icon: Icon(Icons.refresh, color: context.accent),
              onPressed: () {
                Haptics.light();
                notifier.refreshRandomInterests(lang: languageCode);
              },
            ),
          ],
        ),
        if (selectedKeys.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final key in selectedKeys)
                PillChip(
                  label: notifier.displayName(key, languageCode),
                  isSelected: true,
                  onDelete: () {
                    if (key.startsWith('custom:')) {
                      notifier.removeCustomInterest(key);
                    } else {
                      notifier.toggleInterest(key);
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final interest in loaded)
              PillChip(
                label: interest.localizedName(languageCode),
                icon: interest.icon,
                onTap: () => notifier.toggleInterest(interest.key),
              ),
            _AddCustomInterestButton(
              onSubmit: (text) => notifier.addCustomInterests(text),
            ),
          ],
        ),
      ],
    );
  }
}

class _AddCustomInterestButton extends StatelessWidget {
  const _AddCustomInterestButton({required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        onTap: () {
          Haptics.light();
          _showAddInterestsSheet(context, onSubmit);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
            border: Border.all(color: context.cardStroke, style: BorderStyle.solid),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 16, color: context.accent),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Add interest',
                style: AppTypography.chip.copyWith(color: context.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddInterestsSheet(BuildContext context, ValueChanged<String> onSubmit) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AddInterestsSheet(onSubmit: onSubmit),
    );
  }
}

class _AddInterestsSheet extends StatefulWidget {
  const _AddInterestsSheet({required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  State<_AddInterestsSheet> createState() => _AddInterestsSheetState();
}

class _AddInterestsSheetState extends State<_AddInterestsSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: context.cardStroke),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add interests',
              style: AppTypography.sectionTitle.copyWith(color: context.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Separate multiple interests with commas.',
              style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. street food, live music',
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  borderSide: BorderSide(color: context.cardStroke),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Haptics.light();
                  widget.onSubmit(_controller.text);
                  Navigator.of(context).pop();
                },
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

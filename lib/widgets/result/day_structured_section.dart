import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/colors.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../models/itinerary.dart';
import 'segment_timeline_selector.dart';

/// Ekvivalent DayStructuredSection.swift.
///
/// `day` je mutable `ItineraryDay` — `advanceVariant()`/`variants.add(...)`
/// mijenjaju objekat direktno, isto ponašanje kao `@Binding var day` u Swift-u.
/// `isGeneratingAltVariant`/`generatingAltDayNumber` su OBIČNA (ne-settable)
/// polja jer ih "roditelj kontroliše" — u praksi to znači da roditelj
/// (ResultScreen preko `onRequestAlternative`) postavlja ta stanja PRIJE i
/// POSLIJE poziva generatora, a ovaj widget ih samo čita da zna kad da
/// blur-uje/zaključa cijeli dan (isto ponašanje kao Swift @Binding, samo
/// vlasništvo je jednosmjerno umjesto dvosmjernog).
class DayStructuredSection extends StatefulWidget {
  const DayStructuredSection({
    super.key,
    required this.day,
    required this.onSelectPart,
    required this.isReadOnly,
    required this.isSavedPlan,
    required this.onRequestAlternative,
    required this.isGeneratingAltVariant,
    required this.generatingAltDayNumber,
    this.onPersistPlan,
  });

  final ItineraryDay day;
  final ValueChanged<DayPart> onSelectPart;
  final bool isReadOnly;
  final bool isSavedPlan;
  final Future<DayVariant> Function(int dayNumber) onRequestAlternative;
  final bool isGeneratingAltVariant;
  final int? generatingAltDayNumber;
  final VoidCallback? onPersistPlan;

  @override
  State<DayStructuredSection> createState() => _DayStructuredSectionState();
}

class _DayStructuredSectionState extends State<DayStructuredSection> {
  // Mora ostati u sinhronizaciji sa AIProxyItineraryGenerator._maxVariantsPerDay.
  static const int _maxVariantsPerDay = 3;

  DayPart _selectedSegment = DayPart.morning;
  DayPart? _loadingPart;

  bool get _isThisDayGenerating =>
      widget.isGeneratingAltVariant && widget.generatingAltDayNumber == widget.day.dayNumber;

  void _selectSegment(DayPart part) {
    if (_selectedSegment == part) return;
    setState(() => _selectedSegment = part);
    widget.onSelectPart(part);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _blurWhileGenerating(
          SegmentTimelineSelector(selected: _selectedSegment, onSelect: _selectSegment),
        ),
        const SizedBox(height: 12),
        Stack(
          alignment: Alignment.center,
          children: [
            _blurWhileGenerating(_contentForSelectedSegment(context)),
            if (_isThisDayGenerating) _generatingBadge(context),
          ],
        ),
      ],
    );
  }

  Widget _blurWhileGenerating(Widget child) {
    if (!_isThisDayGenerating) return child;
    return AbsorbPointer(
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Opacity(opacity: 0.4, child: child),
      ),
    );
  }

  Widget _generatingBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.cardBackground.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: context.accent),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Generating…',
            style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _contentForSelectedSegment(BuildContext context) {
    switch (_selectedSegment) {
      case DayPart.morning:
        return _variantSection(context, DayPart.morning, widget.day.morningItem, widget.day.dayStructure?.morning);
      case DayPart.afternoon:
        return _variantSection(
            context, DayPart.afternoon, widget.day.afternoonItem, widget.day.dayStructure?.afternoon);
      case DayPart.evening:
        return _variantSection(context, DayPart.evening, widget.day.eveningItem, widget.day.dayStructure?.evening);
    }
  }

  Widget _variantSection(BuildContext context, DayPart part, ItineraryItem item, List<DayBlock>? blocks) {
    final desc = item.description.trim();
    final locationName = item.locationName?.trim() ?? '';

    return Column(
      key: ValueKey(part),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: AppTypography.cardTitle.copyWith(color: context.textPrimary),
        ),
        if (desc.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(desc, style: AppTypography.body.copyWith(color: context.textPrimary)),
        ],
        if (locationName.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(locationName, style: AppTypography.bodySecondary.copyWith(color: context.textSecondary)),
        ],
        const SizedBox(height: 10),
        _blocksView(context, blocks),
        if (!widget.isReadOnly && !widget.isSavedPlan) ...[
          const SizedBox(height: AppSpacing.sm),
          _alternativeButton(context, part),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Generate a new version, or switch back to one you already created.',
            style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _blocksView(BuildContext context, List<DayBlock>? blocks) {
    if (blocks == null || blocks.isEmpty) {
      return Text(
        'No structure available for this part of the day.',
        style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cerulean.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  blocks[i].title,
                  style: AppTypography.cardTitle.copyWith(color: context.textPrimary),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final step in blocks[i].steps)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 7, right: 10),
                          child: Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: context.accent.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(step, style: AppTypography.bodySecondary.copyWith(color: context.textSecondary)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (i < blocks.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Widget _alternativeButton(BuildContext context, DayPart part) {
    final canAdvance = widget.day.canAdvanceVariant;
    final canGenerateMore = widget.day.variants.length < _maxVariantsPerDay;

    final isDisabled = widget.isReadOnly ||
        widget.isSavedPlan ||
        _isThisDayGenerating ||
        _loadingPart != null ||
        (!canAdvance && !canGenerateMore);

    final label = canAdvance ? 'Try another version' : (canGenerateMore ? 'Generate version' : 'No more versions');

    return _AltButton(
      label: label,
      showIcon: canAdvance || canGenerateMore,
      isLoading: _loadingPart == part,
      onPressed: isDisabled ? null : () => _handleAlternativeTap(part, canAdvance, canGenerateMore),
    );
  }

  Future<void> _handleAlternativeTap(DayPart part, bool canAdvance, bool canGenerateMore) async {
    if (canAdvance) {
      setState(() => _loadingPart = part);
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      setState(() {
        widget.day.advanceVariant();
        _loadingPart = null;
      });
      return;
    }

    if (widget.isReadOnly || widget.isSavedPlan || !canGenerateMore) return;

    setState(() => _loadingPart = part);
    try {
      final newVariant = await widget.onRequestAlternative(widget.day.dayNumber);
      if (!mounted) return;
      setState(() {
        widget.day.variants.add(newVariant);
        widget.day.activeVariantIndex = widget.day.variants.length - 1;
      });
      widget.onPersistPlan?.call();
    } catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Error'),
          content: Text('$e'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('OK')),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingPart = null);
    }
  }
}

/// Isti gradient look kao PrimaryButton, ali sa opcionalnim trailing icon
/// slotom (Swift original ima "arrow.triangle.2.circlepath" pored teksta) —
/// izdvojeno ovdje umjesto proširivanja dijeljenog PrimaryButton widgeta.
class _AltButton extends StatelessWidget {
  const _AltButton({
    required this.label,
    required this.showIcon,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool showIcon;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? 0.6 : 1.0,
      child: Container(
        height: 44,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          gradient: const LinearGradient(
            colors: [AppColors.accent, AppColors.accentDark],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
            onTap: isLoading ? null : onPressed,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label, style: AppTypography.button.copyWith(color: Colors.white)),
                        if (showIcon) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.autorenew, size: 14, color: Colors.white70),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

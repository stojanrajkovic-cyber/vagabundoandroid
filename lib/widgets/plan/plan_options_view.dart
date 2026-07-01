import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../providers/location_provider.dart';
import '../../providers/plan_config_provider.dart';
import '../../utils/haptics.dart';

/// Port PlanOptionsView.swift — days stepper, kids toggle, car toggle +
/// uslovni pod-blok (useCurrentLocation, origin, max driving hours,
/// break-every-minutes, allow-overnight-split).
class PlanOptionsView extends ConsumerWidget {
  const PlanOptionsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(planConfigProvider);
    final notifier = ref.read(planConfigProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: context.cardStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DaysStepper(
            days: config.days,
            onChanged: (d) {
              Haptics.selection();
              notifier.setDays(d);
            },
          ),
          const Divider(height: AppSpacing.xl),
          _ToggleRow(
            label: 'Travelling with kids',
            value: config.withKids,
            onChanged: (v) {
              Haptics.light();
              notifier.setWithKids(v);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _ToggleRow(
            label: 'Travelling by car',
            value: config.byCar,
            onChanged: (v) {
              Haptics.light();
              notifier.setByCar(v);
            },
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: config.byCar
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: _CarOptionsBlock(config: config, notifier: notifier),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _CarOptionsBlock extends ConsumerWidget {
  const _CarOptionsBlock({required this.config, required this.notifier});

  final PlanConfigState config;
  final PlanConfigNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ToggleRow(
          label: 'Use my current location',
          value: config.useCurrentLocation,
          onChanged: (v) {
            Haptics.light();
            notifier.setUseCurrentLocation(v);
            if (v) {
              ref.read(deviceLocationManagerProvider).ensurePermissionAndFetch();
            }
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: config.useCurrentLocation
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: _OriginField(
                    initialValue: config.originQuery,
                    onChanged: notifier.setOriginQuery,
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        _NumberStepper(
          label: 'Max driving hours / day',
          value: config.maxDrivingHoursPerDay,
          step: 0.5,
          min: 1,
          max: 12,
          formatter: (v) => '${v.toStringAsFixed(1)}h',
          onChanged: notifier.setMaxDrivingHoursPerDay,
        ),
        const SizedBox(height: AppSpacing.sm),
        _NumberStepper(
          label: 'Break every',
          value: config.breakEveryMinutes.toDouble(),
          step: 15,
          min: 30,
          max: 240,
          formatter: (v) => '${v.round()} min',
          onChanged: (v) => notifier.setBreakEveryMinutes(v.round()),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ToggleRow(
          label: 'Allow overnight split',
          value: config.allowOvernightSplit,
          onChanged: (v) {
            Haptics.light();
            notifier.setAllowOvernightSplit(v);
          },
        ),
      ],
    );
  }
}

class _OriginField extends StatefulWidget {
  const _OriginField({required this.initialValue, required this.onChanged});

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<_OriginField> createState() => _OriginFieldState();
}

class _OriginFieldState extends State<_OriginField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: 'Starting point',
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          borderSide: BorderSide(color: context.cardStroke),
        ),
      ),
    );
  }
}

class _DaysStepper extends StatelessWidget {
  const _DaysStepper({required this.days, required this.onChanged});

  final int days;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Days',
            style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        _StepperButton(
          icon: Icons.remove,
          onTap: days > 1 ? () => onChanged(days - 1) : null,
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$days',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        _StepperButton(
          icon: Icons.add,
          onTap: days < 7 ? () => onChanged(days + 1) : null,
        ),
      ],
    );
  }
}

class _NumberStepper extends StatelessWidget {
  const _NumberStepper({
    required this.label,
    required this.value,
    required this.step,
    required this.min,
    required this.max,
    required this.formatter,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double step;
  final double min;
  final double max;
  final String Function(double) formatter;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: context.textPrimary, fontSize: 14)),
        ),
        _StepperButton(
          icon: Icons.remove,
          onTap: value - step >= min
              ? () {
                  Haptics.selection();
                  onChanged(value - step);
                }
              : null,
        ),
        SizedBox(
          width: 56,
          child: Text(
            formatter(value),
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        _StepperButton(
          icon: Icons.add,
          onTap: value + step <= max
              ? () {
                  Haptics.selection();
                  onChanged(value + step);
                }
              : null,
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? context.accent.withValues(alpha: 0.10) : context.cardStroke,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: enabled ? context.accent : context.textSecondary),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: context.textPrimary, fontSize: 16)),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: context.accent,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../providers/location_selection_provider.dart';
import '../../services/location/countries_cities_service.dart';
import '../../utils/haptics.dart';

/// Port CountryCityPickerView.swift — tri dropdown-like dugmeta (Country,
/// State [samo ako isUSSelected], City) koja otvaraju searchable bottom sheet.
class CountryCityPicker extends ConsumerWidget {
  const CountryCityPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(locationSelectionProvider);
    final notifier = ref.read(locationSelectionProvider.notifier);

    final cityEnabled =
        state.selectedCountry != null && (!state.isUSSelected || state.selectedStateCode != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PickerButton(
          label: 'Country',
          value: state.selectedCountry?.name,
          onTap: () => _showCountrySheet(context, ref),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (state.isUSSelected) ...[
          _PickerButton(
            label: 'State',
            value: _selectedStateName(state),
            onTap: () => _showStateSheet(context, ref),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        _PickerButton(
          label: 'City',
          value: state.selectedCity?.displayName,
          enabled: cityEnabled,
          isLoading: state.isLoadingCities,
          onTap: cityEnabled ? () => _showCitySheet(context, ref) : null,
        ),
        if (state.citiesLoadError != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            state.citiesLoadError!,
            style: TextStyle(color: Colors.red.shade400, fontSize: 12),
          ),
        ],
        if (notifier.selectedCountryMetadata() != null) ...[
          const SizedBox(height: AppSpacing.xs),
          _CountryMetadataLine(entry: notifier.selectedCountryMetadata()!),
        ],
      ],
    );
  }

  String? _selectedStateName(LocationSelectionState state) {
    final code = state.selectedStateCode;
    if (code == null) return null;
    for (final s in state.availableStates) {
      if (s.code == code) return s.name;
    }
    return code;
  }

  void _showCountrySheet(BuildContext context, WidgetRef ref) {
    Haptics.light();
    final countries = ref.read(locationSelectionProvider).countries;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SearchableListSheet<Country>(
        title: 'Select country',
        items: countries,
        itemLabel: (c) => c.name,
        onSelected: (country) async {
          Navigator.of(sheetContext).pop();
          await ref.read(locationSelectionProvider.notifier).selectCountry(country);
        },
      ),
    );
  }

  void _showStateSheet(BuildContext context, WidgetRef ref) {
    Haptics.light();
    final states = ref.read(locationSelectionProvider).availableStates;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SearchableListSheet<USState>(
        title: 'Select state',
        items: states,
        itemLabel: (s) => s.name,
        onSelected: (s) {
          Navigator.of(sheetContext).pop();
          ref.read(locationSelectionProvider.notifier).selectState(s.code);
        },
      ),
    );
  }

  void _showCitySheet(BuildContext context, WidgetRef ref) {
    Haptics.light();
    final cities = ref.read(locationSelectionProvider).filteredCities;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SearchableListSheet<City>(
        title: 'Select city',
        items: cities,
        itemLabel: (c) => c.displayName,
        onSelected: (city) {
          Navigator.of(sheetContext).pop();
          ref.read(locationSelectionProvider.notifier).selectCity(city);
        },
      ),
    );
  }
}

class _CountryMetadataLine extends StatelessWidget {
  const _CountryMetadataLine({required this.entry});

  final CountryEntry entry;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (entry.capital != null) 'Capital: ${entry.capital}',
      if (entry.currency != null) 'Currency: ${entry.currency}',
      if (entry.population != null) 'Population: ${entry.population}',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' · '),
      style: TextStyle(color: context.textSecondary, fontSize: 12),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.label,
    required this.value,
    required this.onTap,
    this.enabled = true,
    this.isLoading = false,
  });

  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          onTap: enabled ? onTap : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(color: context.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value ?? 'Select $label'.toLowerCase(),
                        style: TextStyle(
                          color: value != null ? context.textPrimary : context.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: context.accent),
                  )
                else
                  Icon(Icons.expand_more, color: context.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchableListSheet<T> extends StatefulWidget {
  const _SearchableListSheet({
    required this.title,
    required this.items,
    required this.itemLabel,
    required this.onSelected,
    super.key,
  });

  final String title;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onSelected;

  @override
  State<_SearchableListSheet<T>> createState() => _SearchableListSheetState<T>();
}

class _SearchableListSheetState<T> extends State<_SearchableListSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.items
        : widget.items
            .where((e) => widget.itemLabel(e).toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
            border: Border.all(color: context.cardStroke),
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.cardStroke,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: TextField(
                  autofocus: false,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search…',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                      borderSide: BorderSide(color: context.cardStroke),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No results',
                          style: TextStyle(color: context.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return ListTile(
                            title: Text(
                              widget.itemLabel(item),
                              style: TextStyle(color: context.textPrimary),
                            ),
                            onTap: () {
                              Haptics.selection();
                              widget.onSelected(item);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

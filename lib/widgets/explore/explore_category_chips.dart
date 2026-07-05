import 'package:flutter/material.dart';

import '../../app/theme/spacing.dart';
import '../../models/poi_category.dart';
import '../../utils/haptics.dart';
import '../pill_chip.dart';

/// Wrap od PillChip po kExploreCategories — POI filter kategorije (NE
/// Supabase trip-interesi iz Plan ekrana). Selekcija je UI-only, čuvana u
/// parent widget-u (ExploreControls/ExploreScreen) do klika na CTA.
class ExploreCategoryChips extends StatelessWidget {
  const ExploreCategoryChips({
    super.key,
    required this.selectedKeys,
    required this.onToggle,
  });

  final Set<String> selectedKeys;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final category in kExploreCategories)
          PillChip(
            label: category.label,
            isSelected: selectedKeys.contains(category.key),
            onTap: () {
              Haptics.selection();
              onToggle(category.key);
            },
          ),
      ],
    );
  }
}

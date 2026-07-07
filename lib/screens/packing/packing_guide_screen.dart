import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../models/packing_guide.dart';

/// Ekvivalent PackingGuideView.swift.
class PackingGuideScreen extends StatefulWidget {
  const PackingGuideScreen(
      {super.key, required this.guide, required this.onUpdate});

  final PackingGuide guide;

  /// Pozvano prilikom zatvaranja ekrana (nakon check/uncheck, dodavanja ili
  /// brisanja stavki) — pozivalac je odgovoran za persistenciju (Firestore).
  final void Function(PackingGuide updated) onUpdate;

  @override
  State<PackingGuideScreen> createState() => _PackingGuideScreenState();
}

class _PackingGuideScreenState extends State<PackingGuideScreen> {
  late final List<PackingItem> _items = List.of(widget.guide.items);

  @override
  Widget build(BuildContext context) {
    final grouped = <PackingCategory, List<PackingItem>>{};
    for (final category in PackingCategory.values) {
      final itemsInCategory =
          _items.where((i) => i.category == category).toList()
            ..sort((a, b) {
              if (a.isChecked != b.isChecked) {
                return a.isChecked ? 1 : -1;
              }
              return a
                  .displayText()
                  .toLowerCase()
                  .compareTo(b.displayText().toLowerCase());
            });
      if (itemsInCategory.isNotEmpty) {
        grouped[category] = itemsInCategory;
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _closeAndSave();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: TextButton(
            onPressed: _closeAndSave,
            child: Text('Close',
                style: AppTypography.body.copyWith(color: context.accent)),
          ),
          leadingWidth: 80,
          title: const Text('Packing guide'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add item',
              onPressed: _showAddItemSheet,
            ),
          ],
        ),
        body: SafeArea(
          child: grouped.isEmpty
              ? Center(
                  child: Text(
                    'No items yet',
                    style: AppTypography.body
                        .copyWith(color: context.textSecondary),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  children: [
                    if (widget.guide.notes != null &&
                        widget.guide.notes!.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: context.accent.withValues(alpha: 0.10),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius),
                          border: Border.all(
                              color: context.accent.withValues(alpha: 0.30)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.umbrella_outlined,
                                size: 18, color: context.accent),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                widget.guide.notes!,
                                style: AppTypography.bodySecondary
                                    .copyWith(color: context.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    for (final entry in grouped.entries) ...[
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Text(
                          entry.key.label,
                          style: AppTypography.sectionTitle
                              .copyWith(color: context.textPrimary),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: context.cardBackground,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius),
                          border: Border.all(color: context.cardStroke),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < entry.value.length; i++) ...[
                              if (i > 0)
                                Divider(height: 1, color: context.cardStroke),
                              _buildRow(entry.value[i]),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildRow(PackingItem item) {
    final row = InkWell(
      onTap: () => _toggleChecked(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(
              item.isChecked ? Icons.check_circle : Icons.circle_outlined,
              color: item.isChecked ? Colors.green : context.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                item.displayText(),
                style: AppTypography.body.copyWith(
                  color: item.isChecked
                      ? context.textSecondary
                      : context.textPrimary,
                  decoration:
                      item.isChecked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!item.isCustom) return row;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        color: Colors.red,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => _deleteItem(item),
      child: row,
    );
  }

  void _toggleChecked(PackingItem item) {
    setState(() => item.isChecked = !item.isChecked);
  }

  void _deleteItem(PackingItem item) {
    setState(() => _items.removeWhere((i) => i.id == item.id));
  }

  void _closeAndSave() {
    final updated = PackingGuide(
      id: widget.guide.id,
      startDate: widget.guide.startDate,
      endDate: widget.guide.endDate,
      items: _items,
      notes: widget.guide.notes,
      createdAt: widget.guide.createdAt,
    );
    widget.onUpdate(updated);
    Navigator.of(context).pop();
  }

  Future<void> _showAddItemSheet() async {
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: sheetContext.cardBackground,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.cardRadius)),
                border: Border.all(color: sheetContext.cardStroke),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add item',
                    style: AppTypography.sectionTitle
                        .copyWith(color: sheetContext.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: AppTypography.body
                        .copyWith(color: sheetContext.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g. Travel pillow',
                      hintStyle: AppTypography.body
                          .copyWith(color: sheetContext.textSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                        borderSide: BorderSide(color: sheetContext.cardStroke),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                        borderSide: BorderSide(color: sheetContext.accent),
                      ),
                    ),
                    onSubmitted: (_) =>
                        _submitAddItem(sheetContext, controller.text),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: sheetContext.accent),
                      onPressed: () =>
                          _submitAddItem(sheetContext, controller.text),
                      child: Text('Add',
                          style: AppTypography.button
                              .copyWith(color: sheetContext.onAccent)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _submitAddItem(BuildContext sheetContext, String rawText) {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _items.add(PackingItem(
          category: PackingCategory.reminders, title: trimmed, isCustom: true));
    });
    Navigator.of(sheetContext).pop();
  }
}

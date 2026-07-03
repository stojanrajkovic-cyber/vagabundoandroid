import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../models/itinerary.dart';
import '../../models/local_offline_plan.dart';
import '../../models/plan_document.dart';
import '../../providers/auth_provider.dart';
import '../../providers/firestore_provider.dart';
import '../../providers/saved_plans_provider.dart';
import '../../services/connectivity/connectivity_service.dart';
import '../../services/firestore/firestore_service.dart';
import '../../widgets/saved/offline_sync_banner.dart';
import '../../widgets/saved/saved_plan_row.dart';
import '../result/result_screen.dart';

/// Port SavedPlansView.swift (Faza 5) — lista sačuvanih planova (planned/
/// completed) sa live Firestore streamom, offline mirror fallback, i
/// offline sync banner/prompt.
class SavedPlansScreen extends ConsumerStatefulWidget {
  const SavedPlansScreen({super.key});

  @override
  ConsumerState<SavedPlansScreen> createState() => _SavedPlansScreenState();
}

class _SavedPlansScreenState extends ConsumerState<SavedPlansScreen> {
  List<LocalOfflinePlan> _offlinePlans = const [];
  bool _isLoadingOffline = true;
  bool _syncDialogShown = false;

  @override
  void initState() {
    super.initState();
    _loadOfflinePlans();
  }

  Future<void> _loadOfflinePlans() async {
    if (mounted) setState(() => _isLoadingOffline = true);
    final plans = await LocalOfflinePlan.loadAllOfflinePlans();
    if (!mounted) return;
    setState(() {
      _offlinePlans = plans;
      _isLoadingOffline = false;
    });
  }

  void _showSyncPromptDialog(int missingCount) {
    if (_syncDialogShown) return;
    _syncDialogShown = true;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sync plans for offline use?'),
        content: Text(
          '$missingCount ${missingCount == 1 ? 'plan is' : 'plans are'} not '
          'available offline yet. Sync now so you can open them without a '
          'connection.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(savedPlansProvider.notifier).dismissSyncPrompt();
            },
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(savedPlansProvider.notifier).syncMissingOfflinePlans();
            },
            child: const Text('Sync now'),
          ),
        ],
      ),
    ).then((_) => _syncDialogShown = false);
  }

  Future<void> _openPlan(PlanDocument plan, {required bool isCompleted}) async {
    final itinerary = ItineraryResponse.fromJsonString(plan.itineraryJSON);
    if (itinerary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this plan — the saved data looks corrupted.')),
      );
      return;
    }

    final uid = ref.read(authStateProvider).asData?.value?.uid;

    context.push(
      '/result',
      extra: ResultScreenArgs(
        itinerary: itinerary,
        planId: plan.id,
        isReadOnly: isCompleted,
        showMarkCompleted: !isCompleted,
        showsCloseButton: false,
        onMarkCompleted: (isCompleted || uid == null)
            ? null
            : () => FirestoreService.instance.updatePlanStatus(
                  uid: uid,
                  planId: plan.id,
                  status: PlanStatus.completed,
                ),
      ),
    );
  }

  void _openOfflinePlan(LocalOfflinePlan plan) {
    context.push(
      '/result',
      extra: ResultScreenArgs(
        itinerary: plan.itinerary,
        planId: plan.id,
        isReadOnly: true,
        showMarkCompleted: false,
        showsCloseButton: false,
      ),
    );
  }

  double? _roadTripDistanceKm(PlanDocument plan) {
    return ItineraryResponse.fromJsonString(plan.itineraryJSON)?.roadTrip?.totalDistanceKm;
  }

  String _formatDate(DateTime date) => DateFormat.yMMMd().format(date);

  @override
  Widget build(BuildContext context) {
    final isOffline = ref.watch(isOfflineProvider);
    final plansAsync = ref.watch(userPlansProvider);
    final savedPlansState = ref.watch(savedPlansProvider);

    ref.listen<SavedPlansState>(savedPlansProvider, (previous, next) {
      if (next.showSyncPrompt && (previous == null || !previous.showSyncPrompt)) {
        _showSyncPromptDialog(next.missingOfflineIds.length);
      }
      // Osvježi offline listu kad sync završi, da nova lokalna kopija
      // odmah bude vidljiva u offline prikazu.
      if (previous != null && previous.isSyncing && !next.isSyncing) {
        _loadOfflinePlans();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved plans'),
        actions: [
          if (!isOffline)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () => ref.invalidate(userPlansProvider),
            ),
        ],
      ),
      body: SafeArea(
        child: isOffline
            ? _buildOfflineBody(context)
            : _buildOnlineBody(context, plansAsync, savedPlansState),
      ),
    );
  }

  Widget _buildOnlineBody(
    BuildContext context,
    AsyncValue<List<PlanDocument>> plansAsync,
    SavedPlansState savedPlansState,
  ) {
    return plansAsync.when(
      data: (plans) {
        if (plans.isEmpty) return _buildEmptyState(context);

        final uid = ref.read(authStateProvider).asData?.value?.uid;
        final planned = plans.where((p) => p.status == PlanStatus.planned).toList();
        final completed = plans.where((p) => p.status == PlanStatus.completed).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(userPlansProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxl),
            children: [
              if (savedPlansState.missingOfflineIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: OfflineSyncBanner(
                    count: savedPlansState.missingOfflineIds.length,
                    isSyncing: savedPlansState.isSyncing,
                    onSyncTap: () => ref.read(savedPlansProvider.notifier).syncMissingOfflinePlans(),
                  ),
                ),
              if (planned.isNotEmpty) ...[
                _sectionHeader(context, 'Planned journeys'),
                const SizedBox(height: AppSpacing.sm),
                for (final plan in planned)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: SavedPlanRow(
                      id: plan.id,
                      status: SavedPlanRowStatus.planned,
                      city: plan.city,
                      days: plan.days,
                      distanceKm: _roadTripDistanceKm(plan),
                      trailingLabel: _formatDate(plan.createdAt),
                      onTap: () => _openPlan(plan, isCompleted: false),
                      onComplete: uid == null
                          ? null
                          : () => FirestoreService.instance.updatePlanStatus(
                                uid: uid,
                                planId: plan.id,
                                status: PlanStatus.completed,
                              ),
                      onDelete: uid == null
                          ? null
                          : () => FirestoreService.instance.deletePlan(uid: uid, planId: plan.id),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (completed.isNotEmpty) ...[
                _sectionHeader(context, 'Completed journeys'),
                const SizedBox(height: AppSpacing.sm),
                for (final plan in completed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: SavedPlanRow(
                      id: plan.id,
                      status: SavedPlanRowStatus.completed,
                      city: plan.city,
                      days: plan.days,
                      distanceKm: _roadTripDistanceKm(plan),
                      trailingLabel: _formatDate(plan.createdAt),
                      onTap: () => _openPlan(plan, isCompleted: true),
                      onDelete: uid == null
                          ? null
                          : () => FirestoreService.instance.deletePlan(uid: uid, planId: plan.id),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'Failed to load plans: $e',
          style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
        ),
      ),
    );
  }

  Widget _buildOfflineBody(BuildContext context) {
    if (_isLoadingOffline) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_offlinePlans.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxl),
      children: [
        _sectionHeader(context, 'Planned journeys'),
        const SizedBox(height: AppSpacing.sm),
        for (final plan in _offlinePlans)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: SavedPlanRow(
              id: plan.id,
              status: SavedPlanRowStatus.planned,
              city: plan.itinerary.city,
              days: plan.itinerary.days.length,
              distanceKm: plan.itinerary.roadTrip?.totalDistanceKm,
              trailingLabel: 'Offline available',
              onTap: () => _openOfflinePlan(plan),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: context.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No saved plans yet',
              style: AppTypography.sectionTitle.copyWith(color: context.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Plans you generate will show up here so you can revisit them anytime.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Text(title, style: AppTypography.sectionTitle.copyWith(color: context.textPrimary));
  }
}

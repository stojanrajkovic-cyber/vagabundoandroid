import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/itinerary.dart';
import '../models/plan_document.dart';
import '../services/storage/local_plan_mirror.dart';
import 'firestore_provider.dart';

/// Isti ključ kao iOS `@AppStorage("offline_sync_dismissed_at")`.
const _dismissedAtKey = 'offline_sync_dismissed_at';
const _promptCooldown = Duration(days: 7);

class SavedPlansState {
  const SavedPlansState({
    this.missingOfflineIds = const [],
    this.showSyncPrompt = false,
    this.isSyncing = false,
  });

  /// planId-jevi (status == planned) koji NISU lokalno keširani preko
  /// [LocalPlanMirror].
  final List<String> missingOfflineIds;
  final bool showSyncPrompt;
  final bool isSyncing;

  SavedPlansState copyWith({
    List<String>? missingOfflineIds,
    bool? showSyncPrompt,
    bool? isSyncing,
  }) {
    return SavedPlansState(
      missingOfflineIds: missingOfflineIds ?? this.missingOfflineIds,
      showSyncPrompt: showSyncPrompt ?? this.showSyncPrompt,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

/// Orkestrira offline sync logiku (Saved Plans ekran, Faza 5) — prati
/// [userPlansProvider] i računa koji planirani (planned) planovi nemaju
/// lokalnu kopiju, i kad treba ponuditi sync prompt.
class SavedPlansNotifier extends StateNotifier<SavedPlansState> {
  SavedPlansNotifier(this._ref) : super(const SavedPlansState()) {
    // fireImmediately pokriva i "poziva se kad se ekran otvori" (prvi read
    // providera pokreće ovaj listener odmah) i "kad userPlansProvider
    // emituje novu listu" (svaka sljedeća promjena).
    _ref.listen<AsyncValue<List<PlanDocument>>>(
      userPlansProvider,
      (previous, next) {
        final plans = next.asData?.value;
        if (plans != null) {
          checkMissingOfflinePlans(plans);
        }
      },
      fireImmediately: true,
    );
  }

  final Ref _ref;

  Future<void> checkMissingOfflinePlans(List<PlanDocument> plans) async {
    final planned = plans.where((p) => p.status == PlanStatus.planned).toList();
    final serverIds = planned.map((p) => p.id).toSet();
    final deviceIds = (await LocalPlanMirror.allPlanIds()).toSet();
    final missing = serverIds.difference(deviceIds).toList();

    var showPrompt = false;
    if (missing.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final dismissedAtMs = prefs.getInt(_dismissedAtKey);
      if (dismissedAtMs == null) {
        showPrompt = true;
      } else {
        final dismissedAt = DateTime.fromMillisecondsSinceEpoch(dismissedAtMs);
        showPrompt = DateTime.now().difference(dismissedAt) > _promptCooldown;
      }
    }

    if (!mounted) return;
    state = state.copyWith(missingOfflineIds: missing, showSyncPrompt: showPrompt);
  }

  Future<void> syncMissingOfflinePlans() async {
    if (state.isSyncing || state.missingOfflineIds.isEmpty) return;
    state = state.copyWith(isSyncing: true, showSyncPrompt: false);

    final plans = _ref.read(userPlansProvider).asData?.value ?? const <PlanDocument>[];
    final byId = {for (final p in plans) p.id: p};

    for (final id in state.missingOfflineIds) {
      final plan = byId[id];
      if (plan == null) continue;
      final itinerary = ItineraryResponse.fromJsonString(plan.itineraryJSON);
      if (itinerary == null) continue;
      await LocalPlanMirror.save(id, itinerary);
    }

    final deviceIds = (await LocalPlanMirror.allPlanIds()).toSet();
    final stillMissing =
        state.missingOfflineIds.where((id) => !deviceIds.contains(id)).toList();

    if (!mounted) return;
    state = state.copyWith(missingOfflineIds: stillMissing, isSyncing: false);
  }

  Future<void> dismissSyncPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dismissedAtKey, DateTime.now().millisecondsSinceEpoch);
    if (!mounted) return;
    state = state.copyWith(showSyncPrompt: false);
  }
}

final savedPlansProvider =
    StateNotifierProvider<SavedPlansNotifier, SavedPlansState>((ref) {
  return SavedPlansNotifier(ref);
});

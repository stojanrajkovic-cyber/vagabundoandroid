import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app/theme/spacing.dart';
import '../../models/itinerary.dart';
import '../../models/plan_document.dart';
import '../../providers/ai_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore/firestore_service.dart';
import '../../widgets/result/day_card.dart';
import '../../widgets/result/day_selector.dart';
import '../../widgets/result/road_trip_section.dart';
import '../../widgets/result/trip_summary_card.dart';

/// Ekvivalent ResultView.swift (samo in-scope dijelovi za Fazu 4 — vidi
/// TODO komentare za sve što je namjerno izostavljeno).
class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key, required this.itinerary, this.planId});

  final ItineraryResponse itinerary;

  /// null = svježe generisan plan (treba se sačuvati pri zatvaranju),
  /// ne-null = otvoren iz Saved Plans (Faza 5) — ne re-snima se ovdje.
  final String? planId;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  late final ItineraryResponse _workingItinerary = widget.itinerary;

  int _selectedPageIndex = 0;
  bool _isGeneratingAltVariant = false;
  int? _generatingAltDayNumber;
  bool _readyToPop = false;

  bool get _isSavedPlan => widget.planId != null;

  @override
  Widget build(BuildContext context) {
    final hasRoadTrip = _workingItinerary.roadTrip != null;

    return PopScope(
      canPop: _readyToPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handlePopAttempt();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_workingItinerary.city.isEmpty ? 'Itinerary' : _workingItinerary.city),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),
                TripSummaryCard(itinerary: _workingItinerary),
                const SizedBox(height: AppSpacing.lg),
                DaySelector(
                  itinerary: _workingItinerary,
                  selectedPageIndex: _selectedPageIndex,
                  onSelect: (i) => setState(() => _selectedPageIndex = i),
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _buildSelectedPage(hasRoadTrip),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedPage(bool hasRoadTrip) {
    if (hasRoadTrip && _selectedPageIndex == 0) {
      return RoadTripSection(trip: _workingItinerary.roadTrip!);
    }

    final baseIndex = hasRoadTrip ? 1 : 0;
    final dayIndex = _selectedPageIndex - baseIndex;
    if (dayIndex < 0 || dayIndex >= _workingItinerary.days.length) {
      return const SizedBox.shrink();
    }

    final day = _workingItinerary.days[dayIndex];
    LatLng? fallbackCenter;
    if (_workingItinerary.cityLat != null && _workingItinerary.cityLon != null) {
      fallbackCenter = LatLng(_workingItinerary.cityLat!, _workingItinerary.cityLon!);
    }

    return DayCard(
      key: ValueKey(day.dayNumber),
      day: day,
      fallbackCenter: fallbackCenter,
      onSelectPart: (_) {},
      // TODO Faza 5: propagiraj stvarni isReadOnly (npr. read-only prikaz
      // dijeljenog plana) — za sada svježe generisan plan je uvijek editabilan.
      isReadOnly: false,
      isSavedPlan: _isSavedPlan,
      isGeneratingAltVariant: _isGeneratingAltVariant,
      generatingAltDayNumber: _generatingAltDayNumber,
      onRequestAlternative: _handleRequestAlternative,
      onPersistPlan: _persistPlan,
    );
  }

  /// Postavlja "globalno" isGeneratingAltVariant/generatingAltDayNumber PRIJE
  /// poziva generatora i čisti ih POSLIJE — DayStructuredSection samo čita
  /// ta polja da zna kad da blur-uje dan (vidi napomenu u day_structured_section.dart).
  Future<DayVariant> _handleRequestAlternative(int dayNumber) async {
    setState(() {
      _isGeneratingAltVariant = true;
      _generatingAltDayNumber = dayNumber;
    });
    try {
      final generator = ref.read(itineraryGeneratorProvider);
      return await generator.generateAlternativeVariant(plan: _workingItinerary, dayNumber: dayNumber);
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingAltVariant = false;
          _generatingAltDayNumber = null;
        });
      }
    }
  }

  void _persistPlan() {
    // TODO Faza 5: persist promjene postojećeg (saved) plana natrag u
    // Firestore kad korisnik doda alternativnu varijantu na već sačuvanom planu.
  }

  Future<void> _handlePopAttempt() async {
    await _persistOnClose();
    if (!mounted) return;
    setState(() => _readyToPop = true);
    Navigator.of(context).maybePop();
  }

  /// Ekvivalent saveBeforeClosing() iz ResultView.swift — samo za svježe
  /// generisane planove (planId == null) i ulogovanog korisnika.
  Future<void> _persistOnClose() async {
    if (widget.planId != null) return;

    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;

    final plan = PlanDocument.create(
      city: _workingItinerary.city,
      days: _workingItinerary.days.length,
      languageCode: _workingItinerary.promptSnapshot?.languageCode ?? 'en',
      generatorModel: _workingItinerary.generatorModel,
      itineraryJSON: jsonEncode(_workingItinerary.toJson()),
      cityLat: _workingItinerary.cityLat,
      cityLon: _workingItinerary.cityLon,
    );

    try {
      await FirestoreService.instance.savePlan(uid: user.uid, plan: plan);
      // TODO Faza 5: VisitedCity zapis (addVisit) i profileStore.refreshPlans()
      // ekvivalent — preskočeno za sada, samo savePlan.
    } catch (_) {
      // TODO Faza 5: prikaži grešku korisniku / retry umjesto tihog gutanja.
    }
  }
}

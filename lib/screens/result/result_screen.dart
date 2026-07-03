import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../models/itinerary.dart';
import '../../models/plan_document.dart';
import '../../providers/ai_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/share_link_provider.dart';
import '../../services/firestore/firestore_service.dart';
import '../../services/share/itinerary_pdf_generator.dart';
import '../../services/share/itinerary_text_formatter.dart';
import '../../services/share/share_link_service.dart';
import '../../widgets/result/day_card.dart';
import '../../widgets/result/day_selector.dart';
import '../../widgets/result/road_trip_section.dart';
import '../../widgets/result/trip_summary_card.dart';
import '../../widgets/result/weather_card.dart';
import '../../widgets/share/manage_share_link_sheet.dart';

/// Argumenti za '/result' rutu kad se otvara iz Saved Plans (Faza 5) — vidi
/// router.dart. Svježe generisan plan (Faza 3/4 flow) i dalje prosljeđuje
/// samo ItineraryResponse kroz `extra`; router pravi ResultScreen sa
/// defaultima u tom slučaju (planId: null, isReadOnly: false, itd).
class ResultScreenArgs {
  const ResultScreenArgs({
    required this.itinerary,
    this.planId,
    this.isReadOnly = false,
    this.showMarkCompleted = false,
    this.onMarkCompleted,
    this.showsCloseButton = true,
  });

  final ItineraryResponse itinerary;
  final String? planId;
  final bool isReadOnly;
  final bool showMarkCompleted;
  final VoidCallback? onMarkCompleted;
  final bool showsCloseButton;
}

/// Ekvivalent ResultView.swift (samo in-scope dijelovi za Fazu 4 — vidi
/// TODO komentare za sve što je namjerno izostavljeno).
///
/// Faza 5 dodaje: isReadOnly/showMarkCompleted (otvaranje iz Saved Plans),
/// showsCloseButton (sakriva AppBar back dugme kad se koristi kao
/// NavigationLink destinacija), i share dugme (ShareLinkService).
class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({
    super.key,
    required this.itinerary,
    this.planId,
    this.isReadOnly = false,
    this.showMarkCompleted = false,
    this.onMarkCompleted,
    this.showsCloseButton = true,
  });

  final ItineraryResponse itinerary;

  /// null = svježe generisan plan (treba se sačuvati pri zatvaranju),
  /// ne-null = otvoren iz Saved Plans (Faza 5) — ne re-snima se ovdje.
  final String? planId;

  /// Sakriva "generiši alternativu" dugme u svakom DayStructuredSection-u
  /// (npr. za već completed planove).
  final bool isReadOnly;

  /// Prikazuje "Mark as completed" akciju u AppBar-u.
  final bool showMarkCompleted;
  final VoidCallback? onMarkCompleted;

  /// false sakriva AppBar back dugme (koristi se kad je ovo NavigationLink
  /// destinacija unutar Saved Plans — GoRouter i dalje ima sistemski back
  /// gesture/dugme, ovo je samo za AppBar-ov automatski leading widget).
  final bool showsCloseButton;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  late final ItineraryResponse _workingItinerary = widget.itinerary;

  int _selectedPageIndex = 0;
  bool _isGeneratingAltVariant = false;
  int? _generatingAltDayNumber;
  bool _readyToPop = false;
  bool _isShareActionInProgress = false;

  bool get _isSavedPlan => widget.planId != null;

  /// dayNumber trenutno prikazanog dana (za WeatherCard) — kad je selektovana
  /// road trip pregled stranica (nema konkretan dan), fallback na prvi dan.
  int get _currentDayNumber {
    final hasRoadTrip = _workingItinerary.roadTrip != null;
    final baseIndex = hasRoadTrip ? 1 : 0;
    final dayIndex = _selectedPageIndex - baseIndex;
    if (dayIndex < 0 || dayIndex >= _workingItinerary.days.length) {
      return _workingItinerary.days.isNotEmpty ? _workingItinerary.days.first.dayNumber : 1;
    }
    return _workingItinerary.days[dayIndex].dayNumber;
  }

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
          automaticallyImplyLeading: widget.showsCloseButton,
          title: Text(_workingItinerary.city.isEmpty ? 'Itinerary' : _workingItinerary.city),
          actions: [
            IconButton(
              icon: _isShareActionInProgress
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share_outlined),
              tooltip: 'Share plan',
              onPressed: _isShareActionInProgress ? null : _showShareOptionsSheet,
            ),
            if (widget.showMarkCompleted)
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                tooltip: 'Mark as completed',
                onPressed: _handleMarkCompleted,
              ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),
                TripSummaryCard(itinerary: _workingItinerary),
                if (_workingItinerary.cityLat != null && _workingItinerary.cityLon != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: WeatherCard(
                      lat: _workingItinerary.cityLat!,
                      lon: _workingItinerary.cityLon!,
                      city: _workingItinerary.city,
                      dayNumber: _currentDayNumber,
                    ),
                  ),
                ],
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
      isReadOnly: widget.isReadOnly,
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
    // TODO Faza 5b: persist promjene postojećeg (saved) plana natrag u
    // Firestore kad korisnik doda alternativnu varijantu na već sačuvanom planu.
  }

  void _handleMarkCompleted() {
    widget.onMarkCompleted?.call();
    _popWhenReady();
  }

  /// Postavlja `_readyToPop` pa poziva `maybePop()` tek NAKON što se frame
  /// sa novim `canPop: true` stvarno izgradi (`addPostFrameCallback`).
  ///
  /// Bez ovoga: `setState` samo ZAKAZUJE rebuild (ne dešava se sinhrono), pa
  /// bi `maybePop()` pozvan odmah nakon njega i dalje vidio stari
  /// `canPop: false` na PopScope-u -> pop se blokira -> `onPopInvokedWithResult`
  /// ponovo poziva `_handlePopAttempt()` -> ponovo blokiran pop -> beskonačna
  /// petlja bez ijednog stvarno iscrtanog frame-a (ANR). Ovo se ranije
  /// "sakrivalo" jer je `_handlePopAttempt` čekao pravi Firestore `savePlan`
  /// (stotine ms) prije drugog `maybePop()` poziva, što je davalo engine-u
  /// dovoljno vremena za frame — ali za planId != null (Faza 5, Saved Plans)
  /// `_persistOnClose` odmah vraća, pa je isti race postajao stvaran.
  void _popWhenReady() {
    setState(() => _readyToPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  /// Ekvivalent Share menija iz ResultView.swift — "Share link" (public
  /// link preko ShareLinkService), "Manage link" (postojeći toggle/delete
  /// sheet iz Faze 5), i "Share as text"/"Share as PDF" (novi export-i, ne
  /// zahtijevaju planId jer rade direktno nad ItineraryResponse objektom).
  Future<void> _showShareOptionsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ShareOptionsSheet(
        canShareLink: widget.planId != null,
        onShareLink: () {
          Navigator.of(sheetContext).pop();
          _handleShareLink();
        },
        onManageLink: () {
          Navigator.of(sheetContext).pop();
          _handleManageLink();
        },
        onShareAsText: () {
          Navigator.of(sheetContext).pop();
          _handleShareAsText();
        },
        onShareAsPdf: () {
          Navigator.of(sheetContext).pop();
          _handleShareAsPdf();
        },
      ),
    );
  }

  Future<ShareInfo?> _ensureShareInfo() async {
    final planId = widget.planId;
    if (planId == null) return null;

    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (uid == null) return null;

    return ref.read(shareLinkServiceProvider).createOrGetShareForPlan(uid: uid, planId: planId);
  }

  /// 1a — stvarno slanje public link-a preko native share sheet-a.
  Future<void> _handleShareLink() async {
    setState(() => _isShareActionInProgress = true);
    try {
      final info = await _ensureShareInfo();
      if (info == null) return;
      final url = 'https://vagabundo.app/p/${info.id}';
      await Share.share(url, subject: 'Check out my trip to ${_workingItinerary.city}!');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create share link: $e')),
      );
    } finally {
      if (mounted) setState(() => _isShareActionInProgress = false);
    }
  }

  Future<void> _handleManageLink() async {
    setState(() => _isShareActionInProgress = true);
    try {
      final info = await _ensureShareInfo();
      if (info == null) return;
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ManageShareLinkSheet(initialShare: info),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create share link: $e')),
      );
    } finally {
      if (mounted) setState(() => _isShareActionInProgress = false);
    }
  }

  /// 1b — plain-text export preko native share sheet-a.
  Future<void> _handleShareAsText() async {
    await Share.share(ItineraryTextFormatter.format(_workingItinerary));
  }

  /// 1c — PDF export preko `printing` paketa (interno koristi share_plus).
  Future<void> _handleShareAsPdf() async {
    setState(() => _isShareActionInProgress = true);
    try {
      final bytes = await ItineraryPdfGenerator.generate(_workingItinerary);
      await Printing.sharePdf(bytes: bytes, filename: '${_workingItinerary.city}_itinerary.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not generate PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _isShareActionInProgress = false);
    }
  }

  Future<void> _handlePopAttempt() async {
    await _persistOnClose();
    if (!mounted) return;
    _popWhenReady();
  }

  /// Ekvivalent saveBeforeClosing() iz ResultView.swift — samo za svježe
  /// generisane planove (planId == null) i ulogovanog korisnika. Ako je
  /// planId != null (otvoren iz Saved Plans), plan već postoji u
  /// Firestore-u pa se ovdje NIKAD ne poziva savePlan.
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

/// Action sheet za sve share opcije (dodatak nakon Faze 5) — "Share link"/
/// "Manage link" trebaju sačuvan plan (planId), "Share as text"/"Share as PDF"
/// rade nad bilo kojim ItineraryResponse objektom bez obzira da li je sačuvan.
class _ShareOptionsSheet extends StatelessWidget {
  const _ShareOptionsSheet({
    required this.canShareLink,
    required this.onShareLink,
    required this.onManageLink,
    required this.onShareAsText,
    required this.onShareAsPdf,
  });

  final bool canShareLink;
  final VoidCallback onShareLink;
  final VoidCallback onManageLink;
  final VoidCallback onShareAsText;
  final VoidCallback onShareAsPdf;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
          border: Border.all(color: context.cardStroke),
        ),
        // ListTile crta ink splash-eve na najbližem Material predaku — bez ovoga
        // Flutter baca "background color or ink splashes may be invisible".
        child: Material(
          color: Colors.transparent,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.cardStroke,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Share plan',
                  style: AppTypography.sectionTitle.copyWith(color: context.textPrimary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ListTile(
              leading: Icon(Icons.link, color: canShareLink ? context.accent : context.textSecondary),
              title: Text(
                'Share link',
                style: AppTypography.body.copyWith(
                  color: canShareLink ? context.textPrimary : context.textSecondary,
                ),
              ),
              trailing: canShareLink
                  ? null
                  : Text('Save the plan first', style: AppTypography.fieldLabel.copyWith(color: context.textSecondary)),
              enabled: canShareLink,
              onTap: canShareLink ? onShareLink : null,
            ),
            ListTile(
              leading: Icon(Icons.tune, color: canShareLink ? context.accent : context.textSecondary),
              title: Text(
                'Manage link',
                style: AppTypography.body.copyWith(
                  color: canShareLink ? context.textPrimary : context.textSecondary,
                ),
              ),
              trailing: canShareLink
                  ? null
                  : Text('Save the plan first', style: AppTypography.fieldLabel.copyWith(color: context.textSecondary)),
              enabled: canShareLink,
              onTap: canShareLink ? onManageLink : null,
            ),
            ListTile(
              leading: Icon(Icons.text_snippet_outlined, color: context.accent),
              title: Text('Share as text', style: AppTypography.body.copyWith(color: context.textPrimary)),
              onTap: onShareAsText,
            ),
            ListTile(
              leading: Icon(Icons.picture_as_pdf_outlined, color: context.accent),
              title: Text('Share as PDF', style: AppTypography.body.copyWith(color: context.textPrimary)),
              onTap: onShareAsPdf,
            ),
          ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../models/itinerary.dart';
import '../../providers/ai_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/location_selection_provider.dart';
import '../../providers/plan_config_provider.dart';
import '../../widgets/plan/app_hero_section.dart';
import '../../widgets/plan/country_city_picker.dart';
import '../../widgets/plan/interest_chips_grid.dart';
import '../../widgets/plan/plan_options_view.dart';
import '../../widgets/plan/trip_pace_selector.dart';
import '../../widgets/primary_button.dart';

/// Port MainView.swift — ekran gdje korisnik bira državu/grad, podešava
/// opcije putovanja, bira interese, i klikne "Generiši plan".
///
/// IZRIČITO VAN OBIMA za Fazu 3 (vidi TODO komentare na mjestima gdje bi
/// išli): purchase/credit gating, analytics/crashlytics, pravi ResultView,
/// SettingsView/TopBarView/offline banner, road trip MapKit-quality planning.
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  void _loadInitialData() {
    ref.read(locationSelectionProvider.notifier).loadCountriesIfNeeded();
    final lang = Localizations.localeOf(context).languageCode;
    ref.read(planConfigProvider.notifier).loadInterestsIfNeeded(lang: lang);
  }

  void _onScroll() {
    setState(() => _scrollOffset = _scrollController.offset);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationSelectionProvider);
    final config = ref.watch(planConfigProvider);
    final languageCode = Localizations.localeOf(context).languageCode;

    final inputsReady =
        location.selectedCountry != null && location.selectedCity != null && config.days >= 1;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: AppHeroSection(
                  scrollOffset: _scrollOffset,
                  title: location.selectedCity?.displayName ?? 'Plan your trip',
                ),
              ),
              SliverPadding(
                // AppTabShell (Faza 1) renderuje floating tab bar preko
                // Scaffold(extendBody: true) — content mora imati dovoljno
                // donjeg razmaka da zadnja stavka (Generate dugme) može
                // potpuno da se skroluje iznad njega.
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  MediaQuery.of(context).padding.bottom + 96,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const CountryCityPicker(),
                    const SizedBox(height: AppSpacing.lg),
                    const PlanOptionsView(),
                    const SizedBox(height: AppSpacing.lg),
                    const TripPaceSelector(),
                    const SizedBox(height: AppSpacing.lg),
                    InterestChipsGrid(languageCode: languageCode),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: 'Generate plan',
                      isLoading: _isGenerating,
                      onPressed: inputsReady && !_isGenerating
                          ? () => _handleGenerateTapped(languageCode)
                          : null,
                    ),
                  ]),
                ),
              ),
            ],
          ),
          if (_isGenerating) const _GeneratingOverlay(),
        ],
      ),
    );
  }

  Future<void> _handleGenerateTapped(String languageCode) async {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      // TODO Faza 8: puni AuthGateView sa custom porukama (email verifikacija,
      // itd.) — za sada samo osnovna auth provjera pa navigacija na /profile,
      // koji već prikazuje SignInSignUpScreen kad korisnik nije ulogovan.
      if (mounted) context.go('/profile');
      return;
    }

    final location = ref.read(locationSelectionProvider);
    final config = ref.read(planConfigProvider);
    final country = location.selectedCountry;
    final city = location.selectedCity;
    if (country == null || city == null) return;

    String? originName;
    double? originLat;
    double? originLon;
    if (config.byCar) {
      if (config.useCurrentLocation) {
        final coordinate = ref.read(deviceLocationManagerProvider).currentCoordinate;
        originLat = coordinate?.latitude;
        originLon = coordinate?.longitude;
      } else if (config.originQuery.trim().isNotEmpty) {
        originName = config.originQuery.trim();
      }
    }

    final request = ItineraryRequest(
      country: country.name,
      city: city.name,
      languageCode: languageCode,
      model: kDefaultGeneratorModel,
      days: config.days,
      cityLat: city.lat,
      cityLon: city.lon,
      tripPace: config.tripPace,
      interests: ref.read(planConfigProvider.notifier).selectedLabels(languageCode),
      byCar: config.byCar,
      originName: originName,
      originLat: originLat,
      originLon: originLon,
    );

    // TODO Faza 8: purchase gating (PurchaseManager.canGeneratePlan / kupovina
    // kredita) — za sada, svaki ulogovan korisnik može generisati bez provjere.
    // TODO Faza 8/9: analytics/crashlytics pozivi (potpuno preskočeno ovdje).

    setState(() => _isGenerating = true);

    try {
      final generator = ref.read(itineraryGeneratorProvider);
      final result = await generator.generate(request);
      if (!mounted) return;
      setState(() => _isGenerating = false);
      _showDebugResultSheet(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generation failed: $e')),
      );
    }
  }

  /// TODO Faza 4: zamijeni sa pravim ResultView — za sada samo prikazuje
  /// sirov JSON rezultata u scrollable bottom sheet-u radi debug-a.
  void _showDebugResultSheet(ItineraryResponse result) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: context.cardBackground,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SingleChildScrollView(
              controller: scrollController,
              child: SelectableText(
                const JsonEncoder.withIndent('  ').convert(result.toJson()),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Port loadingOverlay iz MainView.swift — koristi obični CircularProgressIndicator
/// umjesto AnimatedVagabundoLogoSVG, i rotira iste "gen_step_*" ključeve svakih
/// 8s (identičan interval Swift originalu), zaustavljajući se na posljednjem.
class _GeneratingOverlay extends StatefulWidget {
  const _GeneratingOverlay();

  @override
  State<_GeneratingOverlay> createState() => _GeneratingOverlayState();
}

class _GeneratingOverlayState extends State<_GeneratingOverlay> {
  static const List<String> _steps = [
    'gen_step_analyzing',
    'gen_step_coordinates',
    'gen_step_roadtrip',
    'gen_step_interests',
    'gen_step_planning',
    'gen_step_routes',
    'gen_step_finalizing',
  ];

  int _stepIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_stepIndex < _steps.length - 1) {
        setState(() => _stepIndex++);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.20),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: context.cardBackground,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: context.accent),
                const SizedBox(height: AppSpacing.md),
                Text(
                  // TODO: zamijeni sa lokalizovanim stringom za ključ _steps[_stepIndex]
                  // kad se l10n sistem oživi (vidi TripPace.localizationKey pattern).
                  _steps[_stepIndex],
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

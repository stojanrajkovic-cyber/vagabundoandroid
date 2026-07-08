import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';

/// Flutter splash — preuzima izgled nativnog Android splash-a (ista pozadina,
/// isti logo, isto mjesto) da tranzicija bude bešavna, pa animira: logo
/// fade+scale in, ZATIM (sekvencijalno) "Vagabundo" tekst ispod pojavljuje
/// slovo-po-slovo, pa navigira na pravi app.
///
/// Firebase je GARANTOVANO spreman prije nego se ovaj ekran uopšte prikaže
/// (main.dart await-uje Firebase.initializeApp() prije runApp()) — ne treba
/// mu nikakvo dodatno čekanje, samo čista animacija.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _logoDuration = Duration(milliseconds: 600);
  static const _letterDelay = Duration(milliseconds: 90);
  static const _holdAfter = Duration(milliseconds: 400);
  static const _word = 'Vagabundo';

  late final AnimationController _logoController = AnimationController(
    vsync: this,
    duration: _logoDuration,
  );
  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _logoController,
    curve: Curves.easeOutBack,
  );
  late final Animation<double> _logoOpacity = CurvedAnimation(
    parent: _logoController,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
  );

  int _visibleLetters = 0;

  @override
  void initState() {
    super.initState();
    _runSequence();
  }

  Future<void> _runSequence() async {
    // 1) Logo prvo.
    await _logoController.forward();
    if (!mounted) return;

    // 2) TEK ONDA tekst, slovo po slovo (sekvencijalno, ne istovremeno).
    for (var i = 1; i <= _word.length; i++) {
      if (!mounted) return;
      setState(() => _visibleLetters = i);
      await Future.delayed(_letterDelay);
    }

    await Future.delayed(_holdAfter);
    if (!mounted) return;

    context.go('/plan');
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.alice, // ISTA boja kao native splash — bez treptaja
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _logoOpacity,
              child: ScaleTransition(
                scale: _logoScale,
                child: Image.asset(
                  'assets/images/logo.png', // Flutter density-variant sistem
                  // bira 2.0x/3.0x automatski po gustini ekrana uređaja.
                  width: 96,
                  height: 96,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _word.substring(0, _visibleLetters),
              style: AppTypography.heroTitle.copyWith(
                color: AppColors.cerulean,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

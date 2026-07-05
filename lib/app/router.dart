import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/itinerary.dart';
import '../providers/auth_provider.dart';
import '../screens/main/main_screen.dart';
import '../screens/explore/explore_screen.dart';
import '../screens/result/result_screen.dart';
import '../screens/saved/saved_plans_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/auth/sign_in_sign_up_screen.dart';
import '../widgets/app_tab_shell.dart';

/// Ekvivalent NavigationStack + TabView switch iz AppTabShell.swift.
///
/// StatefulShellRoute.indexedStack čuva navigacijsko stanje svakog taba
/// zasebno (isto ponašanje kao odvojeni NavigationStack po tabu na iOS-u).
final routerProvider = Provider<GoRouter>((ref) {
  // watch, ne read: kad se auth stanje promijeni, GoRouter re-evaluira
  // rutu za /profile (isto kao `if session.isAuthenticated` na iOS-u).
  ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/plan',
    routes: [
      // Van StatefulShellRoute tab strukture (isto kao Swift `.sheet`/full-screen
      // push za ResultView — ne treba svoj tab, samo se push-uje preko postojećih).
      GoRoute(
        path: '/result',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is ResultScreenArgs) {
            return ResultScreen(
              itinerary: extra.itinerary,
              planId: extra.planId,
              isReadOnly: extra.isReadOnly,
              showMarkCompleted: extra.showMarkCompleted,
              onMarkCompleted: extra.onMarkCompleted,
              showsCloseButton: extra.showsCloseButton,
            );
          }
          // Svježe generisan plan (Faza 3/4 flow) — main_screen.dart i dalje
          // prosljeđuje samo ItineraryResponse kroz `extra`.
          return ResultScreen(itinerary: extra as ItineraryResponse, planId: null);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppTabShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/plan',
                builder: (context, state) => const MainScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                builder: (context, state) => const ExploreScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/saved',
                builder: (context, state) => const SavedPlansScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) {
                  final container = ProviderScope.containerOf(context);
                  final isAuthenticated =
                      container.read(isAuthenticatedProvider);
                  return isAuthenticated
                      ? const ProfileScreen()
                      : const SignInSignUpScreen();
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

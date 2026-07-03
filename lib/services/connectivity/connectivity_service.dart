import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ekvivalent NetworkMonitor sa iOS-a — true = offline (nema mrežne konekcije).
///
/// Emituje trenutni status odmah nakon subscribe-a (preko `checkConnectivity()`)
/// pa zatim prati promjene preko `onConnectivityChanged` — bez ovoga bi UI
/// ostao na default (online) pretpostavci dok se ne desi prva promjena mreže.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  yield _isOffline(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(_isOffline);
});

bool _isOffline(List<ConnectivityResult> results) {
  if (results.isEmpty) return true;
  return results.every((r) => r == ConnectivityResult.none);
}

/// Sinhroni pristup bez AsyncValue boilerplate-a, za widgete kojima samo
/// treba trenutna vrijednost (default false/online dok prvi event ne stigne).
final isOfflineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).asData?.value ?? false;
});

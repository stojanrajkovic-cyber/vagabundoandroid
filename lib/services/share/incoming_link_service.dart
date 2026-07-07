import 'dart:async';

import 'package:app_links/app_links.dart';

/// Android ekvivalent handleIncomingURL(_:) iz VagabundoApp.swift (Universal
/// Links) — hvata https://vagabundo.app/p/{token} linkove i validira token
/// (minimum 16 karaktera nakon trim-a). FAZA A: samo cijev, token se JOŠ NE
/// rezolvira/prikazuje (Faza B).
class IncomingLinkService {
  IncomingLinkService(this._onToken);

  final void Function(String token) _onToken;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  Uri? _lastHandledUri;

  Future<void> start() async {
    // Cold start — app otvorena DIREKTNO preko linka
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) _handle(initialUri);

    // Warm — app već otvorena u pozadini, korisnik klikne link.
    // NAPOMENA: uriLinkStream zna ponovo emitovati ISTI initial link koji je
    // getInitialLink() već obradio (potvrđeno na emulatoru — cold start
    // ispisuje token dvaput bez ovog guard-a) — _lastHandledUri sprečava
    // duplo procesiranje istog linka.
    _sub = _appLinks.uriLinkStream.listen(_handle);
  }

  void dispose() => _sub?.cancel();

  void _handle(Uri uri) {
    if (uri == _lastHandledUri) return;

    final segments = uri.pathSegments; // npr. ['p', 'abc123...']
    if (segments.length != 2 || segments[0] != 'p') return;

    final token = segments[1].trim();
    if (token.length < 16) return;

    _lastHandledUri = uri;
    // ignore: avoid_print
    print('🔗 Incoming share token: $token');
    _onToken(token);
  }
}

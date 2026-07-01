import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ai/itinerary_generator.dart';

/// AIProxy kredencijali — čitaju se iz --dart-define ako su prosljeđeni,
/// inače padaju na stvarne vrijednosti iz iOS Secrets.xcconfig (AIProxy
/// "partial key" je po dizajnu bezbjedan za bundlovanje u klijentu, isto
/// kao što je već bio bundlovan u iOS Info.plist preko build-config
/// supstitucije — server drži drugu polovinu ključa).
///
/// Override primjer:
///   flutter run \
///     --dart-define=AIPROXY_SERVICE_URL=https://api.aiproxy.com/... \
///     --dart-define=AIPROXY_PARTIAL_KEY=v2|...
const String _aiProxyServiceUrlEnv = String.fromEnvironment('AIPROXY_SERVICE_URL');
const String _aiProxyPartialKeyEnv = String.fromEnvironment('AIPROXY_PARTIAL_KEY');

const String _aiProxyServiceUrlDefault = 'https://api.aiproxy.com/8c264efa/7b8576a3';
const String _aiProxyPartialKeyDefault = 'v2|2b0f2a07|YIX4RxEpyZDCyMSD';

final itineraryGeneratorProvider = Provider<ItineraryGenerator>((ref) {
  final serviceUrl =
      _aiProxyServiceUrlEnv.isNotEmpty ? _aiProxyServiceUrlEnv : _aiProxyServiceUrlDefault;
  final partialKey =
      _aiProxyPartialKeyEnv.isNotEmpty ? _aiProxyPartialKeyEnv : _aiProxyPartialKeyDefault;

  return AIProxyItineraryGenerator(
    aiProxyServiceUrl: Uri.parse(serviceUrl),
    partialKey: partialKey,
  );
});

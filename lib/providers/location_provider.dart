import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/location/device_location_manager.dart';

/// Ekvivalent @EnvironmentObject var deviceLocation: DeviceLocationManager.
///
/// ChangeNotifierProvider (ne StreamProvider/StateNotifierProvider) jer
/// DeviceLocationManager sam upravlja svojim stateful ponašanjem (GPS stream,
/// timeout, completer) — najbliži je Flutter ekvivalent Swift-ovom
/// ObservableObject-u sa @Published poljima.
final deviceLocationManagerProvider = ChangeNotifierProvider<DeviceLocationManager>((ref) {
  final manager = DeviceLocationManager();
  ref.onDispose(manager.dispose);
  return manager;
});

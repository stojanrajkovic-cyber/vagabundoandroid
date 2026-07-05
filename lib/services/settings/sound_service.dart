import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_settings_store.dart';

/// Ekvivalent SoundManager.swift — puštanje UI zvučnih efekata,
/// respektuje appSettingsProvider (soundEnabled/soundVolume).
class SoundService {
  SoundService(this.ref);
  final Ref ref;

  final AudioPlayer _player = AudioPlayer();

  Future<void> playSuccess() => play('success');

  Future<void> play(String name, {String ext = 'wav'}) async {
    final settings = ref.read(appSettingsProvider);
    if (!settings.soundEnabled) return;
    try {
      await _player.setVolume(settings.soundVolume);
      await _player.play(AssetSource('sounds/$name.$ext'));
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ SoundService: missing or failed sound "$name.$ext": $e');
    }
  }
}

final soundServiceProvider = Provider<SoundService>((ref) => SoundService(ref));

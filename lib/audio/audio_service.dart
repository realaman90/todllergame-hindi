import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Three-lane audio service.
///
/// - Voice lane: single player for word clips and puzzle prompts.
///   Starting a new voice clip stops the previous one.
/// - Ambient lane: looping music/ambient. Ducks to 30% while the voice
///   lane is active and restores afterward.
/// - SFX lane: one-shot sound effects.
class AudioService extends ChangeNotifier {
  static const _duckedVolume = 0.30;
  static const _ambientVolume = 1.0;

  AudioPlayer? _voicePlayer;
  AudioPlayer? _ambientPlayer;
  AudioPlayer? _sfxPlayer;
  StreamSubscription<PlayerState>? _voiceSubscription;
  int _voiceGeneration = 0;

  bool get isPlaying => _voicePlayer?.playing ?? false;

  AudioPlayer get _ensureVoice => _voicePlayer ??= AudioPlayer();
  AudioPlayer get _ensureAmbient => _ambientPlayer ??= AudioPlayer();
  AudioPlayer get _ensureSfx => _sfxPlayer ??= AudioPlayer();

  /// Play a scene object's word clip or a puzzle prompt.
  ///
  /// [sceneId] and [slug] form the filename (`<scene>_<slug>.mp3`).
  /// Set [slow] to true to load the `_slow.mp3` repeat take.
  Future<void> playWord(
    String sceneId,
    String slug, {
    required String language,
    bool slow = false,
  }) async {
    final suffix = slow ? '_slow' : '';
    final path = 'assets/audio/$language/${sceneId}_$slug$suffix.mp3';
    await _playVoice(path);
  }

  Future<void> _playVoice(String path) async {
    final player = _ensureVoice;
    final generation = ++_voiceGeneration;

    try {
      await player.stop();
      await player.setAsset(path);
      await player.setVolume(1.0);
      await _duckAmbient();
      await player.play();

      await _voiceSubscription?.cancel();
      _voiceSubscription = player.playerStateStream.listen((state) {
        if (!state.playing &&
            state.processingState == ProcessingState.completed &&
            _voiceGeneration == generation) {
          _restoreAmbient();
        }
      });
    } on Exception catch (e, stack) {
      if (kDebugMode) {
        debugPrint('AudioService failed to play $path: $e\n$stack');
      }
    }
  }

  /// Play a looping ambient track (theme on Home, scene ambient in scene).
  Future<void> playAmbient(String path, {bool loop = true}) async {
    final player = _ensureAmbient;
    try {
      await player.stop();
      await player.setAsset(path);
      await player.setLoopMode(loop ? LoopMode.all : LoopMode.off);
      await player.setVolume(_ambientVolume);
      await player.play();
    } on Exception catch (e, stack) {
      if (kDebugMode) {
        debugPrint('AudioService failed to play ambient $path: $e\n$stack');
      }
    }
  }

  Future<void> stopAmbient() async => await _ambientPlayer?.stop();

  Future<void> _duckAmbient() async {
    await _ambientPlayer?.setVolume(_duckedVolume);
  }

  Future<void> _restoreAmbient() async {
    await _ambientPlayer?.setVolume(_ambientVolume);
  }

  /// Play a one-shot sound effect by filename (no extension).
  Future<void> playSfx(String name) async {
    final player = _ensureSfx;
    final path = 'assets/audio/sfx/$name.mp3';
    try {
      await player.stop();
      await player.setAsset(path);
      await player.setVolume(1.0);
      await player.play();
    } on Exception catch (e, stack) {
      if (kDebugMode) {
        debugPrint('AudioService failed to play sfx $path: $e\n$stack');
      }
    }
  }

  /// Stop the voice lane and restore ambient volume.
  Future<void> stop() async {
    _voiceGeneration = 0;
    await _restoreAmbient();
    await _voicePlayer?.stop();
  }

  @override
  void dispose() {
    _voiceSubscription?.cancel();
    _voicePlayer?.dispose();
    _ambientPlayer?.dispose();
    _sfxPlayer?.dispose();
    super.dispose();
  }
}

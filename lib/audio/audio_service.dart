import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Three-lane audio service.
///
/// - Voice lane: single player for word clips, puzzle prompts, and Mithu
///   host lines. Starting a new voice operation stops the previous one.
///   Multiple voice clips can be queued as one sequence (e.g. a puzzle
///   prompt word followed by "kahaan hai?").
/// - Ambient lane: looping music/ambient. Ducks to 30% while the voice
///   lane is active and restores afterward.
/// - SFX lane: one-shot sound effects.
class AudioService extends ChangeNotifier {
  // Founder feedback: bg music was overpowering the voice. Quieter by
  // default; full parent-facing sliders arrive with the settings screen.
  static const _duckedVolume = 0.12;
  static const _ambientVolume = 0.45;

  AudioPlayer? _voicePlayer;
  AudioPlayer? _ambientPlayer;
  AudioPlayer? _sfxPlayer;
  StreamSubscription<PlayerState>? _voiceSubscription;
  int _voiceGeneration = 0;
  final List<String> _voiceQueue = [];
  Completer<void>? _voiceCompleter;
  String? _pendingSfx;
  String? _currentVoicePath;
  bool _wasPlaying = false;
  bool _clipCompletionHandled = true;

  // Per-player operation queues: just_audio throws 'Loading interrupted'
  // through internal futures when a new load supersedes one in flight —
  // uncatchable at call sites and fatal to the test harness. Serializing
  // each player's platform ops means an in-flight load always finishes
  // (or fails cleanly) before the next begins.
  Future<void> _voiceOps = Future.value();
  Future<void> _sfxOps = Future.value();
  Future<void> _ambientOps = Future.value();

  Future<void> _onVoiceOps(Future<void> Function() op) {
    final run = _voiceOps.then((_) => op());
    _voiceOps = run.then((_) {}, onError: (_) {});
    return run;
  }

  Future<void> _onSfxOps(Future<void> Function() op) {
    final run = _sfxOps.then((_) => op());
    _sfxOps = run.then((_) {}, onError: (_) {});
    return run;
  }

  Future<void> _onAmbientOps(Future<void> Function() op) {
    final run = _ambientOps.then((_) => op());
    _ambientOps = run.then((_) {}, onError: (_) {});
    return run;
  }

  bool get isPlaying => _voicePlayer?.playing ?? false;
  String? get currentVoicePath => _currentVoicePath;

  AudioPlayer get _ensureVoice => _voicePlayer ??= AudioPlayer();
  AudioPlayer get _ensureAmbient => _ambientPlayer ??= AudioPlayer();
  AudioPlayer get _ensureSfx => _sfxPlayer ??= AudioPlayer();

  void _notifyIfPlayingChanged() {
    final now = isPlaying;
    if (now != _wasPlaying) {
      _wasPlaying = now;
      notifyListeners();
    }
  }

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

  /// Play a Mithu host line by base name (e.g. `mithu_greeting`).
  Future<void> playHost(String name) async {
    final path = 'assets/audio/hi/$name.mp3';
    if (kDebugMode) debugPrint('AudioService.playHost: $path');
    await _playVoice(path);
  }

  /// Play a sequence of Mithu host lines back-to-back on the voice lane.
  Future<void> playHostSequence(List<String> names) async {
    final paths = names.map((name) => 'assets/audio/hi/$name.mp3').toList();
    if (kDebugMode) debugPrint('AudioService.playHostSequence: $paths');
    await _playVoiceSequence(paths);
  }

  /// Play a find-it prompt: the target word followed by "___ kahaan hai?".
  Future<void> playPromptSequence(
    String sceneId,
    String slug, {
    required String language,
  }) async {
    final wordPath = 'assets/audio/$language/${sceneId}_$slug.mp3';
    final hostPath = 'assets/audio/$language/mithu_kahaan_hai.mp3';
    await _playVoiceSequence([wordPath, hostPath]);
  }

  /// Warm informative correction: "यह [word] नहीं है!" — spoken kindly,
  /// never as a buzzer. Teaches negation while redirecting.
  Future<void> playWrongMatch(
    String sceneId,
    String slug, {
    required String language,
  }) async {
    await _playVoiceSequence([
      'assets/audio/hi/mithu_yeh.mp3',
      'assets/audio/$language/${sceneId}_$slug.mp3',
      'assets/audio/hi/mithu_nahi_hai.mp3',
    ]);
  }

  /// Play a random praise line, then the celebration SFX.
  Future<void> playPraise() async {
    const praises = ['shabash', 'wah', 'badhiya'];
    final pick = praises[Random().nextInt(praises.length)];
    await _playVoice('assets/audio/hi/mithu_$pick.mp3', thenSfx: 'celebration');
  }

  /// Play the sticker-earned host line, then the sticker_earned SFX.
  Future<void> playStickerEarned() async {
    await _playVoice('assets/audio/hi/mithu_sticker.mp3', thenSfx: 'sticker_earned');
  }

  Future<void> _playVoice(String path, {String? thenSfx}) async {
    await _startVoiceOperation([path], thenSfx: thenSfx);
  }

  Future<void> _playVoiceSequence(List<String> paths, {String? thenSfx}) async {
    await _startVoiceOperation(paths, thenSfx: thenSfx);
  }

  Future<void> _startVoiceOperation(List<String> paths, {String? thenSfx}) async {
    if (kDebugMode) {
      debugPrint(
        'AudioService._startVoiceOperation: ${paths.length} clip(s), first=${paths.firstOrNull}',
      );
    }

    // Finish any awaiter on the previous voice operation.
    if (_voiceCompleter != null && !_voiceCompleter!.isCompleted) {
      _voiceCompleter!.complete();
    }
    _voiceCompleter = null;
    _pendingSfx = null;

    if (paths.isEmpty) {
      _currentVoicePath = null;
      _notifyIfPlayingChanged();
      return;
    }

    final completer = Completer<void>();
    _voiceCompleter = completer;
    _pendingSfx = thenSfx;
    _currentVoicePath = paths.first;
    final generation = ++_voiceGeneration;
    _voiceQueue.clear();
    _voiceQueue.addAll(paths.sublist(1));

    final player = _ensureVoice;
    await _voiceSubscription?.cancel();
    _clipCompletionHandled = true; // nothing playing yet for this op
    _voiceSubscription = player.playerStateStream.listen((state) {
      _notifyIfPlayingChanged();
      if (_voiceGeneration != generation) return;
      // just_audio keeps `playing == true` at ProcessingState.completed
      // (it only flips on stop/pause), so completion must key off the
      // processing state alone. _clipCompletionHandled dedupes repeated
      // emissions of the completed state for the same clip.
      if (state.processingState == ProcessingState.completed &&
          !_clipCompletionHandled) {
        _clipCompletionHandled = true;
        if (_voiceQueue.isNotEmpty) {
          final next = _voiceQueue.removeAt(0);
          _currentVoicePath = next;
          // Fire-and-forget from a stream handler: a load superseded by a
          // rapid new tap throws through just_audio's internal future —
          // swallow it here or it escapes as an uncaught zone error.
          _playClip(next).catchError((Object e) {
            if (kDebugMode) debugPrint('AudioService queued clip aborted: $e');
          });
        } else {
          _currentVoicePath = null;
          _restoreAmbient();
          _playPendingSfx();
          if (_voiceCompleter != null && !_voiceCompleter!.isCompleted) {
            _voiceCompleter!.complete();
            _voiceCompleter = null;
          }
        }
      }
    });

    try {
      await _playClip(paths.first);
      await completer.future;
    } on Exception catch (e, stack) {
      if (kDebugMode) {
        debugPrint('AudioService failed to play voice sequence: $e\n$stack');
      }
      _currentVoicePath = null;
      _restoreAmbient();
      if (_voiceCompleter != null && !_voiceCompleter!.isCompleted) {
        _voiceCompleter!.complete();
        _voiceCompleter = null;
      }
    }
  }

  Future<void> _playClip(String path) async {
    if (kDebugMode) debugPrint('AudioService._playClip: $path');
    _currentVoicePath = path;
    await _onVoiceOps(() async {
      final player = _ensureVoice;
      await player.stop();
      await player.setAsset(path);
      await player.setVolume(1.0);
      await _duckAmbient();
      // Arm completion handling for THIS clip just before it starts.
      _clipCompletionHandled = false;
      await player.play();
    });
    _notifyIfPlayingChanged();
  }

  /// Play a looping ambient track (theme on Home, scene ambient in scene).
  Future<void> playAmbient(String path, {bool loop = true}) async {
    final player = _ensureAmbient;
    try {
      await _onAmbientOps(() async {
        await player.stop();
        await player.setAsset(path);
        await player.setLoopMode(loop ? LoopMode.all : LoopMode.off);
        await player.setVolume(_ambientVolume);
        await player.play();
      });
    } on Exception catch (e, stack) {
      if (kDebugMode) {
        debugPrint('AudioService failed to play ambient $path: $e\n$stack');
      }
    }
  }

  Future<void> stopAmbient() async => await _ambientPlayer?.stop();

  Future<void> _duckAmbient() async {
    try {
      await _ambientPlayer?.setVolume(_duckedVolume);
    } catch (_) {
      // Player mid-teardown (app exit / test harness) — ducking a dying
      // player is a no-op, not an error.
    }
  }

  Future<void> _restoreAmbient() async {
    try {
      await _ambientPlayer?.setVolume(_ambientVolume);
    } catch (_) {
      // Player mid-teardown — restoring volume is best-effort only.
    }
  }

  void _playPendingSfx() {
    final sfx = _pendingSfx;
    _pendingSfx = null;
    if (sfx != null) playSfx(sfx);
  }

  /// Play a one-shot sound effect by filename (no extension).
  Future<void> playSfx(String name) async {
    final player = _ensureSfx;
    final path = 'assets/audio/sfx/$name.mp3';
    try {
      await _onSfxOps(() async {
        await player.stop();
        await player.setAsset(path);
        await player.setVolume(1.0);
        await player.play();
      });
    } on Exception catch (e, stack) {
      if (kDebugMode) {
        debugPrint('AudioService failed to play sfx $path: $e\n$stack');
      }
    }
  }

  /// Stop the voice lane and restore ambient volume.
  Future<void> stop() async {
    _voiceGeneration = 0;
    _voiceQueue.clear();
    if (_voiceCompleter != null && !_voiceCompleter!.isCompleted) {
      _voiceCompleter!.complete();
    }
    _voiceCompleter = null;
    _pendingSfx = null;
    _currentVoicePath = null;
    await _restoreAmbient();
    await _voicePlayer?.stop();
    _notifyIfPlayingChanged();
  }

  @override
  void dispose() {
    _voiceSubscription?.cancel();
    // Deliberately NOT disposing the players: this service lives for the
    // whole process, and just_audio's dispose kicks off an async platform
    // teardown that races engine shutdown ("Cannot complete a future with
    // itself"), crashing test teardown and adding nothing in production —
    // the OS reclaims everything with the process anyway.
    super.dispose();
  }
}

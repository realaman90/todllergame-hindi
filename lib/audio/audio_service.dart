import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Three-lane audio service on the SoLoud engine (ADR-011).
///
/// - Voice lane: word clips, puzzle prompts, and Mithu host lines. A new
///   voice operation supersedes the previous one. Multiple clips can be
///   queued as one sequence (e.g. a word followed by "kahaan hai?").
/// - Ambient lane: looping music. Ducks while the voice lane is active.
/// - SFX lane: one-shot effects, preloaded into memory at init so the
///   first feedback lands inside the 100ms window (feel rule F2), with
///   optional per-play rate for pitch variation (F12).
class AudioService extends ChangeNotifier {
  // Founder feedback: bg music was overpowering the voice. Quieter by
  // default; full parent-facing sliders arrive with the settings screen.
  static const _duckedVolume = 0.12;
  static const _ambientVolume = 0.45;

  static const _preloadedSfx = [
    'tap_pop',
    'note_tap',
    'boop_curious',
    'ding_sticker',
    'celebration',
    'sticker_earned',
  ];

  // F12: successive taps climb a pentatonic ladder (major pentatonic
  // degrees in semitones) — there is no wrong note, so rapid tapping
  // turns into melody instead of a stuck sample.
  static const _pentatonic = [0, 2, 4, 7, 9, 12];

  final SoLoud _engine = SoLoud.instance;
  Future<void>? _initFuture;
  bool _engineReady = false;

  final Map<String, AudioSource> _cache = {};

  int _voiceGeneration = 0;
  SoundHandle? _voiceHandle;
  String? _currentVoicePath;
  bool _voiceActive = false;
  String? _pendingSfx;

  SoundHandle? _ambientHandle;
  double _ambientCurrent = 0.0;
  int _rampGeneration = 0;

  int _ladderStep = 0;

  bool get isPlaying => _voiceActive;
  String? get currentVoicePath => _currentVoicePath;

  /// Boot the engine and preload the latency-critical SFX. Safe to call
  /// more than once; every public method awaits this internally.
  Future<void> init() => _initFuture ??= _doInit();

  Future<void> _doInit() async {
    try {
      await _engine.init();
      _engineReady = true;
      for (final name in _preloadedSfx) {
        await _load('assets/audio/sfx/$name.mp3');
      }
    } catch (e, stack) {
      // No audio is a degraded session, not a broken one — the app must
      // keep working silently (e.g. CI machines without an audio device).
      if (kDebugMode) debugPrint('AudioService init failed: $e\n$stack');
    }
  }

  Future<AudioSource?> _load(
    String path, {
    LoadMode mode = LoadMode.memory,
  }) async {
    if (!_engineReady) return null;
    final cached = _cache[path];
    if (cached != null) return cached;
    try {
      final source = await _engine.loadAsset(path, mode: mode);
      _cache[path] = source;
      return source;
    } catch (e) {
      if (kDebugMode) debugPrint('AudioService failed to load $path: $e');
      return null;
    }
  }

  void _setVoiceActive(bool active) {
    if (_voiceActive != active) {
      _voiceActive = active;
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
    await _startVoiceOperation([path]);
  }

  /// Play a Mithu host line by base name (e.g. `mithu_greeting`).
  Future<void> playHost(String name) async {
    final path = 'assets/audio/hi/$name.mp3';
    if (kDebugMode) debugPrint('AudioService.playHost: $path');
    await _startVoiceOperation([path]);
  }

  /// Play a sequence of Mithu host lines back-to-back on the voice lane.
  Future<void> playHostSequence(List<String> names) async {
    final paths = names.map((name) => 'assets/audio/hi/$name.mp3').toList();
    if (kDebugMode) debugPrint('AudioService.playHostSequence: $paths');
    await _startVoiceOperation(paths);
  }

  /// Play a find-it prompt: the target word followed by "___ kahaan hai?".
  Future<void> playPromptSequence(
    String sceneId,
    String slug, {
    required String language,
  }) async {
    await _startVoiceOperation([
      'assets/audio/$language/${sceneId}_$slug.mp3',
      'assets/audio/$language/mithu_kahaan_hai.mp3',
    ]);
  }

  /// Warm informative correction: "यह [word] नहीं है!" — spoken kindly,
  /// never as a buzzer. Teaches negation while redirecting.
  Future<void> playWrongMatch(
    String sceneId,
    String slug, {
    required String language,
  }) async {
    await _startVoiceOperation([
      'assets/audio/hi/mithu_yeh.mp3',
      'assets/audio/$language/${sceneId}_$slug.mp3',
      'assets/audio/hi/mithu_nahi_hai.mp3',
    ]);
  }

  /// Play a random praise line, then a random win stinger.
  ///
  /// Pass [sceneId]/[slug]/[language] to restate the word the child just
  /// learned right inside the celebration ("शाबाश! ... आम!") — juice
  /// amplifies the curriculum, not generic success (feel rule F14).
  Future<void> playPraise({
    String? sceneId,
    String? slug,
    String? language,
  }) async {
    const praises = ['shabash', 'wah', 'badhiya'];
    const stingers = [
      'celebration',
      'stinger_win_1',
      'stinger_win_2',
      'stinger_win_3',
    ];
    final pick = praises[Random().nextInt(praises.length)];
    await _startVoiceOperation(
      [
        'assets/audio/hi/mithu_$pick.mp3',
        if (sceneId != null && slug != null && language != null)
          'assets/audio/$language/${sceneId}_$slug.mp3',
      ],
      thenSfx: stingers[Random().nextInt(stingers.length)],
    );
  }

  /// Play the sticker-earned host line, then the sticker_earned SFX.
  Future<void> playStickerEarned() async {
    await _startVoiceOperation(
      ['assets/audio/hi/mithu_sticker.mp3'],
      thenSfx: 'sticker_earned',
    );
  }

  /// The voice lane is a plain awaited loop: play a clip, sleep its
  /// length, move on. A newer operation bumps the generation; a stale
  /// loop wakes, sees it lost, and exits without touching state. This
  /// replaces just_audio's state-stream juggling wholesale.
  Future<void> _startVoiceOperation(
    List<String> paths, {
    String? thenSfx,
  }) async {
    if (kDebugMode) {
      debugPrint(
        'AudioService._startVoiceOperation: ${paths.length} clip(s), first=${paths.firstOrNull}',
      );
    }
    await init();
    if (!_engineReady) return;

    final generation = ++_voiceGeneration;
    _pendingSfx = thenSfx;

    final previous = _voiceHandle;
    _voiceHandle = null;
    if (previous != null) {
      await _engine.stop(previous);
    }
    if (generation != _voiceGeneration) return;

    if (paths.isEmpty) {
      _currentVoicePath = null;
      _setVoiceActive(false);
      return;
    }

    unawaited(_duckAmbient());
    for (final path in paths) {
      if (generation != _voiceGeneration) return;
      final source = await _load(path);
      if (generation != _voiceGeneration) return;
      if (source == null) continue;
      if (kDebugMode) debugPrint('AudioService._playClip: $path');
      _currentVoicePath = path;
      _setVoiceActive(true);
      try {
        _voiceHandle = _engine.play(source);
        final length = _engine.getLength(source);
        await Future.delayed(length + const Duration(milliseconds: 120));
      } catch (e) {
        if (kDebugMode) debugPrint('AudioService voice clip failed: $e');
      }
    }
    if (generation != _voiceGeneration) return;

    _voiceHandle = null;
    _currentVoicePath = null;
    _setVoiceActive(false);
    unawaited(_restoreAmbient());
    final sfx = _pendingSfx;
    _pendingSfx = null;
    if (sfx != null) unawaited(playSfx(sfx));
  }

  /// Play a looping ambient track (theme on Home, scene ambient in scene).
  Future<void> playAmbient(String path, {bool loop = true}) async {
    await init();
    if (!_engineReady) return;
    try {
      final previous = _ambientHandle;
      _ambientHandle = null;
      if (previous != null) await _engine.stop(previous);
      // Ambient tracks are long — stream from disk instead of RAM.
      final source = await _load(path, mode: LoadMode.disk);
      if (source == null) return;
      _ambientCurrent = 0.0;
      _ambientHandle = _engine.play(source, volume: 0.0, looping: loop);
      // Fade in from silence instead of slamming on.
      await _rampAmbient(
        _voiceActive ? _duckedVolume : _ambientVolume,
        ms: 1200,
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('AudioService failed to play ambient $path: $e\n$stack');
      }
    }
  }

  Future<void> stopAmbient() async {
    await _rampAmbient(0.0, ms: 200);
    final handle = _ambientHandle;
    _ambientHandle = null;
    if (handle != null) {
      try {
        await _engine.stop(handle);
      } catch (_) {
        // Handle already invalid — nothing to stop.
      }
    }
  }

  /// Smoothly ramp the ambient volume — instant volume jumps read as
  /// "basic"; a short ramp makes ducking feel produced.
  Future<void> _rampAmbient(double to, {int ms = 220}) async {
    final handle = _ambientHandle;
    if (handle == null) return;
    final generation = ++_rampGeneration;
    final from = _ambientCurrent;
    const steps = 6;
    for (var i = 1; i <= steps; i++) {
      if (generation != _rampGeneration || _ambientHandle != handle) return;
      _ambientCurrent = from + (to - from) * i / steps;
      try {
        _engine.setVolume(handle, _ambientCurrent);
      } catch (_) {
        return; // handle died mid-ramp — best-effort only
      }
      await Future.delayed(Duration(milliseconds: ms ~/ steps));
    }
  }

  Future<void> _duckAmbient() => _rampAmbient(_duckedVolume);

  Future<void> _restoreAmbient() => _rampAmbient(_ambientVolume, ms: 420);

  /// Play a one-shot sound effect by filename (no extension).
  ///
  /// [rate] is a relative playback speed (1.0 = as recorded); use it for
  /// pitch variation so repeats never sound identical (F12).
  Future<void> playSfx(String name, {double? rate}) async {
    await init();
    if (!_engineReady) return;
    try {
      final source = await _load('assets/audio/sfx/$name.mp3');
      if (source == null) return;
      final handle = _engine.play(source, paused: rate != null);
      if (rate != null) {
        _engine.setRelativePlaySpeed(handle, rate);
        _engine.setPause(handle, false);
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('AudioService failed to play sfx $name: $e\n$stack');
      }
    }
  }

  /// F12 tap sound: each call climbs one step of a pentatonic ladder.
  /// Call [resetTapLadder] when a round/screen starts so the melody
  /// restarts from the root.
  Future<void> playTapNote() {
    final semitones = _pentatonic[_ladderStep % _pentatonic.length];
    _ladderStep++;
    return playSfx('note_tap', rate: pow(2.0, semitones / 12.0).toDouble());
  }

  void resetTapLadder() => _ladderStep = 0;

  /// Stop the voice lane and restore ambient volume.
  Future<void> stop() async {
    _voiceGeneration++;
    _pendingSfx = null;
    _currentVoicePath = null;
    final handle = _voiceHandle;
    _voiceHandle = null;
    if (handle != null && _engineReady) {
      try {
        await _engine.stop(handle);
      } catch (_) {
        // Already finished.
      }
    }
    _setVoiceActive(false);
    await _restoreAmbient();
  }

  @override
  void dispose() {
    // Deliberately NOT deinit-ing the engine: this service lives for the
    // whole process, and the OS reclaims everything with the process.
    super.dispose();
  }
}

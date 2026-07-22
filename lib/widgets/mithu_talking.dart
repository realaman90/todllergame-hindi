import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Mithu as a paper puppet with three states, driven by real frame art
/// (all generated on-model from the ADR-008 canon):
///
/// - **idle**: beak-closed rest frame, gentle breathing bob, and every
///   few seconds a quick wing flutter (rest → wings-spread → rest).
/// - **talking** (`isPlaying`): the beak genuinely opens and closes
///   (rest ↔ open-beak frames) with a lively bob.
/// - **dancing** (`voicePath` is a praise/sticker line): leans side to
///   side with a hop — Mithu celebrates WITH the child.
class MithuTalking extends StatefulWidget {
  final bool isPlaying;
  final String? voicePath;
  final double size;

  const MithuTalking({
    super.key,
    required this.isPlaying,
    this.voicePath,
    this.size = 120,
  });

  @override
  State<MithuTalking> createState() => _MithuTalkingState();
}

class _MithuTalkingState extends State<MithuTalking>
    with TickerProviderStateMixin {
  static const _rest = 'assets/art/characters/mithu_rest.png';
  static const _open = 'assets/art/characters/mithu_hero_talk.png';
  static const _spread = 'assets/art/characters/mithu_hero.png';
  static const _leanL = 'assets/art/characters/mithu_lean_left.png';
  static const _leanR = 'assets/art/characters/mithu_lean_right.png';

  late final AnimationController _idleController; // breathing + dance clock
  Timer? _frameTimer;
  Timer? _flutterTimer;
  bool _beakOpen = false;
  bool _flutterNow = false;
  // Per-instance celebration style so wins do not all look identical:
  // 0 = lean dance, 1 = spin-hop, 2 = happy flap.
  final int _danceStyle = Random().nextInt(3);

  bool get _dancing {
    final p = widget.voicePath ?? '';
    return p.contains('shabash') ||
        p.contains('wah') ||
        p.contains('badhiya') ||
        p.contains('sticker') ||
        p.contains('yum');
  }

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    )..repeat();
    _syncFrameTimer();
    _scheduleFlutter();
  }

  @override
  void didUpdateWidget(covariant MithuTalking old) {
    super.didUpdateWidget(old);
    if (old.isPlaying != widget.isPlaying) _syncFrameTimer();
  }

  void _syncFrameTimer() {
    _frameTimer?.cancel();
    if (widget.isPlaying) {
      _frameTimer = Timer.periodic(const Duration(milliseconds: 140), (_) {
        if (mounted) setState(() => _beakOpen = !_beakOpen);
      });
    } else {
      _beakOpen = false;
      if (mounted) setState(() {});
    }
  }

  /// Every 3.5–7s of quiet idling, a quick wing flutter keeps him alive.
  void _scheduleFlutter() {
    _flutterTimer = Timer(
      Duration(milliseconds: 3500 + Random().nextInt(3500)),
      () async {
        if (!mounted) return;
        if (!widget.isPlaying && !_dancing) {
          setState(() => _flutterNow = true);
          await Future.delayed(const Duration(milliseconds: 450));
          if (mounted) setState(() => _flutterNow = false);
        }
        if (mounted) _scheduleFlutter();
      },
    );
  }

  @override
  void dispose() {
    _idleController.dispose();
    _frameTimer?.cancel();
    _flutterTimer?.cancel();
    super.dispose();
  }

  String get _frame {
    if (_dancing) {
      final beat = (_idleController.value * 8).floor();
      if (_danceStyle == 2) return beat.isEven ? _spread : _rest;
      if (_danceStyle == 1) return _spread;
      return beat.isEven ? _leanL : _leanR;
    }
    if (widget.isPlaying) return _beakOpen ? _open : _rest;
    if (_flutterNow) return _spread;
    return _rest;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _idleController,
      builder: (context, child) {
        final t = _idleController.value * 2 * pi;
        double dy;
        double tiltAngle;
        double scale = 1.0;
        if (_dancing) {
          final beat = _idleController.value * 8;
          final frac = beat - beat.floor();
          final hop = -14.0 * (frac < 0.5 ? frac * 2 : (1 - frac) * 2);
          if (_danceStyle == 1) {
            // Spin-hop: a full joyful turn per dance clock cycle.
            dy = hop * 0.7;
            tiltAngle = _idleController.value * 2 * pi;
            scale = 1.05;
          } else if (_danceStyle == 2) {
            // Happy flap: fast wing frames + bouncy double-bob.
            dy = 6.0 * sin(t * 6) - 6;
            tiltAngle = 0.04 * sin(t * 5);
            scale = 1.06;
          } else {
            dy = hop;
            tiltAngle = (beat.floor().isEven ? -1 : 1) * 0.06;
            scale = 1.03;
          }
        } else if (widget.isPlaying) {
          dy = 4.0 * sin(t * 3);
          tiltAngle = 0.02 * sin(t * 2);
        } else {
          dy = 5.0 * sin(t);
          tiltAngle = 0.015 * sin(t * 0.7);
        }
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: tiltAngle,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: SizedBox(
        width: widget.size * uiScale(context),
        height: widget.size * uiScale(context),
        // Same-composition on-model frames: a plain swap reads as motion.
        child: ClipOval(
          child: Image.asset(_frame, fit: BoxFit.cover, gaplessPlayback: true),
        ),
      ),
    );
  }
}

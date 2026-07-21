import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/audio.dart';

/// The house tap verb (feel rules F1/F2/F6/F20).
///
/// Registers on touch-DOWN, never on finger-lift: the squash, the sound
/// and the haptic all fire the moment the finger lands — a toddler
/// pressing hard-and-long still gets instant proof the app heard them.
/// The [onTap] side-effect (navigation etc.) fires on lift as usual.
///
/// Grammar: squash to 0.92 in ~90ms on press; release pops through 1.07
/// and settles at 1.0 over ~340ms. All tween endpoints are explicit and
/// every curve is bounded (the repo rule: overshooting curves never go
/// inside a TweenSequence).
class TapBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// Fired on touch-DOWN — put the reaction (speak the word, count the
  /// tap) here when it should not wait for finger-lift.
  final VoidCallback? onDown;

  /// Play the pentatonic tap note on touch-down. Pass the service to
  /// enable; leave null for silent bounces (e.g. when the tap already
  /// triggers its own voice line).
  final AudioService? tapSound;

  /// Light haptic on touch-down (garnish only — no-op on iPads).
  final bool haptic;

  const TapBounce({
    super.key,
    required this.child,
    this.onTap,
    this.onDown,
    this.tapSound,
    this.haptic = true,
  });

  @override
  State<TapBounce> createState() => _TapBounceState();
}

class _TapBounceState extends State<TapBounce> with TickerProviderStateMixin {
  late final AnimationController _press;
  late final AnimationController _release;
  late final Animation<double> _pressScale;
  late final Animation<double> _releaseScale;
  bool _inPress = false;
  bool _fingerDown = false;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        duration: const Duration(milliseconds: 90), vsync: this);
    _release = AnimationController(
        duration: const Duration(milliseconds: 340), vsync: this)
      ..value = 1.0; // rest = settled at scale 1.0
    _pressScale = Tween(begin: 1.0, end: 0.92)
        .animate(CurvedAnimation(parent: _press, curve: Curves.easeOut));
    _releaseScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.92, end: 1.07)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.07, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 65,
      ),
    ]).animate(_release);
    // Finger lifted before the squash finished: play the squash out
    // fully, then release — the bounce must never be clipped short.
    _press.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_fingerDown) {
        _startRelease();
      }
    });
  }

  @override
  void dispose() {
    _press.dispose();
    _release.dispose();
    super.dispose();
  }

  void _startRelease() {
    _inPress = false;
    _release.forward(from: 0.0);
  }

  void _down(TapDownDetails _) {
    _fingerDown = true;
    _inPress = true;
    _release.stop();
    _press.forward(from: 0.0);
    if (widget.haptic) HapticFeedback.lightImpact();
    widget.tapSound?.playTapNote();
    widget.onDown?.call();
  }

  void _up(TapUpDetails _) {
    _fingerDown = false;
    if (_press.isCompleted) _startRelease();
    widget.onTap?.call();
  }

  void _cancel() {
    _fingerDown = false;
    if (_press.isCompleted) _startRelease();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([_press, _release]),
        builder: (context, child) => Transform.scale(
          scale: _inPress ? _pressScale.value : _releaseScale.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

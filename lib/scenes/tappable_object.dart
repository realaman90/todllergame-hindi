import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../audio/audio.dart';
import '../content/content.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

/// A tappable scene object: idle ambient motion, tap animation + SFX,
/// word audio, and reports the tap so the scene can show the word overlay.
class TappableObject extends StatefulWidget {
  final Scene scene;
  final SceneObject object;
  final AudioService audio;
  final String language;
  /// Reports the object's global rect at tap time (used as the
  /// sticker-flight source) — replaces per-object GlobalKeys.
  final ValueChanged<Rect> onTap;

  const TappableObject({
    super.key,
    required this.scene,
    required this.object,
    required this.audio,
    required this.language,
    required this.onTap,
  });

  @override
  State<TappableObject> createState() => _TappableObjectState();
}

class _TappableObjectState extends State<TappableObject>
    with TickerProviderStateMixin {
  late final AnimationController _tapController;
  late final AnimationController _idleController;
  Animation<double>? _tapAnimation;
  Timer? _overlayTimer;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _idleController = AnimationController(
      duration: const Duration(milliseconds: 3200),
      vsync: this,
    );
    _setTapAnimation();
    _idleController.repeat();
  }

  @override
  void didUpdateWidget(covariant TappableObject oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.object.anim != widget.object.anim) {
      _setTapAnimation();
    }
  }

  void _setTapAnimation() {
    _tapAnimation = switch (widget.object.anim) {
      'wiggle' => TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(begin: 0.0, end: -0.12),
            weight: 25,
          ),
          TweenSequenceItem(
            tween: Tween(begin: -0.12, end: 0.12),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween(begin: 0.12, end: 0.0),
            weight: 25,
          ),
        ]).animate(CurvedAnimation(parent: _tapController, curve: Curves.easeInOut)),
      'pop' => TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.15), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 30),
        ]).animate(CurvedAnimation(parent: _tapController, curve: Curves.easeInOut)),
      'float' => TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -16.0), weight: 50),
          TweenSequenceItem(tween: Tween(begin: -16.0, end: 0.0), weight: 50),
        ]).animate(CurvedAnimation(parent: _tapController, curve: Curves.easeInOut)),
      _ => TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.18, end: 1.0), weight: 50),
        ]).animate(CurvedAnimation(parent: _tapController, curve: Curves.easeInOut)),
    };
  }

  void _handleTap() {
    _tapController.forward(from: 0.0);
    widget.audio.playSfx('tap_pop');
    widget.audio.playWord(
      widget.scene.id,
      widget.object.slug,
      language: widget.language,
      slow: false,
    );

    // Show the word overlay only after the object animation completes so the
    // child sees the art react before it is dimmed by the scrim.
    // Capture the rect NOW while this context is definitely mounted.
    final box = context.findRenderObject() as RenderBox?;
    final rect = (box != null && box.hasSize)
        ? box.localToGlobal(Offset.zero) & box.size
        : Rect.zero;
    _overlayTimer?.cancel();
    _overlayTimer = Timer(
      const Duration(milliseconds: 350),
      () => widget.onTap(rect),
    );
  }

  @override
  void dispose() {
    _overlayTimer?.cancel();
    _tapController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = AppColors.forTheme(widget.scene.theme);
    final deepColor = AppColors.deepFor(widget.scene.theme);
    final size = 100.0 * widget.object.scale;
    final phase = (widget.object.slug.hashCode.abs() % 1000) / 1000 * 2 * pi;

    Widget tile = ArtTile(
      imagePath: 'assets/art/${widget.object.art}',
      wordHi: widget.object.wordHi,
      color: themeColor,
      deepColor: deepColor,
      size: size,
      showLabel: true,
    );

    // Tap animation layer.
    if (_tapAnimation != null) {
      tile = AnimatedBuilder(
        animation: _tapAnimation!,
        builder: (context, child) {
          if (widget.object.anim == 'float') {
            return Transform.translate(
              offset: Offset(0, _tapAnimation!.value),
              child: child,
            );
          }
          return Transform.rotate(
            angle: widget.object.anim == 'wiggle' ? _tapAnimation!.value : 0.0,
            child: Transform.scale(
              scale: widget.object.anim == 'wiggle'
                  ? 1.0
                  : _tapAnimation!.value,
              child: child,
            ),
          );
        },
        child: tile,
      );
    }

    // Subtle idle breathing layer.
    tile = AnimatedBuilder(
      animation: _idleController,
      builder: (context, child) {
        final value = _idleController.value * 2 * pi + phase;
        // 6% breath + a light sway so idle life is visible at arm's
        // length on a tablet, not just under a magnifier.
        final scale = 1.0 + 0.06 * sin(value);
        final tilt = 0.02 * sin(value * 0.5 + phase);
        return Transform.rotate(
          angle: tilt,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: tile,
    );

    return GestureDetector(
      onTapDown: (_) => _handleTap(),
      behavior: HitTestBehavior.opaque,
      child: tile,
    );
  }
}

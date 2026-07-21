import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../../juice/juice.dart';
import '../activity.dart';

/// आइसक्रीम बनाओ — the ice-cream parlor (founder upgrade 2026-07-21).
///
/// A real parlor flow in three joyful steps:
///   1. choose a flavor — the scoop plops onto the waffle cone,
///   2. choose toppings — fruit bits and sprinkles land on the scoop,
///   3. give it to Mithu — he slides in, you drag him the cone, he
///      munches it and dances.
/// Every choice is right; vocabulary is the house-scene food words.
class IceCreamActivity extends Activity {
  const IceCreamActivity();

  @override
  String get id => 'icecream';

  @override
  String get titleHi => 'आइसक्रीम बनाओ';

  @override
  Widget build(BuildContext context, ActivitySession session) {
    return IceCreamBody(session: session, key: const ValueKey('icecream'));
  }
}

enum _ParlorPhase { flavor, topping, serve, done }

class _Flavor {
  final String slug;
  final String wordHi;
  final Color tint;

  const _Flavor(this.slug, this.wordHi, this.tint);
}

class _Topping {
  final String slug; // 'sprinkles' or a fruit slug
  final Offset spot; // where it landed on the scoop (0..1 of scoop size)

  const _Topping(this.slug, this.spot);
}

class IceCreamBody extends StatefulWidget {
  final ActivitySession session;

  const IceCreamBody({super.key, required this.session});

  @override
  State<IceCreamBody> createState() => _IceCreamBodyState();
}

class _IceCreamBodyState extends State<IceCreamBody>
    with TickerProviderStateMixin {
  static const _flavors = [
    _Flavor('aam', 'आम', Color(0xFFF2A93B)),
    _Flavor('kela', 'केला', Color(0xFFF7DC6F)),
    _Flavor('seb', 'सेब', Color(0xFFE86A6A)),
  ];
  static const _toppingsMax = 3;
  // Deterministic landing spots so toppings never overlap.
  static const _spots = [
    Offset(0.26, 0.30),
    Offset(0.62, 0.22),
    Offset(0.44, 0.55),
  ];

  var _phase = _ParlorPhase.flavor;
  _Flavor? _flavor;
  final List<_Topping> _toppings = [];
  bool _coneServed = false;

  late final AnimationController _idle;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
        duration: const Duration(milliseconds: 3000), vsync: this)
      ..repeat();
    widget.session.audio
        .playHostSequence(['mithu_game_icecream', 'mithu_konsa_loge']);
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  void _pickFlavor(_Flavor f) {
    if (_phase != _ParlorPhase.flavor) return;
    setState(() {
      _flavor = f;
      _phase = _ParlorPhase.topping;
    });
    widget.session.audio.playWord('house', f.slug, language: 'hi');
    widget.session.audio.playSfx('tap_pop');
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted && _phase == _ParlorPhase.topping) {
        widget.session.audio.playHost('mithu_upar_daalo');
      }
    });
  }

  void _pickTopping(String slug) {
    if (_phase != _ParlorPhase.topping) return;
    if (_toppings.length >= _toppingsMax) return;
    setState(() {
      _toppings.add(_Topping(slug, _spots[_toppings.length]));
    });
    if (slug == 'sprinkles') {
      widget.session.audio.playSfx('tap_pop');
    } else {
      widget.session.audio.playWord('house', slug, language: 'hi');
    }
    // Two toppings make an ice cream — time to serve it.
    if (_toppings.length >= 2) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted || _phase != _ParlorPhase.topping) return;
        setState(() => _phase = _ParlorPhase.serve);
        widget.session.audio.playHost('mithu_mujhe_do');
      });
    }
  }

  Future<void> _serve() async {
    if (_phase != _ParlorPhase.serve) return;
    setState(() {
      _phase = _ParlorPhase.done;
      _coneServed = true;
    });
    // Munch munch — then the happy verdict, then the carousel celebrates.
    widget.session.audio.playSfx('tap_pop');
    await Future.delayed(const Duration(milliseconds: 350));
    widget.session.audio.playSfx('tap_pop');
    await Future.delayed(const Duration(milliseconds: 400));
    await widget.session.audio.playHost('mithu_yum');
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) widget.session.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Counter: the cone under assembly, center-left.
      Align(
        alignment: const Alignment(-0.35, -0.25),
        child: _coneServed
            ? const SizedBox(width: 200, height: 270)
            : _buildConeAssembly(interactive: _phase == _ParlorPhase.serve),
      ),
      // Option tray along the bottom, per phase.
      Align(
        alignment: const Alignment(0, 0.92),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(
                      begin: const Offset(0, 0.25), end: Offset.zero)
                  .animate(anim),
              child: child,
            ),
          ),
          child: switch (_phase) {
            _ParlorPhase.flavor => _flavorTray(),
            _ParlorPhase.topping => _toppingTray(),
            _ => const SizedBox(key: ValueKey('empty-tray')),
          },
        ),
      ),
      // Mithu slides in from the right when it's time to serve.
      AnimatedPositioned(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutBack,
        right: _phase == _ParlorPhase.serve || _phase == _ParlorPhase.done
            ? 18
            : -220,
        bottom: 46,
        child: DragTarget<bool>(
          onWillAcceptWithDetails: (_) => _phase == _ParlorPhase.serve,
          onAcceptWithDetails: (_) => _serve(),
          builder: (context, candidates, rejected) {
            final excited = candidates.isNotEmpty;
            return GestureDetector(
              onTap: _serve,
              child: Transform.scale(
                scale: excited ? 1.12 : 1.0,
                child: ListenableBuilder(
                  listenable: widget.session.audio,
                  builder: (context, _) => MithuTalking(
                    isPlaying: widget.session.audio.isPlaying,
                    voicePath: widget.session.audio.currentVoicePath,
                    size: 160,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  /// The cone + scoop + toppings collage. In the serve phase the whole
  /// thing is draggable toward Mithu and pulses as an invitation.
  Widget _buildConeAssembly({required bool interactive}) {
    final assembly = SizedBox(
      width: 200,
      height: 270,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            bottom: 0,
            child: const ArtTile(
              imagePath: 'assets/art/objects/icecream_cone_empty.png',
              color: AppColors.marigold,
              deepColor: AppColors.marigoldDeep,
              size: 175,
              showLabel: false,
            ),
          ),
          if (_flavor != null)
            Positioned(
              top: 4,
              child: _ScoopPlop(
                child: SizedBox(
                  width: 126,
                  height: 126,
                  child: Stack(children: [
                    const ArtTile(
                      imagePath: 'assets/art/objects/icecream_scoop.png',
                      color: AppColors.marigold,
                      deepColor: AppColors.marigoldDeep,
                      size: 126,
                      showLabel: false,
                    ),
                    // Flavor wash over the vanilla scoop.
                    Container(
                      width: 126,
                      height: 126,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        color: _flavor!.tint.withValues(alpha: 0.30),
                      ),
                    ),
                    for (final t in _toppings)
                      Positioned(
                        left: t.spot.dx * 126 - 15,
                        top: t.spot.dy * 126 - 15,
                        child: PopIn(child: _toppingChip(t.slug, 30)),
                      ),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );

    if (!interactive) return assembly;

    // Serve phase: pulse gently + draggable to Mithu.
    return AnimatedBuilder(
      animation: _idle,
      builder: (context, child) => Transform.scale(
        scale: 1.0 + 0.04 * sin(_idle.value * 2 * pi * 2),
        child: child,
      ),
      child: Draggable<bool>(
        data: true,
        feedback: Transform.scale(scale: 1.05, child: assembly),
        childWhenDragging: Opacity(opacity: 0.25, child: assembly),
        child: assembly,
      ),
    );
  }

  Widget _toppingChip(String slug, double size) {
    if (slug == 'sprinkles') {
      return CustomPaint(
          size: Size(size, size), painter: _SprinklesPainter());
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset('assets/art/objects/house_$slug.png',
            fit: BoxFit.cover),
      ),
    );
  }

  Widget _flavorTray() {
    return Row(
      key: const ValueKey('flavor-tray'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _flavors.length; i++) ...[
          _trayOption(
            delay: 120 * i,
            onTap: () => _pickFlavor(_flavors[i]),
            child: ArtTile(
              imagePath: 'assets/art/objects/house_${_flavors[i].slug}.png',
              wordHi: _flavors[i].wordHi,
              color: AppColors.marigold,
              deepColor: AppColors.marigoldDeep,
              size: 96,
              showLabel: true,
            ),
          ),
          if (i < _flavors.length - 1) const SizedBox(width: 24),
        ],
      ],
    );
  }

  Widget _toppingTray() {
    // Sprinkles + the two fruits NOT chosen as the flavor.
    final fruits =
        _flavors.where((f) => f.slug != _flavor?.slug).toList();
    final options = <(String, Widget)>[
      (
        'sprinkles',
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: CustomPaint(painter: _SprinklesPainter()),
        )
      ),
      for (final f in fruits)
        (
          f.slug,
          ArtTile(
            imagePath: 'assets/art/objects/house_${f.slug}.png',
            wordHi: f.wordHi,
            color: AppColors.marigold,
            deepColor: AppColors.marigoldDeep,
            size: 96,
            showLabel: true,
          )
        ),
    ];

    return Row(
      key: const ValueKey('topping-tray'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          _trayOption(
            delay: 120 * i,
            onTap: () => _pickTopping(options[i].$1),
            child: options[i].$2,
          ),
          if (i < options.length - 1) const SizedBox(width: 24),
        ],
      ],
    );
  }

  Widget _trayOption(
      {required int delay,
      required VoidCallback onTap,
      required Widget child}) {
    return PopIn(
      delayMs: 100 + delay,
      child: AnimatedBuilder(
        animation: _idle,
        builder: (context, c) {
          final t = _idle.value * 2 * pi + delay.toDouble();
          return Transform.scale(scale: 1.0 + 0.05 * sin(t), child: c);
        },
        child: TapBounce(onDown: onTap, child: child),
      ),
    );
  }
}

/// Colorful sprinkle capsules on a small square — used both as the tray
/// tile art and as the on-scoop topping chip.
class _SprinklesPainter extends CustomPainter {
  static const _colors = [
    AppColors.kumkum,
    AppColors.peacock,
    AppColors.marigold,
    AppColors.mehndi,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Fixed pseudo-random layout: same sprinkles every time (no flicker).
    for (var i = 0; i < 10; i++) {
      final fx = (i * 37 % 83) / 83;
      final fy = (i * 53 % 71) / 71;
      final angle = (i * 67 % 90) / 90 * pi;
      canvas.save();
      canvas.translate(
          size.width * (0.15 + 0.7 * fx), size.height * (0.15 + 0.7 * fy));
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero,
                width: size.width * 0.22,
                height: size.width * 0.07),
            const Radius.circular(4)),
        Paint()..color = _colors[i % _colors.length],
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SprinklesPainter old) => false;
}

/// Squash-and-stretch entrance for the scoop: drops in, squashes on
/// landing, springs back — the classic satisfying "plop".
class _ScoopPlop extends StatefulWidget {
  final Widget child;

  const _ScoopPlop({required this.child});

  @override
  State<_ScoopPlop> createState() => _ScoopPlopState();
}

class _ScoopPlopState extends State<_ScoopPlop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        duration: const Duration(milliseconds: 650), vsync: this)
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final drop = t < 0.45 ? -90.0 * (1 - t / 0.45) : 0.0;
        double sx = 1.0, sy = 1.0;
        if (t >= 0.45 && t < 0.7) {
          final k = (t - 0.45) / 0.25;
          sx = 1.0 + 0.25 * sin(k * pi);
          sy = 1.0 - 0.22 * sin(k * pi);
        } else if (t >= 0.7) {
          final k = (t - 0.7) / 0.3;
          sx = 1.0 + 0.06 * sin((1 - k) * pi);
          sy = 1.0 - 0.05 * sin((1 - k) * pi);
        }
        final fade = (t / 0.2).clamp(0.0, 1.0);
        return Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: Offset(0, drop),
            child: Transform.scale(scaleX: sx, scaleY: sy, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

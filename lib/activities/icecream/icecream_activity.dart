import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../activity.dart';

/// आइसक्रीम बनाओ — make ice cream! The first "making" game.
///
/// Two forgiving drag steps into a mixing bowl: first दूध (milk), then a
/// fruit flavor of the child's choice (आम / केला / सेब — every choice is
/// right). The bowl shakes, and out pops an ice cream cone tinted by the flavor.
/// Vocabulary is fixed to the house-scene food words.
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

class _Ingredient {
  final String slug;
  final String wordHi;
  final Color tint;

  const _Ingredient(this.slug, this.wordHi, this.tint);
}

class IceCreamBody extends StatefulWidget {
  final ActivitySession session;

  const IceCreamBody({super.key, required this.session});

  @override
  State<IceCreamBody> createState() => _IceCreamBodyState();
}

class _IceCreamBodyState extends State<IceCreamBody> with TickerProviderStateMixin {
  static const _milk = _Ingredient('doodh', 'दूध', Colors.white);
  static const _fruits = [
    _Ingredient('aam', 'आम', Color(0xFFF2A93B)),
    _Ingredient('kela', 'केला', Color(0xFFF7DC6F)),
    _Ingredient('seb', 'सेब', Color(0xFFE86A6A)),
  ];

  bool _milkIn = false;
  _Ingredient? _flavor;
  bool _done = false;

  late final AnimationController _idle;
  late final AnimationController _shake;
  late final AnimationController _pour;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
        duration: const Duration(milliseconds: 3000), vsync: this)
      ..repeat();
    _shake = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);
    _pour = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);

    widget.session.audio.playHost('mithu_game_icecream');
  }

  @override
  void dispose() {
    _idle.dispose();
    _shake.dispose();
    _pour.dispose();
    super.dispose();
  }

  void _accept(_Ingredient ing) {
    if (_done) return;
    if (!_milkIn) {
      if (ing.slug != 'doodh') return; // pot only wants milk first
      setState(() => _milkIn = true);
      _pour.forward(from: 0.0);
      widget.session.audio.playWord('house', 'doodh', language: 'hi');
      widget.session.audio.playSfx('tap_pop');
    } else if (_flavor == null) {
      if (ing.slug == 'doodh') return;
      setState(() => _flavor = ing);
      widget.session.audio.playWord('house', ing.slug, language: 'hi');
      _shake.forward(from: 0.0).whenCompleteOrCancel(() async {
        if (!mounted) return;
        setState(() => _done = true);
        await widget.session.audio.playHost('mithu_icecream');
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) widget.session.onComplete();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = AppColors.marigold;
    const deepColor = AppColors.marigoldDeep;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 210,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The matka pot — also the drag target.
              AnimatedBuilder(
                animation: Listenable.merge([_idle, _shake, _pour]),
                builder: (context, child) {
                  final wobble = _shake.isAnimating
                      ? sin(_shake.value * pi * 6) * 0.09
                      : 0.02 * sin(_idle.value * 2 * pi);
                  final pourPop = _pour.isAnimating
                      ? 1.0 + 0.08 * sin(_pour.value * pi)
                      : 1.0;
                  return Transform.rotate(
                    angle: wobble,
                    child: Transform.scale(scale: pourPop, child: child),
                  );
                },
                child: DragTarget<_Ingredient>(
                  // Forgiving: any hover over the pot area counts.
                  onWillAcceptWithDetails: (d) => !_done,
                  onAcceptWithDetails: (d) => _accept(d.data),
                  builder: (context, candidates, rejected) {
                    final excited = candidates.isNotEmpty;
                    return Transform.scale(
                      scale: excited ? 1.08 : 1.0,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const ArtTile(
                            imagePath: 'assets/art/objects/icecream_bowl.png',
                            color: themeColor,
                            deepColor: deepColor,
                            size: 185,
                            showLabel: false,
                          ),
                          // Milk fill peeks over the rim.
                          if (_milkIn && !_done)
                            Positioned(
                              top: 38,
                              child: Container(
                                width: 86,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: _flavor == null
                                      ? Colors.white
                                      : _flavor!.tint,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // The finished kulfi pops out above the pot.
              if (_done)
                Positioned(
                  top: 0,
                  child: _ScoopPlop(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const ArtTile(
                          imagePath: 'assets/art/objects/icecream_done.png',
                          color: themeColor,
                          deepColor: deepColor,
                          size: 150,
                          showLabel: false,
                        ),
                        // Flavor tint wash over the kulfi.
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: (_flavor?.tint ?? Colors.white)
                                .withValues(alpha: 0.22),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        // Ingredient tray.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _draggable(_milk, used: _milkIn, delay: 0),
            const SizedBox(width: 26),
            for (var i = 0; i < _fruits.length; i++) ...[
              _draggable(_fruits[i],
                  used: _flavor != null, delay: 140 * (i + 1)),
              if (i < _fruits.length - 1) const SizedBox(width: 26),
            ],
          ],
        ),
      ],
    );
  }

  Widget _draggable(_Ingredient ing, {required bool used, required int delay}) {
    const themeColor = AppColors.marigold;
    const deepColor = AppColors.marigoldDeep;
    final tile = ArtTile(
      imagePath: 'assets/art/objects/house_${ing.slug}.png',
      wordHi: ing.wordHi,
      color: themeColor,
      deepColor: deepColor,
      size: 92,
      showLabel: true,
    );

    if (used && ing.slug == 'doodh' || used && ing.slug != 'doodh' && _flavor != null && _flavor!.slug != ing.slug) {
      // Spent or unchosen ingredients rest dimmed.
      return Opacity(opacity: 0.35, child: tile);
    }
    if (_flavor != null && _flavor!.slug == ing.slug) {
      return Opacity(opacity: 0.35, child: tile);
    }

    return PopIn(
      delayMs: 100 + delay,
      child: AnimatedBuilder(
        animation: _idle,
        builder: (context, child) {
          final t = _idle.value * 2 * pi + delay.toDouble();
          return Transform.scale(
              scale: 1.0 + 0.05 * sin(t), child: child);
        },
        child: Draggable<_Ingredient>(
          data: ing,
          feedback: Transform.scale(
            scale: 1.2,
            child: ArtTile(
              imagePath: 'assets/art/objects/house_${ing.slug}.png',
              color: themeColor,
              deepColor: deepColor,
              size: 92,
              showLabel: false,
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: tile),
          child: GestureDetector(
            onTap: () => widget.session.audio
                .playWord('house', ing.slug, language: 'hi'),
            child: tile,
          ),
        ),
      ),
    );
  }
}

/// Squash-and-stretch entrance for the finished cone: drops in, squashes
/// on landing, springs back — the classic satisfying "plop".
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

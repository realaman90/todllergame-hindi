import 'dart:math';

import 'package:flutter/material.dart';

import '../../juice/juice.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../activity.dart';

/// पौधा उगाओ (Grow a plant, format #26): give the little sprout its
/// पानी and its सूरज — any order, every choice right — and it blooms
/// into a flower; a butterfly flutters in to land on it. Uses only
/// existing curriculum words (paani, sooraj, phool).
class PlantActivity extends Activity {
  const PlantActivity();

  @override
  String get id => 'plant';

  @override
  String get titleHi => 'पौधा उगाओ';

  @override
  Widget build(BuildContext context, ActivitySession session) {
    return PlantBody(session: session, key: UniqueKey());
  }
}

class PlantBody extends StatefulWidget {
  final ActivitySession session;

  const PlantBody({super.key, required this.session});

  @override
  State<PlantBody> createState() => _PlantBodyState();
}

class _PlantBodyState extends State<PlantBody>
    with TickerProviderStateMixin {
  bool _watered = false;
  bool _sunned = false;
  bool _bloomed = false;
  int _burstTrigger = 0;
  Offset _burstAt = Offset.zero;

  late final AnimationController _idle;
  late final AnimationController _grow;
  late final AnimationController _flap;

  bool get _ready => _watered && _sunned;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
        duration: const Duration(milliseconds: 3000), vsync: this)
      ..repeat();
    _grow = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _flap = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this)
      ..repeat(reverse: true);
    widget.session.audio.playHost('mithu_game_plant');
  }

  @override
  void dispose() {
    _idle.dispose();
    _grow.dispose();
    _flap.dispose();
    super.dispose();
  }

  Future<void> _give(String what) async {
    if (_bloomed) return;
    if (what == 'paani' && !_watered) {
      setState(() => _watered = true);
      widget.session.audio.playSfx('tap_soft', rate: 1.1);
      widget.session.audio.playWord('house', 'paani', language: 'hi');
      _grow.forward();
    } else if (what == 'sooraj' && !_sunned) {
      setState(() => _sunned = true);
      widget.session.audio.playSfx('tap_soft', rate: 1.3);
      widget.session.audio.playWord('farm', 'sooraj', language: 'hi');
    } else {
      return;
    }
    if (_ready) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      final stackBox = context.findRenderObject();
      setState(() {
        _bloomed = true;
        _burstTrigger++;
        if (stackBox is RenderBox) {
          _burstAt = Offset(stackBox.size.width / 2,
              stackBox.size.height * 0.38);
        }
      });
      widget.session.audio.playSfx('ding_sticker');
      await widget.session.audio.playWord('farm', 'phool', language: 'hi');
      await Future.delayed(const Duration(milliseconds: 1100));
      if (mounted) widget.session.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = uiScale(context);
    const themeColor = AppColors.mehndi;
    const deepColor = AppColors.mehndiDeep;

    return Stack(children: [
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // The plant, growing up the middle — also the drag target.
          DragTarget<String>(
            onWillAcceptWithDetails: (_) => !_bloomed,
            onAcceptWithDetails: (d) => _give(d.data),
            builder: (context, candidates, rejected) => Transform.scale(
              scale: candidates.isNotEmpty ? 1.08 : 1.0,
              child: SizedBox(
                height: 230 * s,
                child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge([_idle, _grow]),
                  builder: (context, child) {
                    final sway = 0.03 * sin(_idle.value * 2 * pi);
                    final growth = 1.0 + 0.4 * _grow.value;
                    return Transform.rotate(
                      angle: sway,
                      alignment: Alignment.bottomCenter,
                      child: Transform.scale(
                        scale: growth,
                        alignment: Alignment.bottomCenter,
                        child: child,
                      ),
                    );
                  },
                  child: _bloomed
                      ? PopIn(
                          child: ArtTile(
                            imagePath: 'assets/art/objects/farm_phool.png',
                            color: themeColor,
                            deepColor: deepColor,
                            size: 170,
                            showLabel: false,
                          ),
                        )
                      : ArtTile(
                          imagePath: 'assets/art/objects/plant_sprout.png',
                          color: themeColor,
                          deepColor: deepColor,
                          size: 130,
                          showLabel: false,
                        ),
                ),
                // Warm sun glow once the sun is given.
                if (_sunned && !_bloomed)
                  Positioned(
                    top: -8,
                    child: IgnorePointer(
                      child: Container(
                        width: 90 * s,
                        height: 90 * s,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              AppColors.marigold.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  ),
                // The butterfly lands after the bloom.
                if (_bloomed)
                  Positioned(
                    top: 0,
                    right: 26 * s,
                    child: AnimatedBuilder(
                      animation: _flap,
                      builder: (context, _) => CustomPaint(
                        size: Size(44 * s, 36 * s),
                        painter:
                            _ButterflyPainter(flap: _flap.value),
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 36 * s),
          // What the sprout needs.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _giveTile('paani', 'assets/art/objects/house_paani.png',
                  'पानी', _watered, 0),
              SizedBox(width: 30 * s),
              _giveTile('sooraj', 'assets/art/objects/farm_sooraj.png',
                  'सूरज', _sunned, 1),
            ],
          ),
        ],
      ),
      ParticleBurst(trigger: _burstTrigger, at: _burstAt),
    ]);
  }

  Widget _giveTile(
      String what, String art, String wordHi, bool used, int i) {
    const themeColor = AppColors.mehndi;
    const deepColor = AppColors.mehndiDeep;
    final tile = ArtTile(
      imagePath: art,
      wordHi: wordHi,
      color: themeColor,
      deepColor: deepColor,
      size: 96,
      showLabel: true,
    );
    if (used) return Opacity(opacity: 0.3, child: tile);
    return PopIn(
      delayMs: 150 + 130 * i,
      child: IdleBreath(
        phase: i * 1.6,
        amplitude: 0.05,
        child: Draggable<String>(
          data: what,
          onDragStarted: () => widget.session.audio.playWord(
              what == 'paani' ? 'house' : 'farm', what,
              language: 'hi'),
          feedback: Transform.scale(scale: 1.15, child: tile),
          childWhenDragging: Opacity(opacity: 0.25, child: tile),
          child: tile,
        ),
      ),
    );
  }
}

class _ButterflyPainter extends CustomPainter {
  final double flap;

  _ButterflyPainter({required this.flap});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final wingW = size.width * (0.30 + 0.14 * flap);
    final wing = Paint()..color = AppColors.kumkum;
    final wing2 = Paint()..color = AppColors.peacock.withValues(alpha: 0.8);
    // Left + right wings (two lobes each).
    for (final dir in [-1, 1]) {
      canvas.drawOval(
        Rect.fromCenter(
            center: c + Offset(dir * wingW * 0.7, -size.height * 0.14),
            width: wingW,
            height: size.height * 0.5),
        wing,
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: c + Offset(dir * wingW * 0.55, size.height * 0.16),
            width: wingW * 0.7,
            height: size.height * 0.36),
        wing2,
      );
    }
    // Body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: c, width: size.width * 0.10, height: size.height * 0.62),
        const Radius.circular(4),
      ),
      Paint()..color = AppColors.ink,
    );
  }

  @override
  bool shouldRepaint(covariant _ButterflyPainter old) => old.flap != flap;
}

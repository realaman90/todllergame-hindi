import 'dart:math';

import 'package:flutter/material.dart';

import '../../juice/juice.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../activity.dart';

/// रेल गाड़ी भरो (Load the train, format #24): fruits go in the fruit
/// wagon, animals in the animal wagon. All four loaded — the train
/// chugs off with spinning wheels. First sorting-by-category skill.
///
/// Content is fixed (house fruits + farm animals) so both categories
/// always exist regardless of the session scene.
class TrainActivity extends Activity {
  const TrainActivity();

  @override
  String get id => 'train';

  @override
  String get titleHi => 'रेल गाड़ी भरो';

  @override
  Widget build(BuildContext context, ActivitySession session) {
    return TrainBody(session: session, key: UniqueKey());
  }
}

class _Cargo {
  final String sceneId;
  final String slug;
  final String wordHi;
  final bool isFruit;

  const _Cargo(this.sceneId, this.slug, this.wordHi, this.isFruit);
}

class TrainBody extends StatefulWidget {
  final ActivitySession session;

  const TrainBody({super.key, required this.session});

  @override
  State<TrainBody> createState() => _TrainBodyState();
}

class _TrainBodyState extends State<TrainBody>
    with TickerProviderStateMixin {
  static const _cargo = [
    _Cargo('house', 'aam', 'आम', true),
    _Cargo('house', 'kela', 'केला', true),
    _Cargo('farm', 'gaay', 'गाय', false),
    _Cargo('farm', 'kutta', 'कुत्ता', false),
  ];

  late final List<_Cargo> _tray;
  final Set<String> _loaded = {};
  bool _departing = false;
  late final AnimationController _idle;
  late final AnimationController _depart;

  @override
  void initState() {
    super.initState();
    _tray = List.of(_cargo)..shuffle(Random());
    _idle = AnimationController(
        duration: const Duration(milliseconds: 3000), vsync: this)
      ..repeat();
    _depart = AnimationController(
        duration: const Duration(milliseconds: 1600), vsync: this);
    widget.session.audio.playHost('mithu_game_train');
  }

  @override
  void dispose() {
    _idle.dispose();
    _depart.dispose();
    super.dispose();
  }

  Future<void> _onLoad(_Cargo c, bool intoFruitWagon) async {
    if (_departing || _loaded.contains(c.slug)) return;
    if (c.isFruit == intoFruitWagon) {
      setState(() => _loaded.add(c.slug));
      widget.session.audio.playSfx('ding_sticker');
      widget.session.audio.playWord(c.sceneId, c.slug, language: 'hi');
      if (_loaded.length == _cargo.length) {
        _departing = true;
        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        // Chug chug — exits accelerate (F7).
        for (var i = 0; i < 4; i++) {
          widget.session.audio.playTapNote();
          await Future.delayed(const Duration(milliseconds: 180));
        }
        if (!mounted) return;
        await _depart.forward();
        if (mounted) widget.session.onComplete();
      }
    } else {
      widget.session.audio.playSfx('boop_curious');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = uiScale(context);
    final wagonW = 190.0 * s;
    final wagonH = 130.0 * s;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // The train slides off to the right when full.
        AnimatedBuilder(
          animation: _depart,
          builder: (context, child) {
            final t = Curves.easeInCubic.transform(_depart.value);
            return Transform.translate(
              offset: Offset(t * MediaQuery.sizeOf(context).width, 0),
              child: child,
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _wagon(
                  isFruit: true,
                  w: wagonW,
                  h: wagonH,
                  color: AppColors.marigold,
                  deep: AppColors.marigoldDeep,
                  badge: 'assets/art/objects/house_seb.png'),
              SizedBox(width: 18 * s),
              _wagon(
                  isFruit: false,
                  w: wagonW,
                  h: wagonH,
                  color: AppColors.peacock,
                  deep: AppColors.peacockDeep,
                  badge: 'assets/art/objects/farm_bakri.png'),
            ],
          ),
        ),
        SizedBox(height: 44 * s),
        // Cargo tray.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _tray.length; i++) ...[
              _cargoTile(_tray[i], i),
              if (i < _tray.length - 1) SizedBox(width: 22 * s),
            ],
          ],
        ),
      ],
    );
  }

  Widget _wagon(
      {required bool isFruit,
      required double w,
      required double h,
      required Color color,
      required Color deep,
      required String badge}) {
    final held = [
      for (final c in _cargo)
        if (_loaded.contains(c.slug) && c.isFruit == isFruit) c
    ];
    return DragTarget<_Cargo>(
      onWillAcceptWithDetails: (_) => !_departing,
      onAcceptWithDetails: (d) => _onLoad(d.data, isFruit),
      builder: (context, candidates, rejected) {
        final excited = candidates.isNotEmpty;
        return Transform.scale(
          scale: excited ? 1.06 : 1.0,
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(alignment: Alignment.center, children: [
              AnimatedBuilder(
                animation: _depart,
                builder: (context, _) => CustomPaint(
                  size: Size(w, h),
                  painter: _WagonPainter(
                    color: color,
                    deep: deep,
                    wheelSpin: _depart.value * 6 * pi,
                  ),
                ),
              ),
              // Category badge on the wagon side.
              Positioned(
                top: h * 0.06,
                left: w * 0.06,
                child: Container(
                  width: h * 0.30,
                  height: h * 0.30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: ClipOval(
                      child: Image.asset(badge, fit: BoxFit.cover)),
                ),
              ),
              // Loaded cargo peeks out of the wagon.
              Positioned(
                top: h * 0.02,
                child: Row(children: [
                  for (final c in held)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: PopIn(
                        child: Container(
                          width: h * 0.34,
                          height: h * 0.34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 3),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/art/objects/${c.sceneId}_${c.slug}.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _cargoTile(_Cargo c, int i) {
    if (_loaded.contains(c.slug)) {
      final s = uiScale(context);
      return SizedBox(width: 92 * s, height: 92 * s);
    }
    final themeColor = c.isFruit ? AppColors.marigold : AppColors.peacock;
    final deep = c.isFruit ? AppColors.marigoldDeep : AppColors.peacockDeep;
    final tile = ArtTile(
      imagePath: 'assets/art/objects/${c.sceneId}_${c.slug}.png',
      wordHi: c.wordHi,
      color: themeColor,
      deepColor: deep,
      size: 88,
      showLabel: true,
    );
    return PopIn(
      delayMs: 120 + 100 * i,
      child: IdleBreath(
        phase: i * 1.5,
        amplitude: 0.04,
        child: Draggable<_Cargo>(
          data: c,
          onDragStarted: () => widget.session.audio
              .playWord(c.sceneId, c.slug, language: 'hi'),
          feedback: Transform.scale(scale: 1.15, child: tile),
          childWhenDragging: Opacity(opacity: 0.25, child: tile),
          child: tile,
        ),
      ),
    );
  }
}

class _WagonPainter extends CustomPainter {
  final Color color;
  final Color deep;
  final double wheelSpin;

  _WagonPainter(
      {required this.color, required this.deep, required this.wheelSpin});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Body.
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, h * 0.18, w, h * 0.55),
      Radius.circular(h * 0.10),
    );
    canvas.drawRRect(
        body.shift(Offset(0, h * 0.03)),
        Paint()..color = deep.withValues(alpha: 0.4));
    canvas.drawRRect(body, Paint()..color = color);
    // Plank lines.
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(w * i / 3, h * 0.22),
        Offset(w * i / 3, h * 0.69),
        Paint()
          ..color = deep.withValues(alpha: 0.35)
          ..strokeWidth = 2.5,
      );
    }
    // Wheels with spokes that visibly spin on departure.
    for (final cx in [w * 0.25, w * 0.75]) {
      final c = Offset(cx, h * 0.85);
      canvas.drawCircle(c, h * 0.13, Paint()..color = AppColors.ink);
      canvas.drawCircle(
          c, h * 0.06, Paint()..color = Colors.white.withValues(alpha: 0.85));
      for (var k = 0; k < 3; k++) {
        final a = wheelSpin + k * pi / 3;
        canvas.drawLine(
          c - Offset(cos(a), sin(a)) * h * 0.11,
          c + Offset(cos(a), sin(a)) * h * 0.11,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.7)
            ..strokeWidth = 2.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WagonPainter old) =>
      old.wheelSpin != wheelSpin || old.color != color;
}

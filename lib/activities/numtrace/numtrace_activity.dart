import 'dart:math';

import 'package:flutter/material.dart';

import '../../juice/juice.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../activity.dart';

/// नंबर बनाओ (Number tracing, format #33): trace a big numeral with a
/// finger — dots light up under the stroke — then that many mangoes pop
/// in, counted aloud. Pre-writing motor skill welded onto counting.
class NumTraceActivity extends Activity {
  const NumTraceActivity();

  @override
  String get id => 'numtrace';

  @override
  String get titleHi => 'नंबर बनाओ';

  @override
  Widget build(BuildContext context, ActivitySession session) {
    return NumTraceBody(session: session, key: UniqueKey());
  }
}

class NumTraceBody extends StatefulWidget {
  final ActivitySession session;

  const NumTraceBody({super.key, required this.session});

  @override
  State<NumTraceBody> createState() => _NumTraceBodyState();
}

class _NumTraceBodyState extends State<NumTraceBody> {
  // Single-stroke, kid-stylized digit polylines in a 0..1 box.
  static const _digits = <int, List<Offset>>{
    1: [Offset(0.32, 0.28), Offset(0.52, 0.10), Offset(0.52, 0.90)],
    2: [
      Offset(0.28, 0.26),
      Offset(0.38, 0.11),
      Offset(0.62, 0.11),
      Offset(0.71, 0.30),
      Offset(0.30, 0.90),
      Offset(0.74, 0.90),
    ],
    3: [
      Offset(0.30, 0.16),
      Offset(0.60, 0.11),
      Offset(0.70, 0.28),
      Offset(0.50, 0.47),
      Offset(0.70, 0.66),
      Offset(0.60, 0.87),
      Offset(0.30, 0.84),
    ],
    4: [
      Offset(0.58, 0.10),
      Offset(0.28, 0.58),
      Offset(0.76, 0.58),
      Offset(0.62, 0.34),
      Offset(0.62, 0.90),
    ],
    5: [
      Offset(0.70, 0.12),
      Offset(0.34, 0.12),
      Offset(0.32, 0.48),
      Offset(0.58, 0.44),
      Offset(0.71, 0.62),
      Offset(0.60, 0.87),
      Offset(0.30, 0.83),
    ],
  };
  static const _numberWords = ['ek', 'do', 'teen', 'chaar', 'paanch'];
  static const _samplesN = 70;

  late final int _n;
  late final List<Offset> _samples; // normalized, evenly re-sampled
  double _progress = 0.0;
  bool _traced = false;
  int _mangoes = 0; // how many have popped in so far
  int _lastNoteDecile = 0;
  int _burstTrigger = 0;
  Offset _burstAt = Offset.zero;

  @override
  void initState() {
    super.initState();
    _n = 1 + Random().nextInt(5);
    _samples = _resample(_digits[_n]!, _samplesN);
    _intro();
  }

  Future<void> _intro() async {
    final audio = widget.session.audio;
    await audio.playHost('mithu_game_numtrace');
    if (mounted) {
      await audio.playWord('family', _numberWords[_n - 1], language: 'hi');
    }
  }

  List<Offset> _resample(List<Offset> poly, int n) {
    final lengths = <double>[0];
    var total = 0.0;
    for (var i = 1; i < poly.length; i++) {
      total += (poly[i] - poly[i - 1]).distance;
      lengths.add(total);
    }
    final out = <Offset>[];
    for (var k = 0; k <= n; k++) {
      final target = total * k / n;
      var seg = 1;
      while (seg < lengths.length - 1 && lengths[seg] < target) {
        seg++;
      }
      final t = (target - lengths[seg - 1]) /
          max(1e-6, lengths[seg] - lengths[seg - 1]);
      out.add(Offset.lerp(poly[seg - 1], poly[seg], t)!);
    }
    return out;
  }

  Offset _pointAt(Size box, double t) {
    final i = (t * _samplesN).round().clamp(0, _samplesN);
    return Offset(_samples[i].dx * box.width, _samples[i].dy * box.height);
  }

  void _onPan(Size box, Offset p) {
    if (_traced) return;
    final s = uiScale(context);
    var best = -1;
    var bestD = 64.0 * s;
    final from = (_progress * _samplesN).floor();
    final to = min(_samplesN, from + 10);
    for (var i = from; i <= to; i++) {
      final d = (p - _pointAt(box, i / _samplesN)).distance;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    if (best < 0) return;
    final np = best / _samplesN;
    if (np <= _progress) return;
    setState(() => _progress = np);
    final decile = (np * 8).floor();
    if (decile > _lastNoteDecile) {
      _lastNoteDecile = decile;
      widget.session.audio.playTapNote();
    }
    if (np >= 0.97) _finishTrace(box);
  }

  Future<void> _finishTrace(Size box) async {
    if (_traced) return;
    setState(() {
      _traced = true;
      _progress = 1.0;
      _burstTrigger++;
      _burstAt = _pointAt(box, 1.0);
    });
    widget.session.audio.playSfx('ding_sticker');
    // The payoff IS the counting: mangoes pop in one by one, counted.
    for (var i = 1; i <= _n; i++) {
      if (!mounted) return;
      setState(() => _mangoes = i);
      await widget.session.audio
          .playWord('family', _numberWords[i - 1], language: 'hi');
      await Future.delayed(const Duration(milliseconds: 120));
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) widget.session.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = AppColors.forTheme(widget.session.scene.theme);
    final s = uiScale(context);
    final boxSide = 320.0 * s;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // The numeral to trace.
        GestureDetector(
          onPanDown: (d) => _onPan(Size(boxSide, boxSide), d.localPosition),
          onPanUpdate: (d) =>
              _onPan(Size(boxSide, boxSide), d.localPosition),
          child: SizedBox(
            width: boxSide,
            height: boxSide,
            child: Stack(children: [
              CustomPaint(
                size: Size(boxSide, boxSide),
                painter: _DigitPainter(
                  n: _n,
                  samples: _samples,
                  progress: _progress,
                  color: themeColor,
                ),
              ),
              ParticleBurst(trigger: _burstTrigger, at: _burstAt),
            ]),
          ),
        ),
        SizedBox(width: 40 * s),
        // The counted mangoes appear here.
        SizedBox(
          width: 190.0 * s,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < _mangoes; i++)
                PopIn(
                  key: ValueKey('aam-$i'),
                  child: ArtTile(
                    imagePath: 'assets/art/objects/house_aam.png',
                    color: AppColors.marigold,
                    deepColor: AppColors.marigoldDeep,
                    size: 76,
                    showLabel: false,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DigitPainter extends CustomPainter {
  final int n;
  final List<Offset> samples;
  final double progress;
  final Color color;

  _DigitPainter({
    required this.n,
    required this.samples,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Ghost numeral behind the dots for shape recognition.
    final tp = TextPainter(
      text: TextSpan(
        text: '$n',
        style: TextStyle(
          fontSize: size.height * 0.86,
          fontWeight: FontWeight.w800,
          color: color.withValues(alpha: 0.10),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
        canvas,
        Offset((size.width - tp.width) / 2,
            (size.height - tp.height) / 2));

    const dots = 22;
    for (var i = 0; i <= dots; i++) {
      final t = i / dots;
      final idx = (t * (samples.length - 1)).round();
      final p = Offset(
          samples[idx].dx * size.width, samples[idx].dy * size.height);
      final passed = t <= progress;
      canvas.drawCircle(
        p,
        passed ? 9.0 : 6.5,
        Paint()
          ..color =
              passed ? color : AppColors.ink.withValues(alpha: 0.22),
      );
    }
    // Start marker so she knows where to put her finger.
    if (progress < 0.03) {
      final start = Offset(samples.first.dx * size.width,
          samples.first.dy * size.height);
      canvas.drawCircle(
          start, 14, Paint()..color = color.withValues(alpha: 0.35));
    }
  }

  @override
  bool shouldRepaint(covariant _DigitPainter old) =>
      old.progress != progress || old.n != n;
}

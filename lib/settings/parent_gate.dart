import 'dart:math';

import 'package:flutter/material.dart';
import '../theme/theme.dart';

const _holdDuration = Duration(seconds: 3);

/// Shows a Kids-Category parent gate and returns `true` only when a grown-up
/// presses and holds the confirmation button for [_holdDuration].
///
/// Releasing the button before the ring completes resets progress — the
/// long-press action is deliberate and hard for a toddler to perform.
Future<bool> showParentGate(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const _ParentGateDialog(),
  );
  return result ?? false;
}

class _ParentGateDialog extends StatefulWidget {
  const _ParentGateDialog();

  @override
  State<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<_ParentGateDialog>
    with TickerProviderStateMixin {
  late final AnimationController _progressController;
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: _holdDuration,
      vsync: this,
    );
    _progressController.addStatusListener(_onStatusChanged);
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _startHold() {
    if (!mounted) return;
    setState(() => _holding = true);
    _progressController.forward(from: _progressController.value);
  }

  void _cancelHold() {
    if (!mounted) return;
    setState(() => _holding = false);
    _progressController.animateBack(
      0.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _progressController.removeStatusListener(_onStatusChanged);
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Grown-ups only',
              style: AppTextStyles.sceneTitle.copyWith(
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'For grown-ups: press and hold the button until the ring fills.',
              textAlign: TextAlign.center,
              style: AppTextStyles.wordCardGloss.copyWith(
                color: AppColors.ink.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTapDown: (_) => _startHold(),
              onTapUp: (_) => _cancelHold(),
              onTapCancel: () => _cancelHold(),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 88,
                height: 88,
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _RingPainter(
                        progress: _progressController.value,
                        ringColor: AppColors.peacock.withValues(alpha: 0.25),
                        progressColor: AppColors.peacock,
                        strokeWidth: 8,
                      ),
                      child: child,
                    );
                  },
                  child: Center(
                    child: Icon(
                      _holding ? Icons.lock_open : Icons.lock_outline,
                      color: AppColors.peacock,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Go back',
                style: AppTextStyles.wordCardGloss.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color progressColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.ringColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);
    canvas.drawArc(
      rect,
      -pi / 2,
      progress * 2 * pi,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.ringColor != ringColor ||
      oldDelegate.progressColor != progressColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

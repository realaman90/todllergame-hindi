import 'package:flutter/material.dart';
import '../juice/juice.dart';
import '../theme/theme.dart';

/// Sticker-count pill shown in the scene app bar.
///
/// Tapping the pill opens the sticker wall; it bounces whenever the
/// count ticks up so the sticker's arrival has a landing beat (F18's
/// missed-payoff fix).
class StickerCountPill extends StatefulWidget {
  final int count;
  final VoidCallback onTap;

  const StickerCountPill({
    super.key,
    required this.count,
    required this.onTap,
  });

  @override
  State<StickerCountPill> createState() => _StickerCountPillState();
}

class _StickerCountPillState extends State<StickerCountPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
        duration: const Duration(milliseconds: 480), vsync: this);
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.28)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.28, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 65,
      ),
    ]).animate(_bounce);
  }

  @override
  void didUpdateWidget(covariant StickerCountPill old) {
    super.didUpdateWidget(old);
    if (widget.count > old.count) _bounce.forward(from: 0.0);
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TapBounce(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.paper2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.mehndiDeep, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.mehndiDeep.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded,
                  color: AppColors.marigold, size: 22),
              const SizedBox(width: 6),
              Text(
                '${widget.count}',
                style: AppTextStyles.objectLabel.copyWith(
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

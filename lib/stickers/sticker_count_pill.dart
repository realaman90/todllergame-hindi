import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Sticker-count pill shown in the scene app bar.
///
/// Tapping the pill opens the sticker wall.
class StickerCountPill extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const StickerCountPill({
    super.key,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
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
            const Icon(Icons.star_rounded, color: AppColors.marigold, size: 22),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: AppTextStyles.objectLabel.copyWith(
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

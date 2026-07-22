import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// A generic sticker tile for activity rewards.
///
/// Shows a bold activity icon on a paper sticker with the scene's theme
/// color. Used in the earned-overlay flight and on the sticker wall.
class ActivityStickerTile extends StatelessWidget {
  final String activityId;
  final Color color;
  final Color deepColor;
  final double size;

  const ActivityStickerTile({
    super.key,
    required this.activityId,
    required this.color,
    required this.deepColor,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(size * 0.18),
        border: Border.all(color: deepColor, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: deepColor.withValues(alpha: 0.25),
            blurRadius: size * 0.08,
            offset: Offset(0, size * 0.04),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        _iconFor(activityId),
        color: color,
        size: size * 0.5,
      ),
    );
  }

  static IconData _iconFor(String activityId) {
    return switch (activityId) {
      'pairs' => Icons.grid_view_rounded,
      'counting' => Icons.pin_rounded,
      'balloons' => Icons.circle_rounded,
      _ => Icons.extension_rounded,
    };
  }
}

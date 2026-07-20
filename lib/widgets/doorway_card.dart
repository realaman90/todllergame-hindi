import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A tappable doorway card: art thumbnail + colored label band.
class DoorwayCard extends StatelessWidget {
  final String sceneId;
  final String titleHi;
  final String titleTranslit;
  final Color color;
  final Color deepColor;
  final VoidCallback onTap;
  final double width;
  final double height;

  const DoorwayCard({
    super.key,
    required this.sceneId,
    required this.titleHi,
    required this.titleTranslit,
    required this.color,
    required this.deepColor,
    required this.onTap,
    this.width = 116,
    this.height = 132,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.paper2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: deepColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: deepColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Image.asset(
                'assets/art/scenes/${sceneId}_thumb.png',
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            Container(
              color: color,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titleHi,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    titleTranslit,
                    style: AppTextStyles.wordCardTranslit.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

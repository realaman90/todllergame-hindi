import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// A rounded-rect "paper sticker" tile for scene objects, overlay art,
/// puzzle cards, and sticker-wall tiles.
///
/// The art is clipped to a rounded rectangle, given a soft shadow and a
/// thin border in the scene's deep color. If the asset is missing, a
/// colored placeholder with the Devanagari word is shown.
class ArtTile extends StatelessWidget {
  final String imagePath;
  final String? wordHi;
  final Color color;
  final Color deepColor;
  final double size;
  final bool showLabel;
  final VoidCallback? onTap;

  const ArtTile({
    super.key,
    required this.imagePath,
    this.wordHi,
    required this.color,
    required this.deepColor,
    this.size = 80,
    this.showLabel = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final artSize = showLabel ? size * 0.82 : size;
    final labelHeight = showLabel ? size * 0.18 : 0.0;

    Widget art = Container(
      width: artSize,
      height: artSize,
      decoration: BoxDecoration(
        color: Colors.white,
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
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: color,
            alignment: Alignment.center,
            child: Text(
              wordHi ?? '',
              textAlign: TextAlign.center,
              style: AppTextStyles.objectLabel.copyWith(
                color: Colors.white,
                fontSize: size * 0.22,
              ),
            ),
          );
        },
      ),
    );

    if (onTap != null) {
      art = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: art,
      );
    }

    if (!showLabel || wordHi == null) return art;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        art,
        SizedBox(height: size * 0.04),
        SizedBox(
          height: labelHeight,
          child: Text(
            wordHi!,
            textAlign: TextAlign.center,
            style: AppTextStyles.objectLabel.copyWith(
              color: AppColors.ink,
              fontSize: size * 0.18,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../juice/juice.dart';
import '../theme/theme.dart';

/// A die-cut paper sticker: art inside a white sticker rim, layered soft
/// shadows, and a slight hand-placed rotation unique to each tile. The
/// look follows the v1.1 mockup's sticker language — warmth over
/// clinical borders.
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
    final rim = artSize * 0.055; // white die-cut edge
    // Hand-placed feel: stable per-art tilt of up to ~3 degrees.
    final tilt = ((imagePath.hashCode % 1000) / 1000 - 0.5) * 0.10;

    Widget art = Container(
      width: artSize,
      height: artSize,
      padding: EdgeInsets.all(rim),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(artSize * 0.22),
        boxShadow: [
          // Wide ambient lift.
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.10),
            blurRadius: artSize * 0.16,
            offset: Offset(0, artSize * 0.06),
          ),
          // Tighter tinted ground shadow.
          BoxShadow(
            color: deepColor.withValues(alpha: 0.22),
            blurRadius: artSize * 0.07,
            offset: Offset(0, artSize * 0.035),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(artSize * 0.17),
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
      ),
    );

    art = Transform.rotate(angle: tilt, child: art);

    if (onTap != null) {
      // Reaction on touch-DOWN (feel rule F1) with the house bounce.
      art = TapBounce(onDown: onTap, child: art);
    }

    if (!showLabel || wordHi == null) return art;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        art,
        SizedBox(height: size * 0.05),
        // Label chip: a little paper pill instead of floating text.
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: size * 0.10,
            vertical: size * 0.025,
          ),
          decoration: BoxDecoration(
            color: AppColors.paper2,
            borderRadius: BorderRadius.circular(size * 0.10),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.08),
                blurRadius: 3,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: Text(
            wordHi!,
            textAlign: TextAlign.center,
            style: AppTextStyles.objectLabel.copyWith(
              color: AppColors.ink,
              fontSize: size * 0.17,
            ),
          ),
        ),
      ],
    );
  }
}

/// Soft scene-tinted backdrop for game and picker screens: a warm radial
/// wash plus a few big paper-cutout dots. Replaces bare paper with depth.
class GameBackdrop extends StatelessWidget {
  final Color color;

  const GameBackdrop({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      double dot(int i) => 70.0 + 45.0 * ((i * 37) % 3);
      final spots = [
        Offset(w * 0.06, h * 0.14),
        Offset(w * 0.93, h * 0.20),
        Offset(w * 0.10, h * 0.86),
        Offset(w * 0.90, h * 0.82),
        Offset(w * 0.52, h * 0.05),
      ];
      return Stack(children: [
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.25,
              colors: [
                Color.lerp(AppColors.paper, color, 0.16)!,
                AppColors.paper,
              ],
            ),
          ),
        ),
        for (var i = 0; i < spots.length; i++)
          Positioned(
            left: spots[i].dx - dot(i) / 2,
            top: spots[i].dy - dot(i) / 2,
            child: Container(
              width: dot(i),
              height: dot(i),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: i.isEven ? 0.07 : 0.045),
              ),
            ),
          ),
      ]);
    });
  }
}

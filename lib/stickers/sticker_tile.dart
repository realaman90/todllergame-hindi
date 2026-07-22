import 'package:flutter/material.dart';
import '../juice/juice.dart';
import '../widgets/widgets.dart';

/// A sticker tile: art clipped to a rounded-rect paper sticker.
class StickerTile extends StatelessWidget {
  final String imagePath;
  final String wordHi;
  final Color color;
  final Color deepColor;
  final double size;
  final VoidCallback? onTap;

  const StickerTile({
    super.key,
    required this.imagePath,
    required this.wordHi,
    required this.color,
    required this.deepColor,
    this.size = 80,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tile = ArtTile(
      imagePath: imagePath,
      wordHi: wordHi,
      color: color,
      deepColor: deepColor,
      size: size,
      showLabel: false,
    );

    return TapBounce(
      onTap: onTap,
      child: tile,
    );
  }
}

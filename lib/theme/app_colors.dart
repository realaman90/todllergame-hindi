import 'package:flutter/material.dart';

/// Mockup v1.1 style guide tokens.
abstract final class AppColors {
  // Neutrals
  static const Color paper = Color(0xFFFBF3E6);
  static const Color paper2 = Color(0xFFF1E3C9);
  static const Color ink = Color(0xFF3B2A1C);

  // Marigold
  static const Color marigold = Color(0xFFF2871F);
  static const Color marigoldDeep = Color(0xFFC4680F);

  // Peacock
  static const Color peacock = Color(0xFF146F69);
  static const Color peacockDeep = Color(0xFF0D4F4A);

  // Mehndi
  static const Color mehndi = Color(0xFF5C8A3A);
  static const Color mehndiDeep = Color(0xFF3F6427);

  // Kumkum
  static const Color kumkum = Color(0xFFE1516B);
  static const Color kumkumDeep = Color(0xFFB93752);

  static Color forTheme(String theme) => switch (theme) {
        'marigold' => marigold,
        'peacock' => peacock,
        'mehndi' => mehndi,
        'kumkum' => kumkum,
        _ => mehndi,
      };

  static Color deepFor(String theme) => switch (theme) {
        'marigold' => marigoldDeep,
        'peacock' => peacockDeep,
        'mehndi' => mehndiDeep,
        'kumkum' => kumkumDeep,
        _ => mehndiDeep,
      };
}

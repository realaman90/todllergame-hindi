import 'package:flutter/material.dart';

/// Text style tokens derived from the v1.1 mockup type system.
///
/// - Baloo2 (variable) for Hindi display text and titles.
/// - Hind for transliteration and supporting text.
abstract final class AppTextStyles {
  static TextStyle _baloo(double size, double weight) => TextStyle(
        fontFamily: 'Baloo2',
        fontSize: size,
        height: 1.1,
        fontVariations: [FontVariation('wght', weight)],
      );

  static TextStyle _hind(double size, FontWeight weight) => TextStyle(
        fontFamily: 'Hind',
        fontSize: size,
        fontWeight: weight,
      );

  static TextStyle get wordCardHi => _baloo(56, 700);

  static TextStyle get wordCardTranslit => _hind(24, FontWeight.w400);

  static TextStyle get wordCardGloss => _hind(22, FontWeight.w400);

  static TextStyle get sceneTitle => _baloo(36, 700);

  static TextStyle get objectLabel => _baloo(18, 600);

  static TextStyle get homeTitle => _baloo(42, 800);

  static TextStyle get cardLabel => _baloo(28, 700);
}

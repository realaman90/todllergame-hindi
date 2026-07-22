import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App-wide Material theme derived from the v1.1 style guide.
abstract final class AppTheme {
  static ThemeData light() {
    final base = ThemeData.from(
      colorScheme: const ColorScheme.light(
        primary: AppColors.mehndi,
        onPrimary: AppColors.paper,
        secondary: AppColors.peacock,
        onSecondary: AppColors.paper,
        surface: AppColors.paper,
        onSurface: AppColors.ink,
        error: AppColors.kumkum,
        onError: AppColors.paper,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.paper,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper2,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}

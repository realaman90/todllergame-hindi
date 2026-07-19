import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Toddler-sized circular paper-style back button.
///
/// Minimum 56 pt hit area, large icon, no text.
class ToddlerBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const ToddlerBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed ?? () => Navigator.of(context).maybePop(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 56,
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.paper2,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.arrow_back_rounded,
          color: AppColors.ink,
          size: 32,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Soft fade + scale route transition for scene/wall navigation.
///
/// Visible enough that a child notices the scene changing, but still soft
/// and calm for toddler pacing.
class FadeScaleRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  FadeScaleRoute({required this.child, super.settings})
      : super(
          transitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curve),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.88, end: 1.0).animate(curve),
                child: child,
              ),
            );
          },
        );
}

import 'package:flutter/material.dart';

/// Soft fade + scale route transition for scene/wall navigation.
class FadeScaleRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  FadeScaleRoute({required this.child, super.settings})
      : super(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curve,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1.0).animate(curve),
                child: child,
              ),
            );
          },
        );
}

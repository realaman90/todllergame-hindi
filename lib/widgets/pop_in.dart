import 'package:flutter/material.dart';

/// One-shot springy entrance: the child scales 0 → 1 with a friendly
/// overshoot after [delayMs]. Plain Tween, so the overshooting curve is
/// safe (TweenSequences must never use overshooting curves — see the
/// 2026-07-20 crash). Use staggered delays so groups of tiles pop in
/// one after another instead of just appearing.
class PopIn extends StatefulWidget {
  final int delayMs;
  final Widget child;

  const PopIn({super.key, this.delayMs = 0, required this.child});

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

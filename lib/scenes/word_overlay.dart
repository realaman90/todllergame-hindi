import 'package:flutter/material.dart';
import '../audio/audio.dart';
import '../content/content.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

/// Modal-free overlay shown when a scene object is tapped.
///
/// Entrance: scales up from the tapped object's location while the scrim
/// fades in. Tap the art again to play the slow repeat take; tap anywhere
/// else (card body or scrim) dismisses the overlay.
class WordOverlay extends StatefulWidget {
  final Scene scene;
  final SceneObject object;
  final AudioService audio;
  final String language;
  final VoidCallback onDismiss;
  final Rect? sourceRect;

  const WordOverlay({
    super.key,
    required this.scene,
    required this.object,
    required this.audio,
    required this.language,
    required this.onDismiss,
    this.sourceRect,
  });

  @override
  State<WordOverlay> createState() => _WordOverlayState();
}

class _WordOverlayState extends State<WordOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenCenter = MediaQuery.sizeOf(context).center(Offset.zero);
    final startCenter = widget.sourceRect?.center ?? screenCenter;
    final startOffset = startCenter - screenCenter;

    _offsetAnimation = Tween<Offset>(
      begin: startOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = AppColors.forTheme(widget.scene.theme);
    final deepColor = AppColors.deepFor(widget.scene.theme);

    return GestureDetector(
      onTap: widget.onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Container(
              color: Colors.black.withValues(alpha: 0.35 * _fadeAnimation.value),
              alignment: Alignment.center,
              child: child,
            );
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: _offsetAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: themeColor, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: deepColor.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OverlayArt(
                    imagePath: 'assets/art/${widget.object.art}',
                    wordHi: widget.object.wordHi,
                    themeColor: themeColor,
                    deepColor: deepColor,
                    audio: widget.audio,
                    sceneId: widget.scene.id,
                    slug: widget.object.slug,
                    language: widget.language,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.object.wordHi,
                    style: AppTextStyles.wordCardHi.copyWith(color: AppColors.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.object.translit,
                    style: AppTextStyles.wordCardTranslit
                        .copyWith(color: deepColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.object.glossEn,
                    style: AppTextStyles.wordCardGloss
                        .copyWith(color: AppColors.ink.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouncing art inside the word overlay.
class _OverlayArt extends StatefulWidget {
  final String imagePath;
  final String wordHi;
  final Color themeColor;
  final Color deepColor;
  final AudioService audio;
  final String sceneId;
  final String slug;
  final String language;

  const _OverlayArt({
    required this.imagePath,
    required this.wordHi,
    required this.themeColor,
    required this.deepColor,
    required this.audio,
    required this.sceneId,
    required this.slug,
    required this.language,
  });

  @override
  State<_OverlayArt> createState() => _OverlayArtState();
}

class _OverlayArtState extends State<_OverlayArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  void _handleTap() {
    _controller.forward(from: 0.0);
    widget.audio.playSfx('tap_pop');
    widget.audio.playWord(
      widget.sceneId,
      widget.slug,
      language: widget.language,
      slow: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(scale: _animation.value, child: child);
        },
        child: ArtTile(
          imagePath: widget.imagePath,
          wordHi: widget.wordHi,
          color: widget.themeColor,
          deepColor: widget.deepColor,
          size: 160,
          showLabel: false,
        ),
      ),
    );
  }
}

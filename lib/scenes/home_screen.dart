import 'dart:math';

import 'package:flutter/material.dart';
import '../audio/audio.dart';
import '../stickers/stickers.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

/// Scene-select home screen.
///
/// Mithu greeter on the left, three doorway cards on the right, and a
/// sticker-wall entry. Everything fits horizontally on small landscape
/// phones without scrolling.
class HomeScreen extends StatefulWidget {
  final StickerService stickerService;
  final AudioService audio;

  const HomeScreen({
    super.key,
    required this.stickerService,
    required this.audio,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static bool _greetingPlayed = false;

  @override
  void initState() {
    super.initState();
    widget.stickerService.addListener(_onStickersChanged);
    widget.audio.playAmbient('assets/audio/music/theme.mp3');
    if (!_greetingPlayed) {
      _greetingPlayed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.audio.playHost('mithu_greeting');
      });
    }
  }

  @override
  void dispose() {
    widget.stickerService.removeListener(_onStickersChanged);
    widget.audio.stopAmbient();
    super.dispose();
  }

  void _onStickersChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _MithuBlock(audio: widget.audio),
              const SizedBox(width: 32),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DoorwayCard(
                        sceneId: 'house',
                        titleHi: 'घर',
                        titleTranslit: 'Ghar',
                        color: AppColors.marigold,
                        deepColor: AppColors.marigoldDeep,
                        onTap: () => Navigator.of(context).pushNamed('/scene/house'),
                      ),
                      const SizedBox(width: 14),
                      _DoorwayCard(
                        sceneId: 'farm',
                        titleHi: 'बगीचा',
                        titleTranslit: 'Bageecha',
                        color: AppColors.mehndi,
                        deepColor: AppColors.mehndiDeep,
                        onTap: () => Navigator.of(context).pushNamed('/scene/farm'),
                      ),
                      const SizedBox(width: 14),
                      _DoorwayCard(
                        sceneId: 'family',
                        titleHi: 'परिवार',
                        titleTranslit: 'Parivaar',
                        color: AppColors.kumkum,
                        deepColor: AppColors.kumkumDeep,
                        onTap: () => Navigator.of(context).pushNamed('/scene/family'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _StickerWallEntry(
                    count: widget.stickerService.count,
                    onTap: () => Navigator.of(context).pushNamed('/stickers'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MithuBlock extends StatefulWidget {
  final AudioService audio;

  const _MithuBlock({required this.audio});

  @override
  State<_MithuBlock> createState() => _MithuBlockState();
}

class _MithuBlockState extends State<_MithuBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final bob = 4.0 * sin(_controller.value * 2 * 3.14159);
        final tilt = 0.04 * sin(_controller.value * 2 * 3.14159 + 1.0);
        return Transform.translate(
          offset: Offset(0, bob),
          child: Transform.rotate(angle: tilt, child: child),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: ListenableBuilder(
              listenable: widget.audio,
              builder: (context, child) {
                return MithuTalking(
                  isPlaying: widget.audio.isPlaying,
                  size: 160,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'चलो घर घूमें',
            style: AppTextStyles.homeTitle.copyWith(color: AppColors.peacock),
          ),
          const SizedBox(height: 2),
          Text(
            'Chalo Ghar Ghoome',
            style: AppTextStyles.wordCardTranslit
                .copyWith(color: AppColors.ink.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

class _DoorwayCard extends StatelessWidget {
  final String sceneId;
  final String titleHi;
  final String titleTranslit;
  final Color color;
  final Color deepColor;
  final VoidCallback onTap;

  const _DoorwayCard({
    required this.sceneId,
    required this.titleHi,
    required this.titleTranslit,
    required this.color,
    required this.deepColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 116,
        height: 132,
        decoration: BoxDecoration(
          color: AppColors.paper2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: deepColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: deepColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Image.asset(
                'assets/art/scenes/${sceneId}_thumb.png',
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            Container(
              color: color,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titleHi,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    titleTranslit,
                    style: AppTextStyles.wordCardTranslit.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickerWallEntry extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _StickerWallEntry({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 160,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.paper2,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.marigoldDeep, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.marigoldDeep.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.collections,
              color: AppColors.marigold,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              '$count',
              style: AppTextStyles.cardLabel.copyWith(
                color: AppColors.ink,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

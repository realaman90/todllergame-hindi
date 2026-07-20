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

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  static bool _greetingPlayed = false;
  bool _introPlaying = false;
  late final AnimationController _pulseController;
  late final AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    widget.stickerService.addListener(_onStickersChanged);
    widget.audio.addListener(_onAudioChanged);
    widget.audio.playAmbient('assets/audio/music/theme.mp3');
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 3400),
      vsync: this,
    )..repeat();
    _startHomeAudio();
  }

  Future<void> _startHomeAudio() async {
    await widget.stickerService.loaded;
    if (!mounted) return;
    if (!widget.stickerService.hasSeenIntro) {
      await widget.stickerService.markIntroSeen();
      if (!mounted) return;
      setState(() => _introPlaying = true);
      await widget.audio.playHostSequence([
        'mithu_intro_name',
        'mithu_intro_play',
        'mithu_intro_choose',
      ]);
      if (mounted && _introPlaying) {
        setState(() => _introPlaying = false);
      }
    } else if (!_greetingPlayed) {
      _greetingPlayed = true;
      widget.audio.playHost('mithu_greeting');
    }
  }

  void _skipIntro() {
    if (!_introPlaying) return;
    widget.audio.stop();
    setState(() => _introPlaying = false);
  }

  void _onAudioChanged() {
    final isChoose =
        widget.audio.currentVoicePath?.endsWith('mithu_intro_choose.mp3') ??
            false;
    if (isChoose && !_pulseController.isAnimating) {
      _pulseController.repeat();
    } else if (!isChoose && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _breathingController.dispose();
    widget.audio.removeListener(_onAudioChanged);
    widget.stickerService.removeListener(_onStickersChanged);
    widget.audio.stopAmbient();
    super.dispose();
  }

  void _onStickersChanged() {
    if (mounted) setState(() {});
  }

  Widget _buildAnimatedCard(int index, Widget child) {
    return AnimatedBuilder(
      animation: _breathingController,
      builder: (context, child) {
        final breathPhase = _breathingController.value * 2 * pi + index * 1.3;
        final breathScale = 1.0 + 0.02 * sin(breathPhase);
        return Transform.scale(
          scale: breathScale,
          child: child,
        );
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          if (!_pulseController.isAnimating) return child!;
          final t = (_pulseController.value + index * 0.25) % 1.0;
          final pulseScale = 1.0 + 0.05 * sin(t * 2 * pi);
          return Transform.scale(scale: pulseScale, child: child);
        },
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MithuBlock(audio: widget.audio),
          ],
        ),
        const SizedBox(width: 32),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAnimatedCard(
                  0,
                  DoorwayCard(
                    sceneId: 'farm',
                    titleHi: 'सीखो',
                    titleTranslit: 'Seekho',
                    color: AppColors.marigold,
                    deepColor: AppColors.marigoldDeep,
                    width: 168,
                    height: 196,
                    onTap: () => Navigator.of(context).pushNamed('/scenes'),
                  ),
                ),
                const SizedBox(width: 26),
                _buildAnimatedCard(
                  1,
                  DoorwayCard(
                    sceneId: 'games',
                    titleHi: 'खेलो',
                    titleTranslit: 'Khelo',
                    color: AppColors.peacock,
                    deepColor: AppColors.peacockDeep,
                    width: 168,
                    height: 196,
                    onTap: () => Navigator.of(context).pushNamed('/play'),
                  ),
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
    );

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Center(
          child: _introPlaying
              ? GestureDetector(
                  onTap: _skipIntro,
                  behavior: HitTestBehavior.opaque,
                  child: AbsorbPointer(child: content),
                )
              : content,
        ),
      ),
    );
  }
}

class _MithuBlock extends StatelessWidget {
  final AudioService audio;

  const _MithuBlock({required this.audio});

  @override
  Widget build(BuildContext context) {
    return Column(
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
            listenable: audio,
            builder: (context, child) {
              return MithuTalking(
                isPlaying: audio.isPlaying,
                voicePath: audio.currentVoicePath,
                size: 160,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Mithu & Friends',
          style: AppTextStyles.homeTitle.copyWith(color: AppColors.peacock),
        ),
        const SizedBox(height: 2),
        Text(
          'बोलो! खेलो!',
          style: AppTextStyles.wordCardTranslit
              .copyWith(color: AppColors.ink.withValues(alpha: 0.7)),
        ),
      ],
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

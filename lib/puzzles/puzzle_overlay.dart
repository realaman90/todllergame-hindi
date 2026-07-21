import 'dart:math';
import 'package:flutter/material.dart';
import '../audio/audio.dart';
import '../content/content.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import 'puzzle_card.dart';

/// Find-it puzzle overlay.
///
/// Shows a prompt card that speaks the target word, plus four candidate
/// cards. Wrong taps wobble; correct taps celebrate and report their
/// bounds. Tapping outside the puzzle card dismisses the puzzle.
class PuzzleOverlay extends StatefulWidget {
  final Scene scene;
  final Puzzle puzzle;
  final AudioService audio;
  final String language;
  final VoidCallback onClose;
  final void Function(String slug, Rect sourceRect) onSolved;

  const PuzzleOverlay({
    super.key,
    required this.scene,
    required this.puzzle,
    required this.audio,
    required this.language,
    required this.onClose,
    required this.onSolved,
  });

  @override
  State<PuzzleOverlay> createState() => _PuzzleOverlayState();
}

class _PuzzleOverlayState extends State<PuzzleOverlay> {
  late final List<SceneObject> _candidates;

  @override
  void initState() {
    super.initState();
    final objects = widget.scene.objects;
    final target = objects.firstWhere((o) => o.slug == widget.puzzle.ask);
    final decoys = widget.puzzle.decoys
        .map((slug) => objects.firstWhere((o) => o.slug == slug))
        .toList();
    _candidates = [target, ...decoys];
    _candidates.shuffle(Random());

    _playPrompt();
  }

  void _playPrompt() {
    widget.audio.playPromptSequence(
      widget.scene.id,
      widget.puzzle.ask,
      language: widget.language,
    );
  }

  Future<void> _handleSolved(SceneObject object, Rect sourceRect) async {
    await widget.audio.playPraise(
      sceneId: widget.scene.id,
      slug: object.slug,
      language: widget.language,
    );
    if (mounted) widget.onSolved(object.slug, sourceRect);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = AppColors.forTheme(widget.scene.theme);
    final deepColor = AppColors.deepFor(widget.scene.theme);
    final target = widget.scene.objects
        .firstWhere((o) => o.slug == widget.puzzle.ask);

    return GestureDetector(
      onTap: widget.onClose,
      behavior: HitTestBehavior.opaque,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 360,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: themeColor, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: deepColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PromptCard(
                    object: target,
                    themeColor: themeColor,
                    deepColor: deepColor,
                    audio: widget.audio,
                    onTap: _playPrompt,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: _candidates.map((object) {
                      return PuzzleCard(
                        scene: widget.scene,
                        object: object,
                        isTarget: object.slug == widget.puzzle.ask,
                        audio: widget.audio,
                        onSolved: (rect) => _handleSolved(object, rect),
                        onWrong: () {},
                      );
                    }).toList(),
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

class _PromptCard extends StatelessWidget {
  final SceneObject object;
  final Color themeColor;
  final Color deepColor;
  final AudioService audio;
  final VoidCallback onTap;

  const _PromptCard({
    required this.object,
    required this.themeColor,
    required this.deepColor,
    required this.audio,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.paper2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: themeColor, width: 3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: themeColor,
                shape: BoxShape.circle,
                border: Border.all(color: deepColor, width: 2),
              ),
              alignment: Alignment.center,
              child: ListenableBuilder(
                listenable: audio,
                builder: (context, child) {
                  return MithuTalking(
                    isPlaying: audio.isPlaying,
                    voicePath: audio.currentVoicePath,
                    size: 40,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Text(
              object.wordHi,
              style: AppTextStyles.sceneTitle.copyWith(
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.volume_up_rounded,
              color: deepColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

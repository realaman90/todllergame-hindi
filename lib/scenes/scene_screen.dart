import 'dart:math';

import 'package:flutter/material.dart';
import '../audio/audio.dart';
import '../content/content.dart';
import '../puzzles/puzzles.dart';
import '../stickers/stickers.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import 'tappable_object.dart';
import 'word_overlay.dart';

/// Displays one scene: a wide diorama of tappable objects.
class SceneScreen extends StatefulWidget {
  final String sceneId;
  final AudioService audio;
  final StickerService stickerService;

  const SceneScreen({
    super.key,
    required this.sceneId,
    required this.audio,
    required this.stickerService,
  });

  @override
  State<SceneScreen> createState() => _SceneScreenState();
}

class _SceneScreenState extends State<SceneScreen> {
  static const _language = 'hi';

  final GlobalKey _pillKey = GlobalKey();
  final Map<String, GlobalKey> _objectKeys = {};

  late final Future<Scene> _sceneFuture;
  SceneObject? _activeObject;
  Rect? _activeSourceRect;
  String? _pendingSlug;
  GlobalKey? _pendingSourceKey;

  String? _earnedSlug;
  Rect? _earnedSourceRect;
  Rect? _earnedTargetRect;

  Puzzle? _activePuzzle;

  @override
  void initState() {
    super.initState();
    _sceneFuture = const SceneLoader().load(widget.sceneId, language: _language);
    _sceneFuture.then((scene) {
      if (mounted) {
        widget.audio.playAmbient('assets/audio/${scene.ambientAudio}');
      }
    });
    widget.stickerService.addListener(_onStickersChanged);
  }

  @override
  void dispose() {
    widget.audio.stop();
    widget.audio.stopAmbient();
    widget.stickerService.removeListener(_onStickersChanged);
    super.dispose();
  }

  void _onStickersChanged() {
    if (mounted) setState(() {});
  }

  void _ensureKeys(Scene scene) {
    if (_objectKeys.isNotEmpty) return;
    for (final object in scene.objects) {
      _objectKeys[object.slug] = GlobalKey();
    }
  }

  void _showObject(SceneObject object) {
    if (!widget.stickerService.has(object.slug)) {
      _pendingSlug = object.slug;
      _pendingSourceKey = _objectKeys[object.slug];
    }
    setState(() {
      _activeObject = object;
      _activeSourceRect = _rectFromKey(_objectKeys[object.slug]);
    });
  }

  void _dismissOverlay() {
    final pending = _pendingSlug;
    final pendingKey = _pendingSourceKey;

    setState(() {
      _activeObject = null;
      _activeSourceRect = null;
      _pendingSlug = null;
      _pendingSourceKey = null;
    });

    if (pending != null) {
      widget.stickerService.discover(pending);
      setState(() {
        _earnedSlug = pending;
        _earnedSourceRect = _rectFromKey(pendingKey);
        _earnedTargetRect = _rectFromKey(_pillKey);
      });
    }
  }

  void _onEarnedDismiss() {
    setState(() {
      _earnedSlug = null;
      _earnedSourceRect = null;
      _earnedTargetRect = null;
    });
  }

  void _openPuzzle(Scene scene) {
    if (scene.puzzles.isEmpty) return;
    final puzzle = scene.puzzles[Random().nextInt(scene.puzzles.length)];
    setState(() => _activePuzzle = puzzle);
  }

  void _closePuzzle() {
    setState(() => _activePuzzle = null);
  }

  void _onPuzzleSolved(String slug, Rect sourceRect) {
    final puzzleSlug = 'puzzle:$slug';
    widget.stickerService.discover(puzzleSlug);
    setState(() {
      _activePuzzle = null;
      _earnedSlug = puzzleSlug;
      _earnedSourceRect = sourceRect;
      _earnedTargetRect = _rectFromKey(_pillKey);
    });
  }

  void _openStickerWall() {
    Navigator.of(context).pushNamed('/stickers');
  }

  Rect? _rectFromKey(GlobalKey? key) {
    final box = key?.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Scene>(
      future: _sceneFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint(
            'Scene load failed: ${snapshot.error}\n${snapshot.stackTrace}',
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pop();
          });
          return Container(color: AppColors.paper);
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.paper,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final scene = snapshot.data!;
        _ensureKeys(scene);
        final themeColor = AppColors.forTheme(scene.theme);
        final deepColor = AppColors.deepFor(scene.theme);

        return Stack(
          children: [
            Scaffold(
              backgroundColor: AppColors.paper,
              appBar: AppBar(
                title: Text(scene.titleHi, style: AppTextStyles.sceneTitle),
                leading: ToddlerBackButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                automaticallyImplyLeading: false,
                leadingWidth: 72,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: StickerCountPill(
                      key: _pillKey,
                      count: widget.stickerService.count,
                      onTap: _openStickerWall,
                    ),
                  ),
                ],
              ),
              body: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      _Background(scene: scene),
                      ...scene.objects.map((object) {
                        final x = object.pos.dx * constraints.maxWidth;
                        final y = object.pos.dy * constraints.maxHeight;
                        final size = 100.0 * object.scale;
                        return Positioned(
                          left: x - size / 2,
                          top: y - size / 2,
                          child: Container(
                            key: _objectKeys[object.slug],
                            child: TappableObject(
                              scene: scene,
                              object: object,
                              audio: widget.audio,
                              language: _language,
                              onTap: () => _showObject(object),
                            ),
                          ),
                        );
                      }),
                      if (scene.puzzles.isNotEmpty)
                        Positioned(
                          right: 16,
                          top: 16,
                          child: _PuzzleDoor(
                            color: themeColor,
                            deepColor: deepColor,
                            onTap: () => _openPuzzle(scene),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            if (_activeObject != null)
              WordOverlay(
                scene: scene,
                object: _activeObject!,
                audio: widget.audio,
                language: _language,
                onDismiss: _dismissOverlay,
                sourceRect: _activeSourceRect,
              ),
            if (_activePuzzle != null)
              PuzzleOverlay(
                scene: scene,
                puzzle: _activePuzzle!,
                audio: widget.audio,
                language: _language,
                onClose: _closePuzzle,
                onSolved: _onPuzzleSolved,
              ),
            if (_earnedSlug != null)
              _buildEarnedOverlay(scene),
          ],
        );
      },
    );
  }

  Widget _buildEarnedOverlay(Scene scene) {
    final slug = _earnedSlug!;
    final baseSlug = slug.startsWith('puzzle:') ? slug.substring(7) : slug;
    final object = scene.objects.firstWhere((o) => o.slug == baseSlug);
    final themeColor = AppColors.forTheme(scene.theme);
    final deepColor = AppColors.deepFor(scene.theme);

    return StickerEarnedOverlay(
      sourceRect: _earnedSourceRect,
      targetRect: _earnedTargetRect,
      sticker: StickerTile(
        imagePath: 'assets/art/${object.art}',
        wordHi: object.wordHi,
        color: themeColor,
        deepColor: deepColor,
        size: 72,
      ),
      audio: widget.audio,
      onDismiss: _onEarnedDismiss,
    );
  }
}

class _PuzzleDoor extends StatelessWidget {
  final Color color;
  final Color deepColor;
  final VoidCallback onTap;

  const _PuzzleDoor({
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
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: deepColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: deepColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.auto_awesome,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

class _Background extends StatelessWidget {
  final Scene scene;

  const _Background({required this.scene});

  @override
  Widget build(BuildContext context) {
    final themeColor = AppColors.forTheme(scene.theme);
    return Image.asset(
      'assets/art/${scene.background}',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppColors.paper2,
          alignment: Alignment.center,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: themeColor.withValues(alpha: 0.15),
          ),
        );
      },
    );
  }
}

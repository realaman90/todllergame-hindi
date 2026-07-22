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
///
/// M3 object-subset rotation: at most 6 objects are shown at once,
/// laid out on a jittered grid with guaranteed no overlaps. New objects
/// animate in when a discovered object rotates out.
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
  static const _maxVisible = 6;

  final GlobalKey _pillKey = GlobalKey();

  late final Future<Scene> _sceneFuture;
  Scene? _scene;
  List<Offset> _slots = [];
  List<SceneObject> _visibleObjects = [];
  final Set<String> _visibleSlugs = {};
  final Set<String> _shownSlugs = {};
  final Set<String> _outgoingSlugs = {};
  final Map<String, int> _slotAssignment = {};
  final Map<String, int> _instanceGeneration = {};

  SceneObject? _activeObject;
  Rect? _activeSourceRect;
  String? _pendingSlug;
  Rect? _pendingSourceRect;

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
        widget.audio.playHost('mithu_welcome_${scene.id}');
      }
    });
    widget.stickerService.addListener(_onStickersChanged);
  }

  @override
  void dispose() {
    widget.audio.stop();
    // Hand the Home theme back instead of leaving silence — Home only
    // starts it in initState, so stopping here muted Home for the rest
    // of the session (Kimi review: loudest sub-premium signal).
    widget.audio.playAmbient('assets/audio/music/theme.mp3');
    widget.stickerService.removeListener(_onStickersChanged);
    super.dispose();
  }

  void _onStickersChanged() {
    if (mounted) setState(() {});
  }

  void _initializeIfNeeded(Scene scene) {
    if (_scene != null) return;
    _scene = scene;
    _slots = _computeSlots(scene.id);

    final undiscovered = scene.objects
        .where((o) => !widget.stickerService.has(o.slug))
        .toList();
    final discovered = scene.objects
        .where((o) => widget.stickerService.has(o.slug))
        .toList();

    // Deterministic but varied ordering.
    undiscovered.shuffle(Random(scene.id.hashCode));
    discovered.shuffle(Random(scene.id.hashCode + 1));

    _visibleObjects = [
      ...undiscovered,
      ...discovered,
    ].take(_maxVisible).toList();

    for (var i = 0; i < _visibleObjects.length; i++) {
      final slug = _visibleObjects[i].slug;
      _visibleSlugs.add(slug);
      _shownSlugs.add(slug);
      _slotAssignment[slug] = i;
      _instanceGeneration[slug] = (_instanceGeneration[slug] ?? 0) + 1;
    }
  }

  List<Offset> _computeSlots(String seed) {
    final random = Random(seed.hashCode);
    const base = [
      Offset(0.18, 0.30),
      Offset(0.50, 0.30),
      Offset(0.82, 0.30),
      Offset(0.18, 0.70),
      Offset(0.50, 0.70),
      Offset(0.82, 0.70),
    ];
    return base.map((center) {
      final jitter = Offset(
        random.nextDouble() * 0.06 - 0.03,
        random.nextDouble() * 0.06 - 0.03,
      );
      return Offset(
        (center.dx + jitter.dx).clamp(0.12, 0.88),
        (center.dy + jitter.dy).clamp(0.24, 0.76),
      );
    }).toList();
  }

  void _showObject(SceneObject object, Rect sourceRect) {
    if (!widget.stickerService.has(object.slug)) {
      _pendingSlug = object.slug;
      _pendingSourceRect = sourceRect;
    }
    setState(() {
      _activeObject = object;
      _activeSourceRect = sourceRect;
    });
  }

  void _dismissOverlay() {
    final pending = _pendingSlug;
    final pendingRect = _pendingSourceRect;

    setState(() {
      _activeObject = null;
      _activeSourceRect = null;
      _pendingSlug = null;
      _pendingSourceRect = null;
    });

    if (pending != null) {
      widget.stickerService.discover(pending);
      setState(() {
        _earnedSlug = pending;
        _earnedSourceRect = pendingRect;
        _earnedTargetRect = _rectFromKey(_pillKey);
      });
    }
  }

  void _onEarnedDismiss() {
    final earned = _earnedSlug;
    setState(() {
      _earnedSlug = null;
      _earnedSourceRect = null;
      _earnedTargetRect = null;
    });

    if (earned != null && !earned.startsWith('puzzle:')) {
      _rotateAfterDiscovery(earned);
    }
  }

  void _rotateAfterDiscovery(String slug) {
    final scene = _scene;
    if (scene == null) return;
    final slot = _slotAssignment[slug];
    if (slot == null) return;

    // Do not refill with anything that is still in the tree (visible or
    // animating out). Reusing the same GlobalKey while it is still mounted
    // triggers a framework duplicate-key assertion.
    final candidates = scene.objects
        .where(
          (o) =>
              !_visibleSlugs.contains(o.slug) && !_outgoingSlugs.contains(o.slug),
        )
        .toList();
    if (candidates.isEmpty) return;

    // Prefer undiscovered, then discovered-but-not-yet-shown.
    candidates.sort((a, b) {
      final aDisc = widget.stickerService.has(a.slug) ? 1 : 0;
      final bDisc = widget.stickerService.has(b.slug) ? 1 : 0;
      if (aDisc != bDisc) return aDisc - bDisc;
      return a.slug.compareTo(b.slug);
    });

    final replacement = candidates.first;
    // Two readable beats instead of a same-frame morph (founder: "the
    // refresh feels like a bug"): the discovered object leaves, the slot
    // rests empty for a breath, then the newcomer pops in.
    setState(() {
      _visibleObjects.removeWhere((o) => o.slug == slug);
      _visibleSlugs.remove(slug);
      _slotAssignment.remove(slug);
      _outgoingSlugs.add(slug);
    });
    Future.delayed(const Duration(milliseconds: 850), () {
      if (!mounted || _visibleSlugs.contains(replacement.slug)) return;
      setState(() {
        _visibleObjects.add(replacement);
        _visibleSlugs.add(replacement.slug);
        _shownSlugs.add(replacement.slug);
        _slotAssignment[replacement.slug] = slot;
        _instanceGeneration[replacement.slug] =
            (_instanceGeneration[replacement.slug] ?? 0) + 1;
      });
    });
  }

  void _onObjectAnimationComplete(String slug) {
    // Defer the setState to the next frame so it never runs while this
    // subtree is being deactivated or disposed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _outgoingSlugs.remove(slug);
        });
      }
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

        _initializeIfNeeded(scene);

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
                      ..._visibleObjects.map((object) {
                        final slotIndex = _slotAssignment[object.slug];
                        if (slotIndex == null) {
                          return const SizedBox.shrink();
                        }
                        final slot = _slots[slotIndex];
                        // Center on the VISUAL size (ArtTile scales by
                        // uiScale internally) — unscaled math mis-centered
                        // and edge-clipped every object on iPad.
                        final size =
                            100.0 * object.scale * uiScale(context);
                        final x = slot.dx * constraints.maxWidth;
                        final y = slot.dy * constraints.maxHeight;
                        final instanceId = _instanceGeneration[object.slug] ?? 0;
                        return Positioned(
                          left: x - size / 2,
                          top: y - size / 2,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: Tween<double>(begin: 0.6, end: 1.0)
                                      .animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: _AnimatedObject(
                              key: ValueKey('${object.slug}-$instanceId'),
                              slug: object.slug,
                              onDispose: _onObjectAnimationComplete,
                              child: TappableObject(
                                scene: scene,
                                object: object,
                                audio: widget.audio,
                                language: _language,
                                onTap: (rect) => _showObject(object, rect),
                              ),
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

/// Wrapper that reports when its underlying element is disposed.
///
/// AnimatedSwitcher keeps the outgoing child in the tree for the exit
/// animation; this lets the scene know exactly when that child is gone so
/// the same slug can safely re-enter the refill pool.
class _AnimatedObject extends StatefulWidget {
  final String slug;
  final Widget child;
  final ValueChanged<String> onDispose;

  const _AnimatedObject({
    super.key,
    required this.slug,
    required this.onDispose,
    required this.child,
  });

  @override
  State<_AnimatedObject> createState() => _AnimatedObjectState();
}

class _AnimatedObjectState extends State<_AnimatedObject> {
  @override
  void dispose() {
    widget.onDispose(widget.slug);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
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

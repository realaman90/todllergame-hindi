import 'dart:math';

import 'package:flutter/material.dart';
import '../audio/audio.dart';
import '../content/content.dart';
import '../stickers/stickers.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import 'activities.dart';

/// Activity carousel shell.
///
/// Builds a short playlist of activity rounds, loads each scene's vocab,
/// and hosts the game UI. On complete it awards a namespaced activity
/// sticker, plays Mithu praise, shows the earned-sticker moment, then
/// auto-advances. A large paper-style skip arrow is always available, and
/// the back button exits to Home.
class CarouselScreen extends StatefulWidget {
  final StickerService stickerService;
  final AudioService audio;

  const CarouselScreen({
    super.key,
    required this.stickerService,
    required this.audio,
  });

  @override
  State<CarouselScreen> createState() => _CarouselScreenState();
}

class _CarouselScreenState extends State<CarouselScreen> {
  static const _language = 'hi';

  late final List<_Round> _playlist;
  late Future<_RoundState> _roundFuture;
  int _index = 0;
  bool _completing = false;
  String? _earnedSlug;

  @override
  void initState() {
    super.initState();
    _playlist = _buildPlaylist();
    _roundFuture = _loadRound(_playlist[_index]);
  }

  List<_Round> _buildPlaylist() {
    // Interleave scenes AND formats: shuffled scenes × alternating
    // activities, so neither a scene nor a format repeats back-to-back.
    final sceneIds = ['house', 'farm', 'family'];
    sceneIds.shuffle(Random());
    // linematch leads: newest game greets the child (and founder) first.
    const formats = ['icecream', 'linematch', 'pattern', 'oddone', 'bigsmall', 'pairs'];
    final rounds = [
      for (var round = 0; round < formats.length; round++)
        for (var i = 0; i < sceneIds.length; i++)
          _Round(
            sceneId: sceneIds[i],
            activityId: formats[(i + round) % formats.length],
          ),
    ];
    // Breathers after every 3rd game, ALTERNATING types (founder
    // cadence): counting balloons, then soap bubbles, then balloons…
    final woven = <_Round>[];
    var breatherIndex = 0;
    for (var i = 0; i < rounds.length; i++) {
      woven.add(rounds[i]);
      if ((i + 1) % 3 == 0) {
        woven.add(_Round(
          sceneId: rounds[i].sceneId,
          activityId: breatherIndex.isEven ? 'balloons' : 'bubbles',
        ));
        breatherIndex++;
      }
    }
    return woven;
  }

  Future<_RoundState> _loadRound(_Round round) async {
    final scene = await const SceneLoader().load(
      round.sceneId,
      language: _language,
    );
    final vocab = _selectVocab(scene);
    widget.audio.playAmbient('assets/audio/${scene.ambientAudio}');
    return _RoundState(scene: scene, vocab: vocab);
  }

  List<SceneObject> _selectVocab(Scene scene) {
    // Prefer discovered words (reinforcement), fill with undiscovered.
    final discovered = scene.objects
        .where((o) => widget.stickerService.has(o.slug))
        .toList();
    final undiscovered = scene.objects
        .where((o) => !widget.stickerService.has(o.slug))
        .toList();
    discovered.shuffle(Random(scene.id.hashCode));
    undiscovered.shuffle(Random(scene.id.hashCode + 1));
    return [...discovered, ...undiscovered].take(6).toList();
  }

  Future<void> _onComplete() async {
    if (_completing) return;
    _completing = true;
    final round = _playlist[_index];
    final slug = 'activity:${round.activityId}:${round.sceneId}';
    widget.stickerService.discover(slug);
    await widget.audio.playPraise();
    if (mounted) setState(() => _earnedSlug = slug);
  }

  void _onSkip() => _advance();

  void _onEarnedDismiss() {
    setState(() => _earnedSlug = null);
    _advance();
  }

  void _advance() {
    _completing = false;
    if (_index < _playlist.length - 1) {
      setState(() {
        _index++;
        _roundFuture = _loadRound(_playlist[_index]);
      });
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    widget.audio.stopAmbient();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final round = _playlist[_index];
    final activity = activityFor(round.activityId);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(activity.titleHi, style: AppTextStyles.sceneTitle),
        centerTitle: true,
        leading: ToddlerBackButton(
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        automaticallyImplyLeading: false,
        leadingWidth: 72,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: _SkipArrow(),
          ),
        ],
      ),
      body: FutureBuilder<_RoundState>(
        future: _roundFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Carousel load failed: ${snapshot.error}');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.of(context).pop();
            });
            return Container(color: AppColors.paper);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final state = snapshot.data!;
          final session = ActivitySession(
            scene: state.scene,
            vocab: state.vocab,
            audio: widget.audio,
            onComplete: _onComplete,
            onSkip: _onSkip,
          );

          final themeColor = AppColors.forTheme(state.scene.theme);
          return Stack(
            children: [
              Positioned.fill(child: GameBackdrop(color: themeColor)),
              // Rounds slide in from the right and fade — no hard swaps.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 480),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.12, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_index),
                  child: activity.build(context, session),
                ),
              ),
              if (_earnedSlug != null)
                _buildEarnedOverlay(state.scene, round.activityId),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEarnedOverlay(Scene scene, String activityId) {
    final themeColor = AppColors.forTheme(scene.theme);
    final deepColor = AppColors.deepFor(scene.theme);

    return StickerEarnedOverlay(
      sourceRect: null,
      targetRect: null,
      sticker: ActivityStickerTile(
        activityId: activityId,
        color: themeColor,
        deepColor: deepColor,
        size: 80,
      ),
      audio: widget.audio,
      onDismiss: _onEarnedDismiss,
    );
  }
}

class _Round {
  final String sceneId;
  final String activityId;

  const _Round({
    required this.sceneId,
    required this.activityId,
  });
}

class _RoundState {
  final Scene scene;
  final List<SceneObject> vocab;

  const _RoundState({
    required this.scene,
    required this.vocab,
  });
}

class _SkipArrow extends StatelessWidget {
  const _SkipArrow();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final state = context.findAncestorStateOfType<_CarouselScreenState>();
        state?._onSkip();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 56,
        height: 56,
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
        child: const Icon(
          Icons.arrow_forward_rounded,
          color: AppColors.ink,
          size: 32,
        ),
      ),
    );
  }
}

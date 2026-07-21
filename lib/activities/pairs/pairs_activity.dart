import 'dart:math';

import 'package:flutter/material.dart';
import '../../content/content.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../../juice/juice.dart';
import '../activity.dart';

/// जोड़ी मिलाओ (Pairs): 6 face-up cards forming 3 matching pairs.
///
/// Tap a card to hear its word and lift it. Tap its twin to match — both
/// pop, play the word again, and fly off. Tap a non-twin and the previous
/// selection simply settles while the new card lifts. No fail state.
class PairsActivity extends Activity {
  const PairsActivity();

  @override
  String get id => 'pairs';

  @override
  String get titleHi => 'जोड़ी मिलाओ';

  @override
  Widget build(BuildContext context, ActivitySession session) {
    return _PairsGame(session: session);
  }
}

class _PairsGame extends StatefulWidget {
  final ActivitySession session;

  const _PairsGame({required this.session});

  @override
  State<_PairsGame> createState() => _PairsGameState();
}

class _PairsGameState extends State<_PairsGame>
    with TickerProviderStateMixin {
  static const _language = 'hi';

  late final List<_Card> _cards;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    final objects = widget.session.vocab.take(3).toList();
    final pairs = <_Card>[
      for (final object in objects)
        _Card(object: object),
      for (final object in objects)
        _Card(object: object),
    ];
    pairs.shuffle(Random());
    _cards = pairs;
  }

  void _handleTap(int index) {
    final card = _cards[index];
    if (card.matched) return;

    widget.session.audio.playTapNote();
    widget.session.audio.playWord(
      widget.session.scene.id,
      card.object.slug,
      language: _language,
    );

    final selected = _selectedIndex;
    if (selected == null || selected == index) {
      setState(() => _selectedIndex = index);
      return;
    }

    final other = _cards[selected];
    if (other.object.slug == card.object.slug) {
      // Match: pop both and fly them off.
      setState(() {
        _cards[selected].matched = true;
        _cards[index].matched = true;
        _selectedIndex = null;
      });
      widget.session.audio.playSfx('ding_sticker');
      widget.session.audio.playWord(
        widget.session.scene.id,
        card.object.slug,
        language: _language,
      );
      _checkComplete();
    } else {
      // Non-twin: switch selection without any failure feedback.
      setState(() => _selectedIndex = index);
    }
  }

  void _checkComplete() {
    if (_cards.every((c) => c.matched)) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) widget.session.onComplete();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = AppColors.forTheme(widget.session.scene.theme);
    final deepColor = AppColors.deepFor(widget.session.scene.theme);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'जोड़ी मिलाओ',
            style: AppTextStyles.sceneTitle.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 360,
            height: 240,
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(_cards.length, (index) {
                final card = _cards[index];
                final isSelected = _selectedIndex == index && !card.matched;
                return PopIn(
                  delayMs: 80 * index,
                  child: IdleBreath(
                    phase: index * 1.3,
                    amplitude: 0.04,
                    child: _PairCard(
                      card: card,
                      isSelected: isSelected,
                      themeColor: themeColor,
                      deepColor: deepColor,
                      onTap: () => _handleTap(index),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card {
  final SceneObject object;
  bool matched = false;

  _Card({required this.object});
}

class _PairCard extends StatelessWidget {
  final _Card card;
  final bool isSelected;
  final Color themeColor;
  final Color deepColor;
  final VoidCallback onTap;

  const _PairCard({
    required this.card,
    required this.isSelected,
    required this.themeColor,
    required this.deepColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget tile = ArtTile(
      imagePath: 'assets/art/${card.object.art}',
      wordHi: card.object.wordHi,
      color: themeColor,
      deepColor: deepColor,
      size: 92,
      showLabel: false,
      onTap: onTap,
    );

    if (card.matched) {
      tile = AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 0.0).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: SizedBox.shrink(
          key: ValueKey('${card.object.slug}-gone'),
        ),
      );
    }

    return AnimatedScale(
      scale: isSelected ? 1.08 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: AnimatedSlide(
        offset: Offset(0, isSelected ? -0.12 : 0.0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: tile,
      ),
    );
  }
}

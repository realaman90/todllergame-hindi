import 'package:flutter/material.dart';
import '../content/content.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import 'sticker_service.dart';
import 'sticker_tile.dart';

/// Grid of earned stickers reachable from the scene pill and home screen.
class StickerWallScreen extends StatefulWidget {
  final StickerService stickerService;

  const StickerWallScreen({
    super.key,
    required this.stickerService,
  });

  @override
  State<StickerWallScreen> createState() => _StickerWallScreenState();
}

class _StickerWallScreenState extends State<StickerWallScreen> {
  late final Future<List<Scene>> _scenesFuture;

  @override
  void initState() {
    super.initState();
    _scenesFuture = Future.wait([
      const SceneLoader().load('house', language: 'hi'),
      const SceneLoader().load('farm', language: 'hi'),
      const SceneLoader().load('family', language: 'hi'),
    ]);
    widget.stickerService.addListener(_onStickersChanged);
  }

  @override
  void dispose() {
    widget.stickerService.removeListener(_onStickersChanged);
    super.dispose();
  }

  void _onStickersChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: const ToddlerBackButton(),
        automaticallyImplyLeading: false,
        leadingWidth: 72,
      ),
      body: FutureBuilder<List<Scene>>(
        future: _scenesFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Sticker wall failed to load scenes: ${snapshot.error}');
            return _EmptyWall();
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final scenes = snapshot.data!;
          final objectMap = <String, SceneObject>{};
          final themeMap = <String, String>{};
          for (final scene in scenes) {
            for (final object in scene.objects) {
              objectMap[object.slug] = object;
              themeMap[object.slug] = scene.theme;
            }
          }
          final stickers = widget.stickerService.stickers;

          if (stickers.isEmpty) return _EmptyWall();

          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemCount: stickers.length,
            itemBuilder: (context, index) {
              final slug = stickers[index];
              final baseSlug = slug.startsWith('puzzle:')
                  ? slug.substring(7)
                  : slug;
              final object = objectMap[baseSlug];
              final theme = themeMap[baseSlug];
              if (object == null || theme == null) {
                return const SizedBox.shrink();
              }

              final themeColor = AppColors.forTheme(theme);
              final deepColor = AppColors.deepFor(theme);
              return Center(
                child: StickerTile(
                  imagePath: 'assets/art/${object.art}',
                  wordHi: object.wordHi,
                  color: themeColor,
                  deepColor: deepColor,
                  size: 72,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyWall extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: 0.5,
        child: Icon(
          Icons.sentiment_satisfied_alt,
          size: 80,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

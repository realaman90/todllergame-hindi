import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'activities/activities.dart';
import 'audio/audio.dart';
import 'scenes/scenes.dart';
import 'stickers/stickers.dart';
import 'theme/theme.dart';
import 'widgets/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const ChaloGharGhoomeApp());
}

class ChaloGharGhoomeApp extends StatefulWidget {
  const ChaloGharGhoomeApp({super.key});

  @override
  State<ChaloGharGhoomeApp> createState() => _ChaloGharGhoomeAppState();
}

class _ChaloGharGhoomeAppState extends State<ChaloGharGhoomeApp> {
  final AudioService _audio = AudioService();
  final StickerService _stickers = StickerService();

  @override
  void initState() {
    super.initState();
    // Boot the audio engine + preload SFX before the child's first tap.
    _audio.init();
    _stickers.load();
  }

  @override
  void dispose() {
    _audio.dispose();
    _stickers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mithu & Friends',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final name = settings.name ?? '/';
        if (name == '/') {
          return MaterialPageRoute(
            builder: (_) => HomeScreen(
              stickerService: _stickers,
              audio: _audio,
            ),
            settings: settings,
          );
        }
        if (name.startsWith('/scene/')) {
          final sceneId = name.substring('/scene/'.length);
          if (sceneId.isEmpty) return null;
          return FadeScaleRoute(
            settings: settings,
            child: SceneScreen(
              sceneId: sceneId,
              audio: _audio,
              stickerService: _stickers,
            ),
          );
        }
        if (name == '/scenes') {
          return FadeScaleRoute(
            settings: settings,
            child: const ScenePickerScreen(),
          );
        }
        if (name == '/play') {
          return FadeScaleRoute(
            settings: settings,
            child: CarouselScreen(
              stickerService: _stickers,
              audio: _audio,
            ),
          );
        }
        if (name == '/stickers') {
          return FadeScaleRoute(
            settings: settings,
            child: StickerWallScreen(stickerService: _stickers),
          );
        }
        return null;
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'activities/activities.dart';
import 'audio/audio.dart';
import 'scenes/scenes.dart';
import 'settings/settings.dart';
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
  final SettingsService _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    // Boot the audio engine + preload SFX before the child's first tap,
    // then warm the whole word set in the background (A5: the lesson
    // must land as fast as the pop).
    _audio.init().then((_) async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      if (mounted) _audio.warmUp(manifest.listAssets());
    });
    _stickers.load();
    _settings.load().then((_) {
      if (mounted) {
        _audio.musicVolume = _settings.musicVolume;
      }
    });
  }

  @override
  void dispose() {
    _audio.dispose();
    _stickers.dispose();
    _settings.dispose();
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
        if (name == '/settings') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => SettingsScreen(
              audio: _audio,
              settingsService: _settings,
            ),
          );
        }
        return null;
      },
    );
  }
}

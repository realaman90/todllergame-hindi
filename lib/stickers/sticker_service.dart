import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistence service for discovered stickers and first-launch state.
///
/// Stores a list of slugs under the shared_preferences key "stickers".
/// Object discoveries are stored as their slug (e.g. "gaay"); puzzle
/// discoveries are namespaced (e.g. "puzzle:gaay") so the sticker wall
/// can show both kinds.
class StickerService extends ChangeNotifier {
  static const _key = 'stickers';
  static const _introKey = 'has_seen_intro';

  List<String> _stickers = [];
  bool _loaded = false;
  bool _hasSeenIntro = false;
  Completer<void>? _loadCompleter;

  List<String> get stickers => List.unmodifiable(_stickers);
  int get count => _stickers.length;
  bool get isLoaded => _loaded;
  bool get hasSeenIntro => _hasSeenIntro;

  Future<void> get loaded {
    if (_loaded) return Future.value();
    _loadCompleter ??= Completer<void>();
    return _loadCompleter!.future;
  }

  bool has(String slug) => _stickers.contains(slug);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _stickers = prefs.getStringList(_key) ?? [];
    _hasSeenIntro = prefs.getBool(_introKey) ?? false;
    _loaded = true;
    _loadCompleter?.complete();
    notifyListeners();
  }

  Future<void> discover(String slug) async {
    if (_stickers.contains(slug)) return;
    _stickers = [..._stickers, slug];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _stickers);
    notifyListeners();
  }

  Future<void> remove(String slug) async {
    if (!_stickers.contains(slug)) return;
    _stickers = _stickers.where((s) => s != slug).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _stickers);
    notifyListeners();
  }

  Future<void> markIntroSeen() async {
    if (_hasSeenIntro) return;
    _hasSeenIntro = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_introKey, true);
  }
}

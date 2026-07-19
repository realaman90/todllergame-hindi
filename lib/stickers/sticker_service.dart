import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistence service for discovered stickers.
///
/// Stores a list of slugs under the shared_preferences key "stickers".
/// Object discoveries are stored as their slug (e.g. "gaay"); puzzle
/// discoveries are namespaced (e.g. "puzzle:gaay") so the sticker wall
/// can show both kinds.
class StickerService extends ChangeNotifier {
  static const _key = 'stickers';

  List<String> _stickers = [];
  bool _loaded = false;

  List<String> get stickers => List.unmodifiable(_stickers);
  int get count => _stickers.length;
  bool get isLoaded => _loaded;

  bool has(String slug) => _stickers.contains(slug);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _stickers = prefs.getStringList(_key) ?? [];
    _loaded = true;
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
}

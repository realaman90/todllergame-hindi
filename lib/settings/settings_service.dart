import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistence service for parent-facing settings.
///
/// Stores the background-music volume under the shared_preferences key
/// "musicVolume". The service is a [ChangeNotifier] so UI can rebuild when
/// settings load or change.
class SettingsService extends ChangeNotifier {
  static const _musicVolumeKey = 'musicVolume';

  double _musicVolume = 1.0;
  bool _loaded = false;
  Completer<void>? _loadCompleter;

  double get musicVolume => _musicVolume;
  bool get isLoaded => _loaded;

  Future<void> get loaded {
    if (_loaded) return Future.value();
    _loadCompleter ??= Completer<void>();
    return _loadCompleter!.future;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getDouble(_musicVolumeKey);
    _musicVolume = stored == null
        ? 1.0
        : stored.clamp(0.0, 1.0);
    _loaded = true;
    _loadCompleter?.complete();
    notifyListeners();
  }

  set musicVolume(double value) {
    final clamped = value.clamp(0.0, 1.0);
    if (_musicVolume == clamped) return;
    _musicVolume = clamped;
    _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_musicVolumeKey, _musicVolume);
  }
}

import 'dart:convert';
import 'package:flutter/services.dart';
import 'models/scene.dart';

/// Loads and validates scene JSON bundled under `assets/content/`.
///
/// The loader is language-agnostic for scene data; the [language]
/// parameter is retained so callers can build language-scoped audio
/// paths (`assets/audio/<lang>/...`) without touching the content model.
class SceneLoader {
  final AssetBundle? bundle;

  const SceneLoader({this.bundle});

  Future<Scene> load(String sceneId, {required String language}) async {
    final raw = await (bundle ?? rootBundle)
        .loadString('assets/content/$sceneId.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    if (json['id'] != sceneId) {
      throw FormatException(
        'Scene file mismatch: expected "$sceneId" but found "${json['id']}"',
      );
    }
    return Scene.fromJson(json);
  }
}

import 'package:flutter/material.dart';

/// One tappable target inside a scene.
class SceneObject {
  final String slug;
  final String wordHi;
  final String translit;
  final String glossEn;
  final String art;
  final List<String> artLayers;
  final bool character;
  final Offset pos;
  final double scale;
  final String anim;

  const SceneObject({
    required this.slug,
    required this.wordHi,
    required this.translit,
    required this.glossEn,
    required this.art,
    this.artLayers = const [],
    this.character = false,
    required this.pos,
    required this.scale,
    required this.anim,
  });

  factory SceneObject.fromJson(Map<String, dynamic> json) {
    final pos = json['pos'] as List<dynamic>;
    final layers = (json['art_layers'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const <String>[];
    return SceneObject(
      slug: json['slug'] as String,
      wordHi: json['word_hi'] as String,
      translit: json['translit'] as String,
      glossEn: json['gloss_en'] as String,
      art: json['art'] as String,
      artLayers: layers,
      character: json['character'] as bool? ?? false,
      pos: Offset(
        (pos[0] as num).toDouble(),
        (pos[1] as num).toDouble(),
      ),
      scale: (json['scale'] as num).toDouble(),
      anim: json['anim'] as String,
    );
  }
}

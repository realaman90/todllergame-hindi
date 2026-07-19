import 'puzzle.dart';
import 'scene_object.dart';

/// A complete scene definition loaded from `assets/content/<id>.json`.
class Scene {
  final String id;
  final String titleHi;
  final String titleTranslit;
  final String titleEn;
  final String theme;
  final String background;
  final String? ambientAudio;
  final List<SceneObject> objects;
  final List<Puzzle> puzzles;

  const Scene({
    required this.id,
    required this.titleHi,
    required this.titleTranslit,
    required this.titleEn,
    required this.theme,
    required this.background,
    this.ambientAudio,
    required this.objects,
    required this.puzzles,
  });

  factory Scene.fromJson(Map<String, dynamic> json) {
    final objects = (json['objects'] as List<dynamic>)
        .map((e) => SceneObject.fromJson(e as Map<String, dynamic>))
        .toList();

    final slugs = objects.map((o) => o.slug).toSet();
    if (slugs.length != objects.length) {
      throw FormatException('Scene ${json['id']} contains duplicate slugs');
    }

    final puzzles = ((json['puzzles'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>())
        .map(Puzzle.fromJson)
        .toList();
    for (final puzzle in puzzles) {
      if (!slugs.contains(puzzle.ask)) {
        throw FormatException(
          'Scene ${json['id']} puzzle references unknown slug "${puzzle.ask}"',
        );
      }
      for (final decoy in puzzle.decoys) {
        if (!slugs.contains(decoy)) {
          throw FormatException(
            'Scene ${json['id']} puzzle decoy references unknown slug "$decoy"',
          );
        }
      }
    }

    return Scene(
      id: json['id'] as String,
      titleHi: json['title_hi'] as String,
      titleTranslit: json['title_translit'] as String,
      titleEn: json['title_en'] as String,
      theme: json['theme'] as String,
      background: json['background'] as String,
      ambientAudio: json['ambient_audio'] as String?,
      objects: objects,
      puzzles: puzzles,
    );
  }
}

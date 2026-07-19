/// A find-it puzzle definition inside a scene.
class Puzzle {
  final String ask;
  final List<String> decoys;

  const Puzzle({
    required this.ask,
    required this.decoys,
  });

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    return Puzzle(
      ask: json['ask'] as String,
      decoys: (json['decoys'] as List<dynamic>).cast<String>().toList(),
    );
  }
}

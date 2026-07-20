import 'package:flutter/material.dart';
import '../audio/audio.dart';
import '../content/content.dart';

/// A single playable mini-game format.
///
/// Each format lives in `lib/activities/<id>/` and implements this
/// interface. The carousel builds an [ActivitySession] and hands it to
/// [build] to run the game.
abstract class Activity {
  const Activity();

  String get id;

  /// Builds the activity UI for a scene's vocabulary subset.
  Widget build(BuildContext context, ActivitySession session);
}

/// Runtime context handed to an [Activity].
class ActivitySession {
  final Scene scene;

  /// The ≤6 vocabulary objects chosen for this round.
  final List<SceneObject> vocab;
  final AudioService audio;

  /// Call when the child has completed the activity.
  ///
  /// The carousel handles celebration, sticker, and auto-advance.
  final void Function() onComplete;

  /// Call when the child (or parent) wants to skip this round.
  final void Function() onSkip;

  const ActivitySession({
    required this.scene,
    required this.vocab,
    required this.audio,
    required this.onComplete,
    required this.onSkip,
  });
}

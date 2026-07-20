import 'activity.dart';
import 'linematch/linematch.dart';
import 'pairs/pairs.dart';

export 'activity.dart';
export 'carousel_screen.dart';
export 'linematch/linematch.dart';
export 'pairs/pairs.dart';

/// Returns the activity implementation for [id].
Activity activityFor(String id) {
  return switch (id) {
    'pairs' => const PairsActivity(),
    'linematch' => const LineMatchActivity(),
    _ => const PairsActivity(),
  };
}

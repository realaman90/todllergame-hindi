import 'activity.dart';
import 'pairs/pairs.dart';

export 'activity.dart';
export 'carousel_screen.dart';
export 'pairs/pairs.dart';

/// Returns the activity implementation for [id].
///
/// For A1 only `pairs` exists; later waves add `counting` and `balloons`.
Activity activityFor(String id) {
  return switch (id) {
    'pairs' => const PairsActivity(),
    _ => const PairsActivity(),
  };
}

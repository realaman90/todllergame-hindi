import 'activity.dart';
import 'bigsmall/bigsmall.dart';
import 'linematch/linematch.dart';
import 'oddone/oddone.dart';
import 'pairs/pairs.dart';
import 'pattern/pattern.dart';

export 'activity.dart';
export 'bigsmall/bigsmall.dart';
export 'carousel_screen.dart';
export 'linematch/linematch.dart';
export 'oddone/oddone.dart';
export 'pairs/pairs.dart';
export 'pattern/pattern.dart';

/// Returns the activity implementation for [id].
Activity activityFor(String id) {
  return switch (id) {
    'pairs' => const PairsActivity(),
    'linematch' => const LineMatchActivity(),
    'pattern' => const PatternActivity(),
    'oddone' => const OddOneActivity(),
    'bigsmall' => const BigSmallActivity(),
    _ => const PairsActivity(),
  };
}

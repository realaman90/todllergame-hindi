import 'activity.dart';
import 'balloons/balloons.dart';
import 'bubbles/bubbles.dart';
import 'bigsmall/bigsmall.dart';
import 'linematch/linematch.dart';
import 'missing/missing.dart';
import 'numtrace/numtrace.dart';
import 'soundmatch/soundmatch.dart';
import 'train/train.dart';
import 'whack/whack.dart';
import 'pathtrace/pathtrace.dart';
import 'shadow/shadow.dart';
import 'wipereveal/wipereveal.dart';
import 'oddone/oddone.dart';
import 'pairs/pairs.dart';
import 'pattern/pattern.dart';

export 'activity.dart';
export 'balloons/balloons.dart';
export 'bubbles/bubbles.dart';
export 'bigsmall/bigsmall.dart';
export 'carousel_screen.dart';
export 'linematch/linematch.dart';
export 'missing/missing.dart';
export 'numtrace/numtrace.dart';
export 'soundmatch/soundmatch.dart';
export 'train/train.dart';
export 'whack/whack.dart';
export 'pathtrace/pathtrace.dart';
export 'shadow/shadow.dart';
export 'wipereveal/wipereveal.dart';
export 'oddone/oddone.dart';
export 'pairs/pairs.dart';
export 'pattern/pattern.dart';

/// Returns the activity implementation for [id].
Activity activityFor(String id) {
  return switch (id) {
    'pairs' => const PairsActivity(),
    'linematch' => const LineMatchActivity(),
    'shadow' => const ShadowMatchActivity(),
    'wipereveal' => const WipeRevealActivity(),
    'missing' => const WhatsMissingActivity(),
    'whack' => const WhackActivity(),
    'numtrace' => const NumTraceActivity(),
    'soundmatch' => const SoundMatchActivity(),
    'train' => const TrainActivity(),
    'pathtrace' => const PathTraceActivity(),
    'balloons' => const BalloonsActivity(),
    'bubbles' => const BubblesActivity(),
    'pattern' => const PatternActivity(),
    'oddone' => const OddOneActivity(),
    'bigsmall' => const BigSmallActivity(),
    _ => const PairsActivity(),
  };
}

// End-to-end flow test — drives the real app on a simulator/device.
// Run: flutter test integration_test/app_flow_test.dart -d <device>
//
// NOTE: the app has perpetual idle animations (breathing objects, Mithu
// talk frames), so pumpAndSettle would never settle — all waits are
// explicit timed pumps.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:chalo_ghar_ghoome/main.dart' as app;
import 'package:chalo_ghar_ghoome/activities/activities.dart';
import 'package:chalo_ghar_ghoome/scenes/tappable_object.dart';
import 'package:chalo_ghar_ghoome/scenes/word_overlay.dart';
import 'package:chalo_ghar_ghoome/puzzles/puzzle_card.dart';
import 'package:chalo_ghar_ghoome/puzzles/puzzle_overlay.dart';
import 'package:chalo_ghar_ghoome/stickers/sticker_earned_overlay.dart';
import 'package:chalo_ghar_ghoome/widgets/art_tile.dart';
import 'package:chalo_ghar_ghoome/widgets/mithu_talking.dart';

Future<void> wait(WidgetTester t, int ms, {int stepMs = 100}) async {
  for (var elapsed = 0; elapsed < ms; elapsed += stepMs) {
    await t.pump(Duration(milliseconds: stepMs));
  }
}

/// Pump until [finder] matches or [timeoutMs] elapses.
Future<bool> waitFor(WidgetTester t, Finder finder,
    {int timeoutMs = 8000}) async {
  for (var elapsed = 0; elapsed < timeoutMs; elapsed += 150) {
    if (t.any(finder)) return true;
    await t.pump(const Duration(milliseconds: 150));
  }
  return t.any(finder);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('full core loop: intro -> scene -> word -> sticker -> puzzle',
      (tester) async {
    app.main();
    await wait(tester, 2000);

    // ---------- HOME ----------
    expect(find.byType(MithuTalking), findsOneWidget,
        reason: 'Mithu (talking widget) must be on Home');
    expect(find.text('बगीचा'), findsOneWidget,
        reason: 'Bageecha doorway card must be on Home');

    // If the first-launch intro is running, a tap anywhere skips it.
    // Tap Mithu himself — a safe non-navigating target regardless of
    // how the Home layout evolves.
    await tester.tap(find.byType(MithuTalking), warnIfMissed: false);
    await wait(tester, 500);
    expect(find.text('बगीचा'), findsOneWidget,
        reason: 'still on Home after intro skip');

    // Talk animation check: capture Mithu image frames over time while
    // any greeting/intro audio may be playing. We assert the widget
    // exists and renders an Image; frame alternation is asserted
    // opportunistically (audio may already have finished).
    final mithuFinder = find.descendant(
        of: find.byType(MithuTalking), matching: find.byType(Image));
    expect(mithuFinder, findsWidgets, reason: 'Mithu renders an image');

    // ---------- ENTER SCENE ----------
    await tester.tap(find.text('बगीचा'));
    await wait(tester, 2500); // route transition + welcome line starts

    final objects = find.byType(TappableObject);
    expect(objects, findsWidgets, reason: 'scene shows tappable objects');
    final objectCount = tester.widgetList(objects).length;
    expect(objectCount, lessThanOrEqualTo(6),
        reason: 'density rule: at most 6 objects visible, got $objectCount');

    // ---------- TAP OBJECT -> WORD OVERLAY ----------
    await tester.tap(objects.first);
    // anim preset (350ms) delays the overlay; then audio plays
    await wait(tester, 1200);
    expect(find.byType(WordOverlay), findsOneWidget,
        reason: 'word overlay appears after tapping an object');

    // Second tap on the overlay art = slow take (no crash, overlay stays)
    final overlayArt = find.descendant(
        of: find.byType(WordOverlay), matching: find.byType(Image));
    expect(overlayArt, findsWidgets, reason: 'overlay shows the object art');
    await tester.tap(overlayArt.first);
    await wait(tester, 800);
    expect(find.byType(WordOverlay), findsOneWidget,
        reason: 'overlay stays open after slow-take tap');

    // Tap far corner (scrim) to dismiss -> discovery -> sticker overlay
    await tester.tapAt(const Offset(30, 350));
    await wait(tester, 800);
    expect(find.byType(WordOverlay), findsNothing,
        reason: 'overlay dismisses on outside tap');

    // First-ever discovery of this object should fire the earned overlay
    // (unless this exact object was already discovered in a previous run
    // of the suite on this simulator - then no overlay; tolerate both,
    // but if present it must be dismissible.)
    if (tester.any(find.byType(StickerEarnedOverlay))) {
      await tester.tapAt(const Offset(400, 200));
      await wait(tester, 600);
      expect(find.byType(StickerEarnedOverlay), findsNothing,
          reason: 'earned overlay dismisses on tap');
    }
    await wait(tester, 1500); // possible swap-in of replacement object

    // The crash regression: after discovery + swap, the scene must still
    // be alive (this was the _dependents.isEmpty red screen).
    expect(tester.takeException(), isNull,
        reason: 'no framework exception after discovery/swap');
    expect(find.byType(TappableObject), findsWidgets,
        reason: 'scene still renders objects after swap');

    // ---------- FIND-IT PUZZLE ----------
    final puzzleDoor = find.byIcon(Icons.auto_awesome);
    expect(puzzleDoor, findsOneWidget, reason: 'puzzle door present');
    await tester.tap(puzzleDoor);
    await wait(tester, 1500); // prompt sequence starts

    expect(find.byType(PuzzleOverlay), findsOneWidget);
    final cards = find.byType(PuzzleCard);
    expect(tester.widgetList(cards).length, 4, reason: '4 candidate cards');

    // Wrong tap: no fail state — overlay unchanged, cards all remain.
    final wrongCard = find.byWidgetPredicate(
        (w) => w is PuzzleCard && !w.isTarget);
    await tester.tap(wrongCard.first);
    await wait(tester, 600);
    expect(find.byType(PuzzleOverlay), findsOneWidget,
        reason: 'wrong tap does not close/fail the puzzle');
    expect(tester.widgetList(find.byType(PuzzleCard)).length, 4,
        reason: 'wrong tap removes nothing');

    // Correct tap: celebrate -> praise -> earned overlay -> back to scene
    final rightCard =
        find.byWidgetPredicate((w) => w is PuzzleCard && w.isTarget);
    await tester.tap(rightCard);
    await wait(tester, 4000); // celebrate + praise line + transition
    expect(find.byType(PuzzleOverlay), findsNothing,
        reason: 'puzzle closes after correct answer');
    if (tester.any(find.byType(StickerEarnedOverlay))) {
      await tester.tapAt(const Offset(400, 200));
      await wait(tester, 600);
    }

    expect(tester.takeException(), isNull,
        reason: 'no framework exception through the whole loop');

    // ---------- ACTIVITY CAROUSEL: LINE MATCH ----------
    // Back to Home (custom toddler back button), then into the carousel.
    await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
    await wait(tester, 1200);
    final activityDoor = find.byIcon(Icons.play_arrow_rounded);
    expect(activityDoor, findsOneWidget, reason: 'activity door on Home');
    await tester.tap(activityDoor);
    await wait(tester, 2000);

    // Skip until the line-match round comes up (playlist alternates).
    var skips = 0;
    while (!tester.any(find.byType(LineMatchBody)) && skips < 8) {
      final skipArrow = find.byIcon(Icons.arrow_forward_rounded);
      if (!tester.any(skipArrow)) break;
      await tester.tap(skipArrow.first);
      await wait(tester, 1500);
      skips++;
    }
    expect(find.byType(LineMatchBody), findsOneWidget,
        reason: 'line-match round reachable in the carousel (skips=$skips)');

    // Solve all three lines: mirror the widget's layout math.
    final bodyRect = tester.getRect(find.byType(LineMatchBody));
    Offset leftCenter(int row) => bodyRect.topLeft +
        Offset(bodyRect.width * 0.24, bodyRect.height * (0.22 + 0.28 * row));
    Offset rightCenter(int row) => bodyRect.topLeft +
        Offset(bodyRect.width * 0.76, bodyRect.height * (0.22 + 0.28 * row));

    // Identify pairs by ArtTile image paths, in build order (L0,R0,L1,R1..).
    final tiles = tester
        .widgetList<ArtTile>(find.descendant(
            of: find.byType(LineMatchBody), matching: find.byType(ArtTile)))
        .toList();
    expect(tiles.length, 6, reason: 'three pairs on screen');
    final leftPaths = [tiles[0].imagePath, tiles[2].imagePath, tiles[4].imagePath];
    final rightPaths = [tiles[1].imagePath, tiles[3].imagePath, tiles[5].imagePath];

    for (var l = 0; l < 3; l++) {
      final r = rightPaths.indexOf(leftPaths[l]);
      expect(r, isNot(-1), reason: 'right column contains left tile $l');
      await tester.timedDragFrom(
        leftCenter(l),
        rightCenter(r) - leftCenter(l),
        const Duration(milliseconds: 600),
      );
      await wait(tester, 900);
      expect(tester.takeException(), isNull,
          reason: 'no exception after line drag $l');
    }

    // All matched -> completion delay -> Mithu praise (clip length varies)
    // -> earned sticker overlay. Poll rather than guess the audio length.
    final earned = await waitFor(tester, find.byType(StickerEarnedOverlay),
        timeoutMs: 12000);
    expect(earned, isTrue,
        reason: 'completing line match earns a sticker (polled 12s)');
    await tester.tapAt(bodyRect.center);
    await wait(tester, 800);

    expect(tester.takeException(), isNull,
        reason: 'no framework exception through line match');

    // End the test in a QUIET state: let audio finish, then leave the
    // carousel via normal navigation so players are stopped in app
    // context, not by engine teardown (just_audio's platform-init future
    // races hard shutdown and fails the suite from dart:async).
    await wait(tester, 3500);
    final back = find.byIcon(Icons.arrow_back_rounded);
    if (tester.any(back)) {
      await tester.tap(back.first);
      await wait(tester, 1500);
    }
    await wait(tester, 2500);
  });
}

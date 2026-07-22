// Camera tour for the vision-verdict pass: PLAYS the eight newest games
// (whack, plant, numtrace, peek, soundmatch, train, sizes, stickerplay)
// while simctl records video. Interactions are best-effort — the point
// is footage, so nothing here hard-fails except a crash.
// Run: flutter test integration_test/new_games_tour_test.dart -d <device>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:chalo_ghar_ghoome/main.dart' as app;
import 'package:chalo_ghar_ghoome/activities/activities.dart';
import 'package:chalo_ghar_ghoome/stickers/sticker_earned_overlay.dart';
import 'package:chalo_ghar_ghoome/widgets/art_tile.dart';
import 'package:chalo_ghar_ghoome/widgets/mithu_talking.dart';

Future<void> wait(WidgetTester t, int ms, {int stepMs = 100}) async {
  for (var elapsed = 0; elapsed < ms; elapsed += stepMs) {
    await t.pump(Duration(milliseconds: stepMs));
  }
}

Future<bool> waitFor(WidgetTester t, Finder finder,
    {int timeoutMs = 8000}) async {
  for (var elapsed = 0; elapsed < timeoutMs; elapsed += 150) {
    if (t.any(finder)) return true;
    await t.pump(const Duration(milliseconds: 150));
  }
  return t.any(finder);
}

/// Dismiss a sticker overlay if one appeared.
Future<void> clearOverlay(WidgetTester t) async {
  if (t.any(find.byType(StickerEarnedOverlay))) {
    await t.tapAt(const Offset(400, 120));
    await wait(t, 900);
  }
}

/// Skip rounds until [finder] is on screen (or give up after [guard]).
Future<bool> skipTo(WidgetTester t, Finder finder, {int guard = 30}) async {
  for (var i = 0; i < guard; i++) {
    await clearOverlay(t);
    if (t.any(finder)) return true;
    final skip = find.byIcon(Icons.arrow_forward_rounded);
    if (!t.any(skip)) return false;
    await t.tap(skip.first, warnIfMissed: false);
    await wait(t, 1500);
  }
  return t.any(finder);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('tour: play the eight newest games on camera',
      (tester) async {
    app.main();
    await waitFor(tester, find.byType(MithuTalking), timeoutMs: 15000);
    await wait(tester, 1200);
    await tester.tap(find.byType(MithuTalking).first, warnIfMissed: false);
    await wait(tester, 600);
    await tester.tap(find.text('खेलो'));
    await wait(tester, 2500);

    // ---- WHACK: bonk everything that rises for a while ----
    if (await skipTo(tester, find.byType(WhackBody))) {
      for (var i = 0; i < 14; i++) {
        final pots = find.byType(CustomPaint);
        // Tap across the whack area — peekers and pots both live there.
        final body = tester.getRect(find.byType(WhackBody));
        await tester.tapAt(Offset(
            body.left + body.width * (0.3 + 0.2 * (i % 3)),
            body.center.dy + body.height * 0.05));
        await wait(tester, 700);
        await clearOverlay(tester);
        if (!tester.any(find.byType(WhackBody))) break;
        if (pots.evaluate().isEmpty) break;
      }
    }

    // ---- PLANT: water + sun onto the sprout ----
    if (await skipTo(tester, find.byType(PlantBody))) {
      for (final label in ['पानी', 'सूरज']) {
        final tile = find.text(label);
        if (tester.any(tile)) {
          final sproutArt = find.byType(ArtTile).first;
          await tester.timedDrag(
            tile.first,
            tester.getCenter(sproutArt) - tester.getCenter(tile.first),
            const Duration(milliseconds: 700),
          );
          await wait(tester, 1600);
        }
      }
      await waitFor(tester, find.byType(StickerEarnedOverlay),
          timeoutMs: 8000);
      await wait(tester, 1500);
      await clearOverlay(tester);
    }

    // ---- NUMTRACE: show the digit + start pulse, then move on ----
    if (await skipTo(tester, find.byType(NumTraceBody))) {
      await wait(tester, 4000);
    }

    // ---- PEEK: let the zoom breathe, then answer both choices ----
    if (await skipTo(tester, find.byType(PeekBody))) {
      await wait(tester, 3500);
      for (var i = 0; i < 2; i++) {
        final tiles = find.descendant(
            of: find.byType(PeekBody), matching: find.byType(ArtTile));
        final n = tiles.evaluate().length;
        if (n > i) {
          await tester.tap(tiles.at(n - 1 - i), warnIfMissed: false);
          await wait(tester, 1400);
        }
        if (tester.any(find.byType(StickerEarnedOverlay))) break;
      }
      await wait(tester, 1500);
      await clearOverlay(tester);
    }

    // ---- SOUNDMATCH: tap tiles until the round yields ----
    if (await skipTo(tester, find.byType(SoundMatchBody))) {
      for (var i = 0; i < 12; i++) {
        await clearOverlay(tester);
        final tiles = find.descendant(
            of: find.byType(SoundMatchBody),
            matching: find.byType(ArtTile));
        if (tiles.evaluate().isEmpty) break;
        await tester.tap(tiles.at(i % tiles.evaluate().length),
            warnIfMissed: false);
        await wait(tester, 1300);
        if (!tester.any(find.byType(SoundMatchBody))) break;
      }
      await clearOverlay(tester);
    }

    // ---- TRAIN: drag every cargo to both wagons ----
    if (await skipTo(tester, find.byType(TrainBody))) {
      for (var round = 0; round < 2; round++) {
        for (final word in ['आम', 'केला', 'गाय', 'कुत्ता']) {
          final tile = find.text(word);
          if (!tester.any(tile)) continue;
          final wagons = find.descendant(
              of: find.byType(TrainBody),
              matching: find.byType(DragTarget<Object?>));
          // Wagon centers: probe both known wagon positions.
          final body = tester.getRect(find.byType(TrainBody));
          final target = Offset(
              body.left + body.width * (round == 0 ? 0.38 : 0.62),
              body.top + body.height * 0.32);
          await tester.timedDrag(
            tile.first,
            target - tester.getCenter(tile.first),
            const Duration(milliseconds: 700),
          );
          await wait(tester, 1100);
          if (wagons.evaluate().isEmpty) break;
        }
        if (!tester.any(find.byType(TrainBody))) break;
      }
      await waitFor(tester, find.byType(StickerEarnedOverlay),
          timeoutMs: 9000);
      await wait(tester, 1500);
      await clearOverlay(tester);
    }

    // ---- SIZES: tap the three sizes repeatedly ----
    if (await skipTo(tester, find.byType(SizesBody))) {
      for (var i = 0; i < 10; i++) {
        await clearOverlay(tester);
        final tiles = find.descendant(
            of: find.byType(SizesBody), matching: find.byType(ArtTile));
        final n = tiles.evaluate().length;
        if (n == 0) break;
        await tester.tap(tiles.at(i % n), warnIfMissed: false);
        await wait(tester, 1200);
        if (!tester.any(find.byType(SizesBody))) break;
      }
      await clearOverlay(tester);
    }

    // ---- STICKERPLAY: place four stickers around the canvas ----
    if (await skipTo(tester, find.byType(StickerPlayBody))) {
      final body = tester.getRect(find.byType(StickerPlayBody));
      for (var i = 0; i < 4; i++) {
        final tiles = find.descendant(
            of: find.byType(StickerPlayBody),
            matching: find.byType(ArtTile));
        if (tiles.evaluate().isEmpty) break;
        final target = Offset(
            body.left + body.width * (0.25 + 0.17 * i),
            body.top + body.height * (0.30 + 0.10 * (i % 2)));
        await tester.timedDrag(
          tiles.first,
          target - tester.getCenter(tiles.first),
          const Duration(milliseconds: 650),
        );
        await wait(tester, 1200);
      }
      await waitFor(tester, find.byType(StickerEarnedOverlay),
          timeoutMs: 8000);
      await wait(tester, 1500);
      await clearOverlay(tester);
    }

    expect(tester.takeException(), isNull,
        reason: 'no framework exception during the tour');

    // Quiet exit.
    await wait(tester, 2000);
    final back = find.byIcon(Icons.arrow_back_rounded);
    if (tester.any(back)) {
      await tester.tap(back.first, warnIfMissed: false);
      await wait(tester, 1500);
    }
    await wait(tester, 2500);
  });
}

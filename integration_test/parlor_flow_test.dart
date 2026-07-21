// Ice-cream parlor flow test — plays the whole parlor arc for real:
// flavor -> scoop plop -> toppings -> Mithu slides in -> serve -> sticker.
// Run: flutter test integration_test/parlor_flow_test.dart -d <device>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:chalo_ghar_ghoome/main.dart' as app;
import 'package:chalo_ghar_ghoome/stickers/sticker_earned_overlay.dart';
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

Finder assetImage(String fragment) => find.byWidgetPredicate((w) =>
    w is Image &&
    w.image is AssetImage &&
    (w.image as AssetImage).assetName.contains(fragment));

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('parlor: flavor -> toppings -> serve to Mithu -> sticker',
      (tester) async {
    app.main();
    await wait(tester, 2000);

    // Skip any first-launch intro, then enter the games carousel.
    await tester.tap(find.byType(MithuTalking), warnIfMissed: false);
    await wait(tester, 500);
    await tester.tap(find.text('खेलो'));
    await wait(tester, 2000);

    // Round 1 of the carousel is the parlor: empty cone + flavor tray.
    expect(await waitFor(tester, assetImage('icecream_cone_empty')), isTrue,
        reason: 'parlor opens with the empty waffle cone on the counter');
    expect(await waitFor(tester, find.text('आम')), isTrue,
        reason: 'flavor tray offers aam');

    // ---------- 1. CHOOSE FLAVOR ----------
    await tester.tap(find.text('आम'), warnIfMissed: false);
    await wait(tester, 1600); // scoop plop + "upar daalo" prompt
    expect(assetImage('icecream_scoop'), findsWidgets,
        reason: 'scoop lands on the cone after choosing a flavor');

    // ---------- 2. CHOOSE TOPPINGS ----------
    expect(await waitFor(tester, find.text('केला')), isTrue,
        reason: 'topping tray offers the other fruits');
    await tester.tap(find.text('केला'), warnIfMissed: false);
    await wait(tester, 600);
    await tester.tap(find.text('सेब'), warnIfMissed: false);
    // 2nd topping -> serve phase (900ms beat) -> Mithu slides in (650ms).
    await wait(tester, 2200);

    // ---------- 3. GIVE IT TO MITHU ----------
    expect(find.byType(MithuTalking), findsWidgets,
        reason: 'Mithu is at the counter waiting for his ice cream');
    await tester.tap(find.byType(MithuTalking).first, warnIfMissed: false);

    // Munch munch -> "mmm!" -> carousel praise -> sticker overlay.
    final earned = await waitFor(tester, find.byType(StickerEarnedOverlay),
        timeoutMs: 15000);
    expect(earned, isTrue,
        reason: 'serving Mithu completes the parlor and earns a sticker');
    expect(tester.takeException(), isNull,
        reason: 'no framework exception through the parlor flow');

    await tester.tapAt(const Offset(400, 200));
    await wait(tester, 1000);

    // Quiet exit: leave via normal navigation so audio players stop in
    // app context, not by engine teardown.
    await wait(tester, 2500);
    final back = find.byIcon(Icons.arrow_back_rounded);
    if (tester.any(back)) {
      await tester.tap(back.first);
      await wait(tester, 1500);
    }
    await wait(tester, 2500);
  });
}

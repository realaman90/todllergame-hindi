// Diagnostic: load every bundled .mp3 through SoLoud and report the
// ones its decoder rejects (CoreAudio tolerates files dr_mp3 won't).
// Run: flutter test integration_test/audio_assets_load_test.dart -d <device>

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('every bundled mp3 loads in SoLoud', (tester) async {
    await SoLoud.instance.init();
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final mp3s = manifest
        .listAssets()
        .where((k) => k.endsWith('.mp3'))
        .toList()
      ..sort();
    final failures = <String>[];
    for (final path in mp3s) {
      try {
        final src = await SoLoud.instance.loadAsset(path);
        await SoLoud.instance.disposeSource(src);
      } catch (e) {
        failures.add('$path -> $e');
      }
    }
    // Surface the async native-callback exceptions too.
    await tester.pump(const Duration(milliseconds: 500));
    debugPrint('SOLOUD LOAD CHECK: ${mp3s.length} files, '
        '${failures.length} failures');
    for (final f in failures) {
      debugPrint('SOLOUD LOAD FAIL: $f');
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}

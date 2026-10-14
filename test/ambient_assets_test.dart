import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/audio/ambient_mixer.dart';

void main() {
  test('all 10 ambient sound MP3 assets exist on disk and have valid sizes', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final mixer = AmbientMixer();

    for (final c in mixer.channels) {
      expect(c.asset.endsWith('.mp3'), isTrue, reason: '${c.id} should be an mp3');
      final file = File(c.asset);
      expect(file.existsSync(), isTrue, reason: 'Asset file ${c.asset} must exist');
      final bytes = file.lengthSync();
      expect(bytes, greaterThan(500 * 1024), reason: '${c.asset} should be at least 500 KB');
      expect(bytes, lessThan(1500 * 1024), reason: '${c.asset} should be under 1.5 MB');
    }

    mixer.dispose();
  });
}

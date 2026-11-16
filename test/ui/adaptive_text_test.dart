import 'package:flutter/foundation.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as legacy;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:q_master/ui/adaptive_text.dart';

void main() {
  for (final (platform, material3, expected) in [
    (TargetPlatform.android, true, 'Mixed Case'),
    (TargetPlatform.android, false, 'MIXED CASE'),
    (TargetPlatform.iOS, true, 'Mixed Case'),
    (TargetPlatform.iOS, false, 'Mixed Case'),
  ]) {
    testWidgets('text preserves case on $platform m3=$material3', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await tester.pumpWidget(
        legacy.MaterialApp(
          theme: legacy.ThemeData(platform: platform, useMaterial3: material3),
          home: const legacy.Scaffold(
            body: AdaptiveText(
              'Mixed Case',
              style: TextStyle(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textScaler: TextScaler.linear(1.3),
            ),
          ),
        ),
      );
      final text = tester.widget<Text>(find.text(expected));
      expect(text.style, const TextStyle(fontWeight: FontWeight.w700));
      expect(text.textAlign, TextAlign.center);
      expect(text.maxLines, 2);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(text.textScaler, const TextScaler.linear(1.3));
    });
  }
}

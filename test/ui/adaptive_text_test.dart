import 'package:flutter/foundation.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as legacy;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:q_master/ui/adaptive_platform.dart';
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
          builder: (_, child) => material.Theme(
            data: material.ThemeData(
              platform: platform,
              useMaterial3: material3,
            ),
            child: child!,
          ),
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

  testWidgets('adaptive text and platform follow the split theme', (
    tester,
  ) async {
    Future<void> check(TargetPlatform platform, String expected) async {
      await tester.pumpWidget(
        legacy.MaterialApp(
          theme: legacy.ThemeData(
            platform: platform == TargetPlatform.iOS
                ? TargetPlatform.android
                : TargetPlatform.iOS,
            useMaterial3: true,
          ),
          builder: (_, child) => material.Theme(
            data: material.ThemeData(platform: platform, useMaterial3: false),
            child: child!,
          ),
          home: legacy.Scaffold(
            body: Builder(
              builder: (context) {
                expect(
                  isMaterialPlatform(context),
                  platform == TargetPlatform.android,
                );
                return const AdaptiveText('Mixed Case');
              },
            ),
          ),
        ),
      );
      expect(find.text(expected), findsOneWidget);
    }

    await check(TargetPlatform.iOS, 'Mixed Case');
    await check(TargetPlatform.android, 'MIXED CASE');
  });
}

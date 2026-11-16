import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter/foundation.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as legacy;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/slack/slackblast_picker_section.dart';
import 'package:q_master/theme/theme.dart' as gloom;
import 'package:q_master/theme/transition_theme.dart';

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('picker section loads, selects and retries on $platform', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final load = Completer<List<String>>();
      final future = ValueNotifier<Future<List<String>>>(load.future);
      addTearDown(future.dispose);
      String? selected;
      var retries = 0;
      await tester.pumpWidget(
        legacy.MaterialApp(
          theme: gloom.darkTheme().copyWith(platform: platform),
          localizationsDelegates: [
            ...L10n.localizationsDelegates,
            material.GlobalMaterialLocalizations.delegate,
            cupertino.GlobalCupertinoLocalizations.delegate,
          ],
          builder: (_, child) => TransitionTheme(child: child!),
          home: legacy.Scaffold(
            body: ValueListenableBuilder<Future<List<String>>>(
              valueListenable: future,
              builder: (_, currentFuture, _) => SlackblastPickerSection<String>(
                title: 'Regions',
                future: currentFuture,
                itemLabel: (item) => item,
                selectedItem: null,
                onSelect: (item) => selected = item,
                emptyLabel: 'No regions',
                errorLabel: 'Load failed',
                onRetry: () => retries++,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(material.CircularProgressIndicator), findsOneWidget);
      load.complete(['Metro']);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Metro'));
      expect(selected, 'Metro');

      final failed = Completer<List<String>>();
      future.value = failed.future;
      await tester.pump();
      failed.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text('Load failed'), findsOneWidget);
      expect(find.byType(material.ElevatedButton), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      expect(retries, 1);
    });
  }
}

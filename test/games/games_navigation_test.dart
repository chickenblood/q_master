import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:q_master/games/deck_of_pain_game_view.dart';
import 'package:q_master/games/dod_game_view.dart';
import 'package:q_master/games/games_tab.dart';
import 'package:q_master/theme/adaptive_app.dart';
import 'package:q_master/theme/theme.dart' as gloom;

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('games retain their theme and navigation on $platform', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      const channel =
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle';
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (_) async => null,
      );
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      const sensorMethods = MethodChannel(
        'dev.fluttercommunity.plus/sensors/method',
      );
      const sensorEvents = MethodChannel(
        'dev.fluttercommunity.plus/sensors/accelerometer',
      );
      messenger.setMockMethodCallHandler(sensorMethods, (_) async => null);
      messenger.setMockMethodCallHandler(sensorEvents, (_) async => null);
      addTearDown(() {
        messenger.setMockMethodCallHandler(sensorMethods, null);
        messenger.setMockMethodCallHandler(sensorEvents, null);
      });
      var wakelockChanges = 0;
      messenger.setMockMessageHandler(channel, (_) async {
        wakelockChanges++;
        return const StandardMessageCodec().encodeMessage([null]);
      });
      addTearDown(() => messenger.setMockMessageHandler(channel, null));

      final rootKey = GlobalKey<NavigatorState>();
      final branchKey = GlobalKey<NavigatorState>();
      final router = GoRouter(
        navigatorKey: rootKey,
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, _, shell) => shell,
            branches: [
              StatefulShellBranch(
                navigatorKey: branchKey,
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (_, _) => const GamesTab(),
                    routes: GamesTab.routes(rootNavigatorKey: rootKey),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      final mode = ValueNotifier(material.ThemeMode.light);
      addTearDown(mode.dispose);
      await tester.pumpWidget(
        ProviderScope(
          child: ValueListenableBuilder<material.ThemeMode>(
            valueListenable: mode,
            builder: (_, themeMode, _) =>
                AdaptiveApp(routerConfig: router, themeMode: themeMode),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tileInks = find.descendant(
        of: find.byType(GamesTab),
        matching: find.byType(material.Ink),
      );
      expect(tileInks, findsNWidgets(2));
      Color borderColor() {
        final ink = tester.widget<material.Ink>(tileInks.last);
        final decoration = ink.decoration! as BoxDecoration;
        return (decoration.border! as Border).top.color;
      }

      expect(borderColor(), gloom.lightTheme().colorScheme.onSurface);
      mode.value = material.ThemeMode.dark;
      await tester.pumpAndSettle();
      expect(borderColor(), gloom.darkTheme().colorScheme.onSurface);

      Finder tileButton(Finder ink) =>
          find.ancestor(of: ink, matching: find.byType(material.InkWell)).first;
      await tester.tap(tileButton(tileInks.last));
      await tester.pumpAndSettle();
      expect(wakelockChanges, 1);
      final game = find.byType(DeckOfPainGameView);
      expect(game, findsOneWidget);
      final gameContext = tester.element(game);
      expect(Navigator.of(gameContext), same(rootKey.currentState));
      expect(ModalRoute.of(gameContext)!.fullscreenDialog, isTrue);
      expect(find.text('Tap to draw a new card'), findsOneWidget);

      await tester.tapAt(tester.getCenter(game));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: game, matching: find.byType(AutoSizeText)),
        findsOneWidget,
      );
      await tester.tapAt(tester.getCenter(game));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: game, matching: find.byType(AutoSizeText)),
        findsOneWidget,
      );

      rootKey.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.byType(GamesTab), findsOneWidget);
      expect(wakelockChanges, 2);

      await tester.tap(tileButton(tileInks.first));
      await tester.pumpAndSettle();
      final dod = find.byType(DodGameView);
      expect(dod, findsOneWidget);
      expect(Navigator.of(tester.element(dod)), same(rootKey.currentState));
      expect(find.text('Shake or tap to roll'), findsOneWidget);
      rootKey.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.byType(GamesTab), findsOneWidget);
      expect(wakelockChanges, 4);
    });
  }
}

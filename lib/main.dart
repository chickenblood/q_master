import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:q_master/model/timer.dart';
import 'package:shake/shake.dart';

import 'games/games_tab.dart';
import 'l10n/l10n.dart';
import 'model/workout_list.dart';
import 'near_me/near_me_tab.dart';
import 'settings/settings_sheet.dart';
import 'theme/theme.dart';
import 'timer/timer_tab.dart';
import 'ui/adaptive_icons.dart';
import 'ui/adaptive_modal_sheet.dart';
import 'workouts/create_workout_sheet.dart';
import 'workouts/workouts_tab.dart';

enum Tab { workouts, games, timer, location }

void main() {
  runApp(ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  MainApp({super.key}) {
    // Easter egg sound effect on shake.
    ShakeDetector.autoStart(
      onPhoneShake: (_) => AudioPlayer()
        ..setAsset('assets/sounds/easter_egg.wav')
        ..play(),
    );
  }

  final _navigatorKey = GlobalKey<NavigatorState>();
  final _tabController = PlatformTabController(
    initialIndex: Tab.workouts.index,
  );
  final List<Widget> _tabPages = [
    WorkoutsTab(),
    GamesTab(),
    TimerTab(),
    NearMeTab(),
  ];

  Future<void> _showComposeWorkoutModal(WidgetRef ref) async {
    final context = _navigatorKey.currentContext;
    assert(context != null);
    if (context == null) return;

    final workout = await showAdaptiveModalSheet(
      context: _navigatorKey.currentContext!,
      child: CreateWorkoutSheet(),
    );
    if (workout != null) {
      final listNotifier = ref.read(workoutListProvider.notifier);
      listNotifier.add(workout);
    }
  }

  void _resetTimer(WidgetRef ref) async {
    final notifier = ref.read(timerProvider.notifier);
    notifier.reset();
  }

  Future<void> _showSettingsModal() async {
    final context = _navigatorKey.currentContext;
    assert(context != null);
    if (context == null) return;

    await showAdaptiveModalSheet(
      context: _navigatorKey.currentContext!,
      child: SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => PlatformProvider(
    settings: PlatformSettingsData(
      iosUsesMaterialWidgets: true,
      iosUseZeroPaddingForAppbarPlatformIcon: true,
    ),
    builder: (_) => PlatformApp(
      title: 'Q Master',
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      navigatorKey: _navigatorKey,
      material: (_, _) => MaterialAppData(
        theme: lightTheme(),
        darkTheme: darkTheme(),
        themeMode: ThemeMode.system,
      ),
      cupertino: (context, _) => CupertinoAppData(
        theme: MaterialBasedCupertinoThemeData(
          materialTheme:
              MediaQuery.platformBrightnessOf(context) == Brightness.light
              ? lightTheme()
              : darkTheme(),
        ),
      ),
      home: Builder(
        builder: (context) => PlatformTabScaffold(
          appBarBuilder: (_, index) => PlatformAppBar(
            cupertino: (_, _) =>
                CupertinoNavigationBarData(backgroundColor: Colors.transparent),
            title: Text(L10n.of(context)!.appBarTitle),
            leading: PlatformIconButton(
              icon: Icon(context.platformIcons.gearSolid),
              onPressed: _showSettingsModal,
            ),
            trailingActions: [
              switch (Tab.values[index]) {
                .workouts => PlatformIconButton(
                  icon: Icon(PlatformIcons(context).add),
                  onPressed: () => _showComposeWorkoutModal(ref),
                ),
                .timer => PlatformIconButton(
                  icon: Icon(PlatformIcons(context).refresh),
                  onPressed: () => _resetTimer(ref),
                ),
                _ => SizedBox.shrink(),
              },
            ],
          ),
          tabController: _tabController,
          bodyBuilder: (_, index) => _tabPages[index],
          items: [
            BottomNavigationBarItem(
              icon: Icon(AdaptiveIcons.history),
              label: L10n.of(context)!.workoutsTabTitle,
            ),
            BottomNavigationBarItem(
              icon: Icon(AdaptiveIcons.sports),
              label: L10n.of(context)!.gamesTabTitle,
            ),
            BottomNavigationBarItem(
              icon: Icon(AdaptiveIcons.timer),
              label: L10n.of(context)!.timerTabTitle,
            ),
            BottomNavigationBarItem(
              icon: Icon(AdaptiveIcons.location),
              label: L10n.of(context)!.nearMeTabTitle,
            ),
          ],
        ),
      ),
    ),
  );
}

import 'package:audio_session/audio_session.dart';
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
import 'ui/media_query.dart';
import 'utils/shared_app_prefs.dart';
import 'workouts/create_workout_sheet.dart';
import 'workouts/workouts_tab.dart';

enum Tab { workouts, games, timer, location }

void main() {
  runApp(ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  MainApp({super.key}) {
    SharedAppPrefs.ensureInitialized();
    _configureAudioSession();
    // Easter egg sound effect on shake.
    ShakeDetector.autoStart(
      onPhoneShake: (_) => AudioPlayer()
        ..setAsset('assets/sounds/easter_egg.m4a')
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

  // The FAB is only for Android. We use app bar actions on iOS.
  Widget? _androidFloatingActionButton(
    BuildContext context, {
    required WidgetRef ref,
    required int index,
  }) {
    final tab = Tab.values[index];
    if (tab != .workouts && tab != .timer) {
      return null;
    }
    return FloatingActionButton(
      backgroundColor: tab == .timer ? Colors.red : null,
      onPressed: switch (tab) {
        Tab.workouts => () => _showComposeWorkoutModal(ref),
        Tab.timer => () => _resetTimer(ref),
        _ => null,
      },
      child: Icon(switch (tab) {
        Tab.workouts => PlatformIcons(context).add,
        Tab.timer => PlatformIcons(context).refresh,
        _ => null,
      }),
    );
  }

  // Determine whether to show the tab bar based on the selected tab, device
  // and orientation.
  bool _shouldShowTabBar(BuildContext context) {
    final isTablet = MediaUtils.isTablet(context);
    final selectedIndex = _tabController.index(context);
    // We want a full screen timer on phones in landscape mode.
    final isTimerTab = Tab.values[selectedIndex] == .timer;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return isTablet || !(isTimerTab && isLandscape);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => PlatformProvider(
    settings: PlatformSettingsData(
      iosUsesMaterialWidgets: true,
      iosUseZeroPaddingForAppbarPlatformIcon: true,
    ),
    builder: (_) => PlatformTheme(
      materialLightTheme: lightTheme(),
      materialDarkTheme: darkTheme(),
      cupertinoLightTheme: MaterialBasedCupertinoThemeData(
        materialTheme: lightTheme(),
      ),
      cupertinoDarkTheme: MaterialBasedCupertinoThemeData(
        materialTheme: darkTheme(),
      ),
      themeMode: .system,
      builder: (context) => PlatformApp(
        title: 'Q Master',
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        navigatorKey: _navigatorKey,
        home: Builder(
          builder: (context) => PlatformTabScaffold(
            appBarBuilder: (_, index) => PlatformAppBar(
              leading: PlatformIconButton(
                padding: Theme.of(context).platform == TargetPlatform.iOS
                    ? EdgeInsets.only(right: 22)
                    : EdgeInsets.zero,
                icon: Icon(context.platformIcons.gearSolid),
                onPressed: _showSettingsModal,
              ),
              cupertino: (appBarContext, _) => CupertinoNavigationBarData(
                backgroundColor: Colors.transparent,
                title: Text(
                  L10n.of(context)!.appBarTitle,
                  textScaler: MediaQuery.textScalerOf(
                    context,
                  ).clamp(maxScaleFactor: 1.6),
                ),
                // Action buttons – iOS only
                trailing: Row(
                  mainAxisAlignment: .end,
                  children: [
                    Spacer(),
                    switch (Tab.values[_tabController.index(appBarContext)]) {
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
                    SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            tabController: _tabController,
            bodyBuilder: (_, index) => _tabPages[index],
            materialBuilder: (tabBarContext, _, index) =>
                MaterialTabScaffoldData(
                  height: _shouldShowTabBar(tabBarContext) ? null : 0,
                  tabsBackgroundColor: _shouldShowTabBar(tabBarContext)
                      ? null
                      : Colors.transparent,
                  // FAB button – Android only
                  floatingActionButtonLocation: .endFloat,
                  floatingActionButton: _androidFloatingActionButton(
                    context,
                    ref: ref,
                    index: index,
                  ),
                ),
            cupertinoBuilder: (tabBarContext, _, index) =>
                CupertinoTabScaffoldData(
                  navBarHeight: _shouldShowTabBar(tabBarContext) ? null : 0,
                  tabsBackgroundColor: _shouldShowTabBar(tabBarContext)
                      ? Colors.black
                      : Colors.transparent,
                ),
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
    ),
  );
}

// Configure the audio session to not interruptother audio apps.
Future<void> _configureAudioSession() async {
  final session = await AudioSession.instance;
  await session.configure(
    AudioSessionConfiguration(
      avAudioSessionCategory: .playback,
      avAudioSessionCategoryOptions: .duckOthers,
      avAudioSessionMode: .defaultMode,
      avAudioSessionRouteSharingPolicy: .defaultPolicy,
      avAudioSessionSetActiveOptions: .none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: .sonification,
        flags: .none,
        usage: .assistanceSonification,
      ),
      androidAudioFocusGainType: .gainTransientMayDuck,
      androidWillPauseWhenDucked: false,
    ),
  );
}

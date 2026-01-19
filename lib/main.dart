import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shake/shake.dart';

import 'games/games_tab.dart';
import 'l10n/l10n.dart';
import 'near_me/near_me_tab.dart';
import 'theme/theme.dart';
import 'timer/timer_tab.dart';
import 'ui/adaptive_icons.dart';
import 'ui/media_query.dart';
import 'utils/shared_app_prefs.dart';
import 'workouts/workouts_tab.dart';

enum Tab { workouts, games, timer, location }

void main() {
  runApp(ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget with WidgetsBindingObserver {
  late final ShakeDetector _shakeDetector;

  MainApp({super.key}) {
    SharedAppPrefs.ensureInitialized();
    _configureAudioSession();
    WidgetsBinding.instance.addObserver(this);

    // Easter egg sound effect on game action or shake.
    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: (_) {
        final selectedTab = _tabController.index(_navigatorKey.currentContext!);
        if (selectedTab != Tab.games.index) {
          AudioPlayer()
            ..setAsset('assets/sounds/easter_egg.m4a')
            ..play();
        }
      },
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _shakeDetector.stopListening();
    } else if (state == AppLifecycleState.resumed) {
      _shakeDetector.startListening();
    }
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
        debugShowCheckedModeBanner: false,
        home: Builder(
          builder: (context) => PlatformTabScaffold(
            tabController: _tabController,
            bodyBuilder: (_, index) => _tabPages[index],
            materialBuilder: (tabBarContext, _, index) =>
                MaterialTabScaffoldData(
                  height: _shouldShowTabBar(tabBarContext) ? null : 0,
                  tabsBackgroundColor: _shouldShowTabBar(tabBarContext)
                      ? null
                      : Colors.transparent,
                ),
            cupertinoBuilder: (tabBarContext, _, index) =>
                CupertinoTabScaffoldData(
                  navBarHeight: _shouldShowTabBar(tabBarContext) ? null : 0,
                  tabsBackgroundColor: _shouldShowTabBar(tabBarContext)
                      ? null
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

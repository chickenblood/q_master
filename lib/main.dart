import 'package:audio_session/audio_session.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shake/shake.dart';

import 'firebase_options.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedAppPrefs.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget with WidgetsBindingObserver {
  late final ShakeDetector _shakeDetector;

  MainApp({super.key}) {
    _configureAudioSession();
    WidgetsBinding.instance.addObserver(this);

    // Easter egg sound effect on game action or shake.
    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: (_) {
        final selectedTab = _tabController.index(_navigatorKey.currentContext!);
        if (selectedTab != Tab.games.index &&
            SharedAppPrefs.instance.motorboatSoundEnabled.value) {
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

  final _tabPages = [WorkoutsTab(), GamesTab(), TimerTab(), NearMeTab()];

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
    builder: (_) => ListenableBuilder(
      listenable: SharedAppPrefs.instance.theme,
      builder: (_, _) => PlatformTheme(
        materialLightTheme: lightTheme(),
        materialDarkTheme: darkTheme(),
        cupertinoLightTheme: MaterialBasedCupertinoThemeData(
          materialTheme: lightTheme(),
        ),
        cupertinoDarkTheme: MaterialBasedCupertinoThemeData(
          materialTheme: darkTheme(),
        ),
        themeMode: ThemeMode.values[SharedAppPrefs.instance.theme.value],
        builder: (context) => PlatformApp(
          title: 'Q Master',
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          home: Builder(
            builder: (context) => PlatformTabScaffold(
              tabController: _tabController,
              bodyBuilder: (_, index) =>
                  _TabsContainer(selectedIndex: index, children: _tabPages),
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

/// Wraps tabs on Android so that it supports nested navigation and remembers
/// the navigation stack when switching tabs. On iOS, the CupertinoTabScaffold
/// already provides this behavior.
final class _TabsContainer extends StatelessWidget {
  final List<Widget> _children;
  final int selectedIndex;

  _TabsContainer({required List<Widget> children, required this.selectedIndex})
    : _children = children.map((child) => _TabWrapper(child: child)).toList();

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == .android) {
      return IndexedStack(index: selectedIndex, children: _children);
    }
    return _children[selectedIndex];
  }
}

final class _TabWrapper extends StatelessWidget {
  final Widget child;

  const _TabWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == .android) {
      return CupertinoTabView(
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => child),
      );
    }
    return child;
  }
}

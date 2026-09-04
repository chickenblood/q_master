import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shake/shake.dart';
import 'package:zikzak_share_handler/zikzak_share_handler.dart';

import 'firebase_options.dart';
import 'games/games_tab.dart';
import 'l10n/l10n.dart';
import 'model/workout_list.dart';
import 'near_me/near_me_tab.dart';
import 'theme/theme.dart';
import 'timer/timer_setup_tab.dart';
import 'ui/adaptive_icons.dart';
import 'ui/media_query.dart';
import 'ui/simple_alert.dart';
import 'utils/shared_app_prefs.dart';
import 'workouts/workouts_tab.dart';

enum Tab { workouts, games, timer, location }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedAppPrefs.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ProviderScope(child: _MainApp()));
}

class _MainApp extends ConsumerStatefulWidget with WidgetsBindingObserver {
  late final ShakeDetector _shakeDetector;
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _tabController = PlatformTabController(
    initialIndex: Tab.workouts.index,
  );

  _MainApp() {
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _shakeDetector.stopListening();
    } else if (state == AppLifecycleState.resumed) {
      _shakeDetector.startListening();
    }
  }

  @override
  _MainAppState createState() => _MainAppState();
}

final class _MainAppState extends ConsumerState<_MainApp> {
  final tabPages = [WorkoutsTab(), GamesTab(), TimerSetupTab(), NearMeTab()];
  late final StreamSubscription<SharedMedia> _sharedMediaSubscription;

  @override
  void initState() {
    super.initState();
    configureReceivingShares();
  }

  @override
  void dispose() {
    _sharedMediaSubscription.cancel();
    super.dispose();
  }

  Future<void> configureReceivingShares() async {
    final initialMedia = await ShareHandlerPlatform.instance
        .getInitialSharedMedia();

    void handleReceivedMedia(SharedMedia media) {
      if (media.attachments == null) return;

      for (final attachment in media.attachments!) {
        if (attachment.path.endsWith('.qmw')) {
          final listNotifier = ref.read(workoutListProvider.notifier);
          listNotifier.addFromFile(attachment.path);
          return;
        }
      }

      if (mounted) {
        showSimpleAlert(
          widget._navigatorKey.currentContext!,
          message: 'Invalid workout data received',
        );
      }
      ShareHandlerPlatform.instance.resetInitialSharedMedia();
    }

    if (initialMedia != null) {
      handleReceivedMedia(initialMedia);
    }

    _sharedMediaSubscription = ShareHandlerPlatform.instance.sharedMediaStream
        .listen(
          handleReceivedMedia,
          onError: (_) {
            if (mounted) {
              showSimpleAlert(
                widget._navigatorKey.currentContext!,
                message: 'Invalid workout data received',
              );
            }
          },
        );
  }

  // Determine whether to show the tab bar based on the selected tab, device
  // and orientation.
  bool shouldShowTabBar(BuildContext context) {
    final isTablet = MediaUtils.isTablet(context);
    final selectedIndex = widget._tabController.index(context);
    // We want a full screen timer on phones in landscape mode.
    final isTimerTab = Tab.values[selectedIndex] == .timer;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return isTablet || !(isTimerTab && isLandscape);
  }

  @override
  Widget build(BuildContext context) {
    return PlatformProvider(
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
          builder: (context) => ScaffoldMessenger(
            child: PlatformApp(
              title: 'Q Master',
              localizationsDelegates: L10n.localizationsDelegates,
              supportedLocales: L10n.supportedLocales,
              navigatorKey: widget._navigatorKey,
              debugShowCheckedModeBanner: false,
              home: Builder(
                builder: (context) {
                  // Red 2px top-of-tab indicator for active tab — Option 3 identity.
                  BottomNavigationBarItem tabItem(IconData icon, String label) {
                    const double iconBoxHeight = 40;
                    const double iconSize = 24;
                    final theme = Theme.of(context);
                    final colorScheme = theme.colorScheme;
                    // Removed unused isDark variable
                    final indicator = Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 28,
                          height: 2,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    );
                    Widget iconWidget({bool active = false}) => SizedBox(
                      height: iconBoxHeight,
                      width: iconBoxHeight,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (active) indicator,
                          // Shift icon down by 4 pixels
                          Positioned(
                            top: 4,
                            left: 0,
                            right: 0,
                            child: Icon(
                              icon,
                              size: iconSize,
                              color: active
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                    return BottomNavigationBarItem(
                      icon: iconWidget(active: false),
                      activeIcon: iconWidget(active: true),
                      label: label,
                    );
                  }

                  return PlatformTabScaffold(
                    tabController: widget._tabController,
                    bodyBuilder: (_, index) => _TabsContainer(
                      selectedIndex: index,
                      children: tabPages,
                    ),
                    material3Tabs: (tabBarContext, _) {
                      // Removed unused isDark variable
                      final theme = Theme.of(tabBarContext);
                      final colorScheme = theme.colorScheme;
                      return MaterialNavigationBarData(
                        indicatorColor: Colors.transparent,
                        labelTextStyle: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          final isSelected = states.contains(
                            WidgetState.selected,
                          );
                          final color = isSelected
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant;
                          return theme.textTheme.labelMedium?.copyWith(
                            color: color,
                          );
                        }),
                      );
                    },
                    materialBuilder: (tabBarContext, _, index) =>
                        MaterialTabScaffoldData(
                          height: shouldShowTabBar(tabBarContext) ? null : 0,
                          tabsBackgroundColor: shouldShowTabBar(tabBarContext)
                              ? null
                              : Colors.transparent,
                        ),
                    cupertinoTabs: (tabBarContext, _) {
                      // Removed unused isDark variable
                      final theme = Theme.of(tabBarContext);
                      final colorScheme = theme.colorScheme;
                      return CupertinoTabBarData(
                        activeColor: colorScheme.onSurface,
                        inactiveColor: colorScheme.onSurfaceVariant,
                      );
                    },
                    cupertinoBuilder: (tabBarContext, _, index) =>
                        CupertinoTabScaffoldData(
                          navBarHeight: shouldShowTabBar(tabBarContext)
                              ? null
                              : 0,
                          tabsBackgroundColor: shouldShowTabBar(tabBarContext)
                              ? null
                              : Colors.transparent,
                        ),
                    items: [
                      tabItem(
                        AdaptiveIcons.history,
                        L10n.of(context)!.workoutsTabTitle,
                      ),
                      tabItem(
                        AdaptiveIcons.sports,
                        L10n.of(context)!.gamesTabTitle,
                      ),
                      tabItem(
                        AdaptiveIcons.timer,
                        L10n.of(context)!.timerPageTitle,
                      ),
                      tabItem(
                        AdaptiveIcons.location,
                        L10n.of(context)!.nearMeTabTitle,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Configure the audio session to not interrupt other audio apps.
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
  final List<Widget> children;
  final int selectedIndex;

  _TabsContainer({required List<Widget> children, required this.selectedIndex})
    : children = children.map((child) => _TabWrapper(child: child)).toList();

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == .android) {
      return IndexedStack(index: selectedIndex, children: children);
    }
    return children[selectedIndex];
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

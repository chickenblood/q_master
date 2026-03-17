import 'package:audio_session/audio_session.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shake/shake.dart';
import 'package:share_handler/share_handler.dart';

import 'firebase_options.dart';
import 'games/games_tab.dart';
import 'l10n/l10n.dart';
import 'model/f3_nation_credentials.dart';
import 'model/workout_list.dart';
import 'near_me/near_me_tab.dart';
import 'theme/theme.dart';
import 'timer/timer_setup_tab.dart';
import 'ui/adaptive_icons.dart';
import 'ui/media_query.dart';
import 'utils/shared_app_prefs.dart';
import 'workouts/workouts_tab.dart';

enum Tab { workouts, games, timer, location }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedAppPrefs.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await F3NationApiKey.ensureInitialized();
  runApp(ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget with WidgetsBindingObserver {
  late final ShakeDetector _shakeDetector;

  MainApp({super.key}) {
    _configureAudioSession();
    _configureReceivingShares();
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

  final _tabPages = [WorkoutsTab(), GamesTab(), TimerSetupTab(), NearMeTab()];
  dynamic _listNotifier;

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
    final isLandscape = MediaQuery.orientationOf(context) == .landscape;

    return isTablet || !(isTimerTab && isLandscape);
  }

  Future<void> _configureReceivingShares() async {
    final handler = ShareHandlerPlatform.instance;
    final media = await handler.getInitialSharedMedia();

    void handleReceivedMedia(SharedMedia media) {
      final attachments = media.attachments;

      for (final attachment in attachments ?? []) {
        if (attachment?.path.endsWith('.json') ?? false) {
          _listNotifier.addFromFile(attachment!.path);
          return;
        }
      }
      _showDebugAlert('Invalid workout data received');
    }

    if (media != null) {
      handleReceivedMedia(media);
    }

    handler.sharedMediaStream.listen((media) {
      handleReceivedMedia(media);
    });
  }

  Future<void> _showDebugAlert(String message) => showAdaptiveDialog(
    context: _navigatorKey.currentContext!,
    builder: (BuildContext innerContext) => AlertDialog.adaptive(
      content: PlatformText(message),
      actions: [
        PlatformDialogAction(
          onPressed: () => Navigator.pop(innerContext),
          child: PlatformText('OK'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _listNotifier = ref.watch(workoutListProvider.notifier);
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
              navigatorKey: _navigatorKey,
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
                    tabController: _tabController,
                    bodyBuilder: (_, index) => _TabsContainer(
                      selectedIndex: index,
                      children: _tabPages,
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
                          height: _shouldShowTabBar(tabBarContext) ? null : 0,
                          tabsBackgroundColor: _shouldShowTabBar(tabBarContext)
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
                          navBarHeight: _shouldShowTabBar(tabBarContext)
                              ? null
                              : 0,
                          tabsBackgroundColor: _shouldShowTabBar(tabBarContext)
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

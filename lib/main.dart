import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:shake/shake.dart';
import 'package:zikzak_share_handler/zikzak_share_handler.dart';

import 'firebase_options.dart';
import 'games/games_tab.dart';
import 'l10n/l10n.dart';
import 'model/workout_list.dart';
import 'near_me/near_me_tab.dart';
import 'theme/theme.dart';
import 'timer/timer_setup_tab.dart';
import 'ui/adaptive_widgets.dart';
import 'ui/media_query.dart';
import 'ui/simple_alert.dart';
import 'utils/shared_app_prefs.dart';
import 'workouts/workouts_tab.dart';

enum Tab { workouts, games, timer, location }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  await SharedAppPrefs.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(LiquidGlassWidgets.wrap(child: ProviderScope(child: _MainApp())));
}

class _MainApp extends ConsumerStatefulWidget with WidgetsBindingObserver {
  late final ShakeDetector _shakeDetector;
  final _navigatorKey = GlobalKey<NavigatorState>();

  _MainApp() {
    _configureAudioSession();
    WidgetsBinding.instance.addObserver(this);

    // Easter egg sound effect on game action or shake.
    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: (_) {
        final location = GoRouter.of(
          _navigatorKey.currentContext!,
        ).state.uri.path;
        if (!location.startsWith('/games') &&
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
  final _workoutsScrollController = ScrollController();
  late final StreamSubscription<SharedMedia> _sharedMediaSubscription;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      navigatorKey: widget._navigatorKey,
      initialLocation: '/workouts',
      routes: [
        StatefulShellRoute(
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/workouts',
                  routes: WorkoutsTab.routes,
                  builder: (context, state) =>
                      WorkoutsTab(scrollController: _workoutsScrollController),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/games',
                  builder: (context, state) => GamesTab(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/timer',
                  builder: (context, state) => TimerSetupTab(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/location',
                  builder: (context, state) => NearMeTab(),
                ),
              ],
            ),
          ],
          navigatorContainerBuilder: (context, navigationShell, children) =>
              IndexedStack(
                index: navigationShell.currentIndex,
                children: [
                  for (final child in children)
                    GlassNavigationShell(child: child),
                ],
              ),
          builder: (context, state, navigationShell) =>
              _buildShell(context, state, navigationShell),
        ),
      ],
    );
    configureReceivingShares();
  }

  @override
  void dispose() {
    _sharedMediaSubscription.cancel();
    _router.dispose();
    _workoutsScrollController.dispose();
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
  bool _shouldShowTabBar(
    BuildContext context, {
    required String location,
    required int selectedIndex,
  }) {
    if (location == '/workouts/editor') {
      return false;
    }

    final isTablet = MediaUtils.isTablet(context);
    // We want a full screen timer on phones in landscape mode.
    final isTimerTab = Tab.values[selectedIndex] == .timer;
    final isLandscape = MediaQuery.orientationOf(context) == .landscape;

    return isTablet || !(isTimerTab && isLandscape);
  }

  Widget _buildShell(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    final selectedIndex = navigationShell.currentIndex;
    final location = state.uri.path;
    final shouldShowFab = location == '/workouts';
    return AdaptiveScaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(top: false, child: navigationShell),
      bottomBar: AdaptiveTabBar(
        visible: _shouldShowTabBar(
          context,
          location: location,
          selectedIndex: selectedIndex,
        ),
        selectedIconColor: Theme.of(context).colorScheme.primary,
        selectedIndex: selectedIndex,
        onTabSelected: (index) => navigationShell.goBranch(index),
        items: [
          AdaptiveTabItem(
            icon: Icon(AdaptiveIcons.history),
            label: L10n.of(context)!.workoutsTabTitle,
          ),
          AdaptiveTabItem(
            icon: Icon(AdaptiveIcons.sports),
            label: L10n.of(context)!.gamesTabTitle,
          ),
          AdaptiveTabItem(
            icon: Icon(AdaptiveIcons.timer),
            label: L10n.of(context)!.timerPageTitle,
          ),
          AdaptiveTabItem(
            icon: Icon(AdaptiveIcons.location),
            label: L10n.of(context)!.nearMeTabTitle,
          ),
        ],
        trailingButton: selectedIndex == Tab.workouts.index && shouldShowFab
            ? _addWorkoutButton(context: context, ref: ref)
            : null,
        scrollController: _workoutsScrollController,
      ),
      resizeToAvoidBottomInset: false,
      floatingActionButton: selectedIndex == Tab.workouts.index && shouldShowFab
          ? _addWorkoutButton(context: context, ref: ref)
          : null,
    );
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
            child: PlatformApp.router(
              title: 'Q Master',
              localizationsDelegates: L10n.localizationsDelegates,
              supportedLocales: L10n.supportedLocales,
              routerConfig: _router,
              debugShowCheckedModeBanner: false,
            ),
          ),
        ),
      ),
    );
  }
}

/// A trailing button next to the tab bar for creating a new workout.
AdaptiveAccessoryActionItem? _addWorkoutButton({
  required BuildContext context,
  required WidgetRef ref,
}) {
  return AdaptiveAccessoryActionItem(
    icon: Icon(PlatformIcons(context).add),
    id: 'add-workout',
    onPressed: (anchor) => WorkoutsTab.showWorkoutCreationPicker(
      context: context,
      ref: ref,
      anchor: anchor,
    ),
  );
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
      avAudioSessionSetActiveOptions: .notifyOthersOnDeactivation,
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

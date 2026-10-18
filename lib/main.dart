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

import 'app_router.dart';
import 'firebase_options.dart';
import 'l10n/l10n.dart';
import 'model/workout_list.dart';
import 'theme/theme.dart';
import 'ui/simple_alert.dart';
import 'utils/shared_app_prefs.dart';

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
    _router = createAppRouter(
      navigatorKey: widget._navigatorKey,
      workoutsScrollController: _workoutsScrollController,
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

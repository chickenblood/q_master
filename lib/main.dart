import 'package:audio_session/audio_session.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'app_router.dart';
import 'firebase_options.dart';
import 'l10n/l10n.dart';
import 'theme/theme.dart';
import 'utils/easter_egg_shake_listener.dart';
import 'utils/shared_app_prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  await SharedAppPrefs.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _configureAudioSession();
  runApp(LiquidGlassWidgets.wrap(child: ProviderScope(child: _MainApp())));
}

class _MainApp extends StatefulWidget {
  const _MainApp();

  @override
  State<_MainApp> createState() => _MainAppState();
}

final class _MainAppState extends State<_MainApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _workoutsScrollController = ScrollController();
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(
      navigatorKey: _navigatorKey,
      workoutsScrollController: _workoutsScrollController,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _workoutsScrollController.dispose();
    super.dispose();
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
              builder: (context, child) =>
                  EasterEggShakeListener(router: _router, child: child!),
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

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shake/shake.dart';

import 'shared_app_prefs.dart';

/// Plays the configured Easter egg sound when the device is shaken outside
/// the games tab, and pauses shake detection while the app is backgrounded.
class EasterEggShakeListener extends StatefulWidget {
  final GoRouter router;
  final Widget child;

  const EasterEggShakeListener({
    required this.router,
    required this.child,
    super.key,
  });

  @override
  State<EasterEggShakeListener> createState() => _EasterEggShakeListenerState();
}

class _EasterEggShakeListenerState extends State<EasterEggShakeListener>
    with WidgetsBindingObserver {
  late final ShakeDetector _shakeDetector;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: (_) {
        final isGamesTab = widget.router.state.uri.path.startsWith('/games');
        if (!isGamesTab &&
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
    if (state == AppLifecycleState.paused) {
      _shakeDetector.stopListening();
    } else if (state == AppLifecycleState.resumed) {
      _shakeDetector.startListening();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shakeDetector.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

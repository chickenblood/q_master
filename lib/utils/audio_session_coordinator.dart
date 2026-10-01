import 'package:audio_session/audio_session.dart';

/// Tracks how many app sound effects are concurrently playing so the shared
/// OS audio session can be deactivated once they've all finished.
///
/// `just_audio` activates the audio session (ducking other apps) whenever a
/// player starts, but never deactivates it afterwards. Without deactivation,
/// iOS/Android never restore other apps' volume. Callers should invoke
/// [markPlaybackStarted] before playing a sound and [markPlaybackEnded] once
/// that sound's `play()` future resolves (which happens on natural
/// completion, pause, or stop).
class AudioSessionCoordinator {
  AudioSessionCoordinator._();

  static final instance = AudioSessionCoordinator._();

  int _activePlaybackCount = 0;

  void markPlaybackStarted() {
    _activePlaybackCount++;
  }

  Future<void> markPlaybackEnded() async {
    if (_activePlaybackCount == 0) return;
    _activePlaybackCount--;
    if (_activePlaybackCount > 0) return;

    final session = await AudioSession.instance;
    await session.setActive(
      false,
      avAudioSessionSetActiveOptions:
          AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
    );
  }
}

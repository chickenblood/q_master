import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zikzak_share_handler/zikzak_share_handler.dart';

import '../model/workout_list.dart';
import '../ui/simple_alert.dart';

/// Imports workout files received through the platform's share extension.
class ReceivedWorkoutShareListener extends ConsumerStatefulWidget {
  final Widget child;

  const ReceivedWorkoutShareListener({required this.child, super.key});

  @override
  ConsumerState<ReceivedWorkoutShareListener> createState() =>
      _ReceivedWorkoutShareListenerState();
}

class _ReceivedWorkoutShareListenerState
    extends ConsumerState<ReceivedWorkoutShareListener> {
  StreamSubscription<SharedMedia>? _subscription;

  @override
  void initState() {
    super.initState();
    _listenForReceivedShares();
  }

  Future<void> _listenForReceivedShares() async {
    final shareHandler = ShareHandlerPlatform.instance;
    final initialMedia = await shareHandler.getInitialSharedMedia();
    if (!mounted) return;

    if (initialMedia != null) {
      _handleReceivedMedia(initialMedia);
    }

    _subscription = shareHandler.sharedMediaStream.listen(
      _handleReceivedMedia,
      onError: (Object error, StackTrace stackTrace) {
        if (mounted) _showInvalidWorkoutAlert();
      },
    );
  }

  void _handleReceivedMedia(SharedMedia media) {
    final attachments = media.attachments;
    if (attachments == null) return;

    for (final attachment in attachments) {
      if (attachment.path.endsWith('.qmw')) {
        ref.read(workoutListProvider.notifier).addFromFile(attachment.path);
        return;
      }
    }

    _showInvalidWorkoutAlert();
    ShareHandlerPlatform.instance.resetInitialSharedMedia();
  }

  void _showInvalidWorkoutAlert() {
    showSimpleAlert(context, message: 'Invalid workout data received');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

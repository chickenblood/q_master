import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../ui/adaptive_icons.dart';

class YoutubeVideoScreen extends StatefulWidget {
  final String videoId;

  const YoutubeVideoScreen({super.key, required this.videoId});

  @override
  State<YoutubeVideoScreen> createState() => _YoutubeVideoScreenState();
}

class _YoutubeVideoScreenState extends State<YoutubeVideoScreen> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        hideControls: true,
        showLiveFullscreenButton: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.white,
                progressColors: const ProgressBarColors(
                  playedColor: Colors.white,
                  handleColor: Colors.white,
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: PlatformIconButton(
                padding: EdgeInsets.zero,
                icon: Icon(AdaptiveIcons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Center(
              child: ValueListenableBuilder<YoutubePlayerValue>(
                valueListenable: _controller,
                builder: (context, value, _) => IconButton(
                  icon: Icon(
                    value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 64,
                  ),
                  iconSize: 64,
                  onPressed: _togglePlayPause,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../ui/adaptive_app_bar.dart';
import '../ui/adaptive_icons.dart';
import '../ui/adaptive_scaffold.dart';

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
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AdaptiveScaffold(
        backgroundColor: Colors.black,
        appBar: AdaptiveAppBar(
          backgroundColor: Colors.transparent,
          leading: [
            AdaptiveAppBarItem(
              icon: Icon(AdaptiveIcons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        body: Center(
          child: YoutubePlayer(
            controller: _controller,
            aspectRatio: 16 / 9,
            initParams: const YoutubePlayerParams(showControls: false),
          ),
        ),
      ),
    );
  }
}

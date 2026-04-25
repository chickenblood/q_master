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
      flags: const YoutubePlayerFlags(autoPlay: true),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: PlatformScaffold(
        backgroundColor: Colors.transparent,
        material: (_, _) => MaterialScaffoldData(extendBodyBehindAppBar: true),
        appBar: PlatformAppBar(
          backgroundColor: Colors.transparent,
          cupertino: (_, _) => CupertinoNavigationBarData(
            backgroundColor: Colors.transparent,
            enableBackgroundFilterBlur: false,
          ),
          leading: PlatformIconButton(
            icon: Icon(AdaptiveIcons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
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
      ),
    );
  }
}

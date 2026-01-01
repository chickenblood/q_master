import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:q_master/ui/adaptive_icons.dart';

import 'dodecahedron_shader.dart';

final class DodGameView extends StatelessWidget {
  final String heroTag;

  const DodGameView({super.key, this.heroTag = ''});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: Object() /* ignore heroTag for now */,
      child: PlatformScaffold(
        backgroundColor: Colors.black,
        appBar: PlatformAppBar(
          backgroundColor: Colors.transparent,
          leading: PlatformIconButton(
            icon: Icon(AdaptiveIcons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: DodecahedronShader()),
      ),
    );
  }
}

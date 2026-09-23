import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../l10n/l10n.dart';
import '../ui/adaptive_icons.dart';
import 'dodecahedron_shader.dart';

const _defaultDodHeroTag = 'dod_game';

final class DodGameView extends StatelessWidget {
  final String heroTag;

  const DodGameView({super.key, this.heroTag = _defaultDodHeroTag});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
      child: GlassScaffold(
        backgroundColor: Colors.black,
        appBar: GlassAppBar(
          backgroundColor: Colors.transparent,
          leading: GlassIconButton(
            icon: Icon(AdaptiveIcons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: PlatformText(
            L10n.of(context)!.dodShakeToRollDiceMessage,
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(maxScaleFactor: 1.6),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        body: const Center(child: DodecahedronShader()),
      ),
    );
  }
}

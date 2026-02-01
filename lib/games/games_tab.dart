import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n/l10n.dart';
import '../settings/settings_sheet.dart';
import 'deck_of_pain_game_view.dart';
import 'dod_game_view.dart';

class GamesTab extends StatelessWidget {
  const GamesTab({super.key});

  void _showDodGame(BuildContext context, String tag) =>
      _presentModalSheet(context, DodGameView(heroTag: tag));

  void _showDeckOfPainGame(BuildContext context, String tag) =>
      _presentModalSheet(context, DeckOfPainGameView(heroTag: tag));

  Future<void> _presentModalSheet(BuildContext context, Widget child) async {
    // Stop the screen from sleeping while the beatdown browser is shown.
    WakelockPlus.enable();

    await Navigator.of(context, rootNavigator: true).push(
      platformPageRoute(
        context: context,
        fullscreenDialog: true,
        builder: (context) => child,
      ),
    );

    WakelockPlus.disable();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.orientationOf(context) == .landscape;
    return PlatformScaffold(
      appBar: PlatformAppBar(
        leading: const SettingsActionButton(),
        title: Text(
          L10n.of(context)!.gamesTabTitle,
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(maxScaleFactor: 1.6),
        ),
        cupertino: (appBarContext, _) =>
            CupertinoNavigationBarData(backgroundColor: Colors.transparent),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: isLandscape
                ? const EdgeInsets.all(16.0)
                : const EdgeInsets.fromLTRB(80.0, 16.0, 80.0, 16.0),
            child: Flex(
              direction: isLandscape ? Axis.horizontal : Axis.vertical,
              mainAxisAlignment: .center,
              children: [
                Expanded(
                  child: Center(
                    child: Transform.rotate(
                      angle: _degToRad(5.0),
                      child: _GameTile(
                        title: L10n.of(context)!.dodGameTileTitle,
                        subtitle: 'Kermit‘s',
                        imagePath: 'assets/images/DoD.png',
                        onTap: (tag) => _showDodGame(context, tag),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Transform.rotate(
                      angle: _degToRad(-5.0),
                      child: _GameTile(
                        title: L10n.of(context)!.dopGameTileTitle,
                        imagePath: 'assets/images/DoP.png',
                        textColor: Colors.black,
                        onTap: (tag) => _showDeckOfPainGame(context, tag),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

double _degToRad(double degrees) => degrees * pi / 180.0;

class _GameTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? textColor;
  final String? imagePath;
  final Function(String)? onTap;

  const _GameTile({
    required this.title,
    this.subtitle,
    this.textColor,
    this.imagePath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22.0),
    child: Hero(
      tag: title,
      child: Material(
        color: Colors.transparent,
        clipBehavior: .hardEdge,
        child: InkWell(
          onTap: () => onTap?.call(title),
          borderRadius: BorderRadius.circular(16.0),
          child: Stack(
            children: [
              if (subtitle != null)
                Positioned(
                  top: 8.0,
                  left: 8.0,
                  right: 8.0,
                  child: AutoSizeText(
                    subtitle!,
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textScaleFactor: min(
                      // ignore: deprecated_member_use
                      MediaQuery.textScaleFactorOf(context),
                      1.4,
                    ),
                  ),
                ),
              Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  image: imagePath != null
                      ? DecorationImage(
                          image: AssetImage(imagePath!),
                          fit: .contain,
                        )
                      : null,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface,
                    width: 1.0,
                  ),
                ),
                child: AspectRatio(aspectRatio: 2 / 3),
              ),
              Positioned(
                bottom: 4,
                left: 4,
                right: 16, // Larger padding on right to account 'A'
                // in card graphic.
                child: AutoSizeText(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  softWrap: true,
                  maxLines: 1,
                  textScaleFactor: min(
                    // ignore: deprecated_member_use
                    MediaQuery.textScaleFactorOf(context),
                    1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

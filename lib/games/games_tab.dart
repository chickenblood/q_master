import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n/l10n.dart';
import '../settings/settings_sheet.dart';
import '../ui/adaptive_route_page.dart';
import '../ui/adaptive_widgets.dart';
import '../ui/media_query.dart';
import 'deck_of_pain_game_view.dart';
import 'dod_game_view.dart';

/// Carries the source tile's Hero tag into a full-screen game route.
final class GameRouteArguments {
  final String heroTag;

  const GameRouteArguments({required this.heroTag});
}

class GamesTab extends StatelessWidget {
  /// Route name for the Dodecahedron of Doom game.
  static const dodGameRouteName = 'dod-game';

  /// Route name for the Deck of Pain game.
  static const deckOfPainGameRouteName = 'deck-of-pain-game';

  /// Builds game routes on the root navigator so they cover the tab shell.
  static List<RouteBase> routes({
    required GlobalKey<NavigatorState> rootNavigatorKey,
  }) => [
    GoRoute(
      path: 'dod-game',
      name: dodGameRouteName,
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) {
        final arguments = state.extra;
        if (arguments is! GameRouteArguments) {
          throw StateError('DoD route requires game route arguments.');
        }
        return adaptiveRoutePage(
          context,
          state,
          DodGameView(heroTag: arguments.heroTag),
          fullscreenDialog: true,
        );
      },
    ),
    GoRoute(
      path: 'deck-of-pain',
      name: deckOfPainGameRouteName,
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) {
        final arguments = state.extra;
        if (arguments is! GameRouteArguments) {
          throw StateError('Deck of Pain route requires game route arguments.');
        }
        return adaptiveRoutePage(
          context,
          state,
          DeckOfPainGameView(heroTag: arguments.heroTag),
          fullscreenDialog: true,
        );
      },
    ),
  ];

  const GamesTab({super.key});

  Future<void> _showDodGame(BuildContext context, String tag) {
    final router = GoRouter.of(context);
    return _withPortraitLock(
      context: context,
      action: () => _presentGame(router, dodGameRouteName, tag),
    );
  }

  Future<void> _showDeckOfPainGame(BuildContext context, String tag) {
    final router = GoRouter.of(context);
    return _withPortraitLock(
      context: context,
      action: () => _presentGame(router, deckOfPainGameRouteName, tag),
    );
  }

  Future<void> _withPortraitLock({
    required BuildContext context,
    required Future<void> Function() action,
  }) async {
    final shouldLockPortrait = !MediaUtils.isTablet(context);
    if (shouldLockPortrait) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    try {
      if (!context.mounted) return;
      await action();
    } finally {
      if (shouldLockPortrait) {
        await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      }
    }
  }

  Future<void> _presentGame(
    GoRouter router,
    String routeName,
    String heroTag,
  ) async {
    await WakelockPlus.enable();
    try {
      await router.pushNamed<void>(
        routeName,
        extra: GameRouteArguments(heroTag: heroTag),
      );
    } finally {
      await WakelockPlus.disable();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.orientationOf(context) == .landscape;
    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        leading: [settingsGlassBarItem(id: 'left-item', context: context)],
        title: Text(
          L10n.of(context)!.gamesTabTitle,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(maxScaleFactor: 1.6),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: isLandscape
                ? const EdgeInsets.fromLTRB(
                    80.0,
                    50.0,
                    80.0,
                    kTextTabBarHeight + 24.0,
                  )
                : EdgeInsets.fromLTRB(
                    80.0,
                    adaptivePadding.top,
                    80.0,
                    kTextTabBarHeight,
                  ),
            child: Flex(
              direction: isLandscape ? .horizontal : .vertical,
              mainAxisAlignment: .center,
              children: [
                Expanded(
                  child: Center(
                    child: _GameTile(
                      title: L10n.of(context)!.dodGameTileTitle,
                      subtitle: 'Kermit‘s',
                      imagePath: 'assets/images/DoD.png',
                      angle: _degToRad(5.0),
                      onTap: (tag) => _showDodGame(context, tag),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _GameTile(
                      title: L10n.of(context)!.dopGameTileTitle,
                      imagePath: 'assets/images/DoP.png',
                      textColor: Colors.black,
                      angle: _degToRad(-5.0),
                      onTap: (tag) => _showDeckOfPainGame(context, tag),
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
  final double angle;
  final Function(String)? onTap;

  const _GameTile({
    required this.title,
    this.subtitle,
    this.textColor,
    this.imagePath,
    this.angle = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22.0),
    child: Hero(
      tag: title,
      child: Transform.rotate(
        angle: angle,
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
                      style: Theme.of(context).textTheme.headlineSmall!
                          .copyWith(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                      textScaleFactor: min(
                        MediaQuery.textScalerOf(context).scale(1.0),
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
                      MediaQuery.textScalerOf(context).scale(1.0),
                      1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

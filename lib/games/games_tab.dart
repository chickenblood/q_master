import 'dart:math';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../utils/media_query.dart';

class GamesTab extends StatelessWidget {
  const GamesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).isLandscape;
    return SafeArea(
      child: Padding(
        padding: isLandscape
            ? const EdgeInsets.all(16.0)
            : const EdgeInsets.fromLTRB(80.0, 16.0, 80.0, 16.0),
        child: Flex(
          direction: isLandscape ? Axis.horizontal : Axis.vertical,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.rotate(
              angle: _degToRad(5.0),
              child: _GameTile(title: L10n.of(context)!.dodGameTileTitle),
            ),
            Transform.rotate(
              angle: _degToRad(-5.0),
              child: _GameTile(title: L10n.of(context)!.dodGameTileTitle),
            ),
          ],
        ),
      ),
    );
  }
}

double _degToRad(double degrees) => degrees * pi / 180.0;

class _GameTile extends StatelessWidget {
  final String title;

  const _GameTile({required this.title});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16.0),
      border: Border.all(
        color: Theme.of(context).colorScheme.onSurface,
        width: 1.0,
      ),
    ),
    child: AspectRatio(
      aspectRatio: 3 / 4,
      child: Center(child: Text(title, textAlign: TextAlign.center)),
    ),
  );
}

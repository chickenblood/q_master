import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/model/deck_of_pain.dart';
import 'package:q_master/model/pain_card.dart';
import 'package:q_master/ui/adaptive_icons.dart';
import 'package:q_master/ui/media_query.dart';

final class DeckOfPainGameView extends StatelessWidget {
  final String heroTag;

  const DeckOfPainGameView({super.key, this.heroTag = ''});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: Object() /* ignore heroTag for now */,
      child: PlatformScaffold(
        iosContentPadding: true, // Fixes app bar underlap for landscape.
        backgroundColor: Colors.black,
        appBar: PlatformAppBar(
          backgroundColor: Colors.transparent,
          leading: PlatformIconButton(
            icon: Icon(AdaptiveIcons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: PlatformText(
            L10n.of(context)!.dopGameScreenTitle,
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Center(child: _Deck()),
      ),
    );
  }
}

final class _Deck extends ConsumerStatefulWidget {
  const _Deck();

  @override
  ConsumerState<_Deck> createState() => _DeckState();
}

class _DeckState extends ConsumerState<_Deck> {
  bool isFlipped = true; // Start with the card face down.

  @override
  Widget build(BuildContext context) {
    ref.watch(deckOfPainProvider);
    final currentCard = ref.read(deckOfPainProvider.notifier).currentCard();
    if (currentCard == null) return Text('No more cards.');
    return Material(
      clipBehavior: .hardEdge,
      borderRadius: .circular(16.0),
      child: InkWell(
        onTap: () {
          final card = ref.read(deckOfPainProvider.notifier).drawCard();
          setState(() => isFlipped = card == null);
        },
        child: isFlipped
            ? const _BackCardView()
            : _FrontCardView(painCard: currentCard),
      ),
    );
  }
}

class _FrontCardView extends StatelessWidget {
  final PainCard painCard;

  const _FrontCardView({required this.painCard});

  Widget _buildText(
    BuildContext context, {
    required String text,
    required TextStyle style,
    required Color color,
  }) {
    return PlatformText(
      text,
      textAlign: .center,
      style: style.copyWith(fontWeight: FontWeight.bold, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaUtils.isLandscape(context);
    final textStyle = isLandscape
        ? TextTheme.of(context).displaySmall!
        : TextTheme.of(context).displayLarge!;
    return Container(
      color: Colors.white,
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            fit: .expand,
            children: [
              Align(
                alignment: Alignment.center,
                child: PlatformText(
                  painCard.description,
                  textAlign: TextAlign.center,
                  overflow: .fade,
                  maxLines: 5,
                  style: textStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: painCard.suit.color,
                  ),
                ),
              ),
              // Top left decoration
              Align(
                alignment: Alignment.topLeft,
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    _buildText(
                      context,
                      text: painCard.displayName,
                      style: textStyle,
                      color: painCard.suit.color,
                    ),
                    _buildText(
                      context,
                      text: painCard.suit.symbol,
                      style: textStyle,
                      color: painCard.suit.color,
                    ),
                  ],
                ),
              ),
              // Bottom right decoration
              Align(
                alignment: Alignment.bottomRight,
                child: Transform.rotate(
                  angle: pi, // Rotate 180 degrees
                  child: Column(
                    mainAxisSize: .min,
                    children: [
                      _buildText(
                        context,
                        text: painCard.displayName,
                        style: textStyle,
                        color: painCard.suit.color,
                      ),
                      _buildText(
                        context,
                        text: painCard.suit.symbol,
                        style: textStyle,
                        color: painCard.suit.color,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackCardView extends StatelessWidget {
  const _BackCardView();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16.0),
      image: DecorationImage(
        image: AssetImage('assets/images/card_back.png'),
        repeat: .repeat,
        fit: .contain,
      ),
    ),
    child: AspectRatio(aspectRatio: 2 / 3),
  );
}

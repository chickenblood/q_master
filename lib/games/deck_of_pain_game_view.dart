import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:q_master/model/deck_of_pain.dart';
import 'package:q_master/ui/adaptive_icons.dart';

final class DeckOfPainGameView extends StatelessWidget {
  final String heroTag;

  const DeckOfPainGameView({super.key, this.heroTag = ''});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: Object() /* ignore heroTag for now */,
      child: PlatformScaffold(
        backgroundColor: Colors.black,
        appBar: PlatformAppBar(
          backgroundColor: Colors.black,
          leading: PlatformIconButton(
            icon: Icon(AdaptiveIcons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Consumer(
            builder: (context, ref, _) {
              ref.watch(deckOfPainProvider);
              return Material(
                child: InkWell(
                  onTap: () {
                    ref.read(deckOfPainProvider.notifier).drawCard();
                  },
                  child: Text(
                    ref
                            .read(deckOfPainProvider.notifier)
                            .currentCard()
                            ?.displayName ??
                        'Tap to draw a card',
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

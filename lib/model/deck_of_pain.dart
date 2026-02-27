import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'pain_card.dart';
import 'pain_exercise_constants.dart';

part 'deck_of_pain.g.dart';

@riverpod
final class DeckOfPain extends _$DeckOfPain {
  @override
  Deck build() {
    final cards = <PainCard>[];

    // Initialize the deck with some PainCards
    for (final entry in painExercises.entries) {
      final suit = entry.key;

      for (final cardData in entry.value) {
        cards.add(
          PainCard(
            suit: suit,
            value: cardData.value,
            exercise: cardData.exercise,
            showRepCount: cardData.showRepCount,
          ),
        );
      }
    }
    cards.shuffle();
    return Deck(cards);
  }
}

final class Deck {
  final List<PainCard> cards;

  Deck(this.cards);

  /// Draws a card from the deck and returns it.
  PainCard? drawCard() {
    if (cards.isNotEmpty) {
      return cards.removeAt(0);
    }
    return null;
  }

  /// Returns the top card without removing it from the deck.
  PainCard? currentCard() => cards.isNotEmpty ? cards[0] : null;

  /// Returns the next card without removing it from the deck.
  PainCard? nextCard() => cards.length > 1 ? cards[1] : null;
}

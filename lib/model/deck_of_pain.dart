import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'pain_card.dart';
import 'pain_exercise_constants.dart';

part 'deck_of_pain.g.dart';

@riverpod
final class DeckOfPain extends _$DeckOfPain {
  /// Returns the top card and removes it from the deck.
  PainCard? drawCard() {
    if (state.isNotEmpty) {
      final result = currentCard();
      if (state.length > 1) {
        state = state.sublist(1);
      } else {
        state = [];
      }
      return result;
    }
    return null;
  }

  /// Returns the top card from the deck.
  PainCard? currentCard() => state.isNotEmpty ? state[0] : null;

  /// Returns the next card from the deck.
  PainCard? nextCard() => state.length > 1 ? state[1] : null;

  @override
  List<PainCard> build() {
    final deck = <PainCard>[];

    // Initialize the deck with some PainCards
    for (final entry in painExercises.entries) {
      final suit = entry.key;

      for (final cardData in entry.value) {
        deck.add(
          PainCard(
            suit: suit,
            value: cardData.value,
            exercise: cardData.exercise,
            showRepCount: cardData.showRepCount,
          ),
        );
      }
    }
    deck.shuffle();
    return deck;
  }
}

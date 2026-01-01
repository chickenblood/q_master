import 'dart:math';

import 'package:q_master/model/pain_card.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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

  @override
  List<PainCard> build() {
    final deck = <PainCard>[];

    final exercises = List.of(painExercises);
    final random = Random();

    // Initialize the deck with some PainCards
    for (var suit in Suit.values) {
      for (var i = 0; i <= 12; i++) {
        final removalIndex = random.nextInt(exercises.length);
        deck.add(
          PainCard(suit: suit, value: i + 1, exercise: exercises[removalIndex]),
        );
        exercises.removeAt(removalIndex);
      }
    }
    deck.shuffle();
    return deck;
  }
}

import 'package:q_master/model/pain_card.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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

    // Initialize the deck with some PainCards
    for (var suit in Suit.values) {
      for (var i = 1; i <= 13; i++) {
        // Face cards are worth 25. Ace is 50.
        final value = switch (i) {
          11 || 12 || 13 => 25,
          1 => 50,
          _ => i,
        };
        deck.add(
          PainCard(suit: suit, value: value, exercise: 'Side straddle hops'),
        );
      }
    }
    deck.shuffle();
    return deck;
  }
}

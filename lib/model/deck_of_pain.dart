import 'pain_card.dart';
import 'pain_exercise_constants.dart';

final class DeckOfPain {
  final cards = <PainCard>[];

  DeckOfPain() {
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
  }

  /// Draws a card from the deck and returns it.
  PainCard? drawCard() => cards.isNotEmpty ? cards.removeAt(0) : null;

  /// Returns the top card without removing it from the deck.
  PainCard? currentCard() => cards.isNotEmpty ? cards[0] : null;

  /// Returns the next card without removing it from the deck.
  PainCard? nextCard() => cards.length > 1 ? cards[1] : null;
}

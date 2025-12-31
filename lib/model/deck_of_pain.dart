import 'package:q_master/model/pain_card.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
final class DeckOfPain {
  final _deck = <PainCard>[];

  DeckOfPain() {
    // Initialize the deck with some PainCards
    for (var suit in Suit.values) {
      for (var i = 1; i <= 13; i++) {
        // Face cards are worth 25. Ace is 50.
        final value = switch (i) {
          11 || 12 || 13 => 25,
          1 => 50,
          _ => i,
        };
        _deck.add(
          PainCard(suit: suit, value: value, exercise: 'Side straddle hops'),
        );
      }
    }
    _deck.shuffle();
  }

  /// Returns the top card from the deck.
  PainCard? nextCard() => _deck.isNotEmpty ? _deck.removeAt(0) : null;

  List<PainCard> build() {
    return _deck;
  }
}

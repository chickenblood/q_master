import 'package:freezed_annotation/freezed_annotation.dart';

part 'pain_card.freezed.dart';

enum Suit {
  // TODO: Locaalize
  hearts('Hearts'),
  diamonds('Diamonds'),
  clubs('Clubs'),
  spades('Spades');

  final String name;
  const Suit(this.name);
}

/// Model class representing a card in the deck of pain.
@freezed
abstract class PainCard with _$PainCard {
  const factory PainCard({
    required Suit suit,
    required int value,
    required String exercise,
  }) = _PainCard;

  const PainCard._();

  /// The display name of the card.
  // TODO: Locaalize
  String get displayName {
    final valueName = switch (value) {
      1 => 'Ace',
      11 => 'Jack',
      12 => 'Queen',
      13 => 'King',
      _ => value.toString(),
    };
    return '$valueName of ${suit.name}';
  }
}

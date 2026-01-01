import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pain_card.freezed.dart';

enum Suit {
  hearts('Hearts', '♥'),
  diamonds('Diamonds', '♦'),
  clubs('Clubs', '♣'),
  spades('Spades', '♠');

  final String name;
  final String symbol;
  const Suit(this.name, this.symbol);

  Color get color => switch (this) {
    .hearts || .diamonds => Colors.red, // Red
    .clubs || .spades => Colors.black, // Black
  };
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
  String get displayName => switch (value) {
    1 => 'A',
    11 => 'J',
    12 => 'Q',
    13 => 'K',
    _ => value.toString(),
  };

  /// A description of the exercise associated with this card.
  String get description => '$_repCount $exercise';

  // The number of repetitions associated with this card.
  int get _repCount => switch (value) {
    11 || 12 || 13 => 25, // Face cards are worth 25
    1 => 50, // Ace is worth 50
    _ => value + 10,
  };
}

import 'package:freezed_annotation/freezed_annotation.dart';

import 'pain_exercise_constants.dart';

part 'pain_card.freezed.dart';

/// Model class representing a card in the deck of pain.
@freezed
abstract class PainCard with _$PainCard {
  const factory PainCard({
    required Suit suit,
    required int value,
    required String exercise,
    required bool showRepCount,
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
  String get description => showRepCount ? '$_repCount $exercise' : exercise;

  // The number of repetitions associated with this card.
  int get _repCount => switch (value) {
    11 || 12 || 13 => 25, // Face cards are worth 25
    1 => 100, // Ace is worth 100
    _ => value + 10,
  };
}

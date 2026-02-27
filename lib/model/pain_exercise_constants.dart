/// Four equal-sized lists of Deck of Pain exercises, representing the
/// four suits in a deck (hearts, clubs, diamond, spades).
library;

import 'package:flutter/material.dart';

enum Suit {
  hearts('Hearts', '♥'),
  clubs('Clubs', '♣'),
  diamonds('Diamonds', '♦'),
  spades('Spades', '♠');

  final String name;
  final String symbol;
  const Suit(this.name, this.symbol);

  Color get color => switch (this) {
    .hearts || .diamonds => Colors.red, // Red
    .clubs || .spades => Colors.black, // Black
  };
}

typedef CardData = ({String exercise, int value, bool? showRepCount});

const painExercises = {
  Suit.hearts: [
    (exercise: 'Side straddle hops', value: 1, showRepCount: true),
    (exercise: 'Sprint 200m', value: 2, showRepCount: false),
    (exercise: 'Sprint 300m', value: 3, showRepCount: false),
    (exercise: 'Sprint 400m', value: 4, showRepCount: false),
    (exercise: 'Carioca (Q set distance)', value: 5, showRepCount: false),
    (exercise: 'Backward run (Q set distance)', value: 6, showRepCount: false),
    (exercise: 'Bear crawl (Q set distance)', value: 7, showRepCount: false),
    (exercise: 'Squat thrust', value: 8, showRepCount: true),
    (exercise: 'High knee', value: 9, showRepCount: true),
    (exercise: 'Butt kick', value: 10, showRepCount: true),
    (exercise: 'Plank jack', value: 11, showRepCount: true),
    (exercise: 'Burpee', value: 12, showRepCount: true),
    (exercise: 'Mtn climber', value: 13, showRepCount: true),
  ],
  Suit.clubs: [
    (exercise: 'Flutter kick', value: 1, showRepCount: true),
    (exercise: 'WWII situp', value: 2, showRepCount: true),
    (exercise: 'High, slow flutter kick', value: 3, showRepCount: true),
    (exercise: 'Heels to heaven', value: 4, showRepCount: true),
    (exercise: 'Oblique crunch (15 each side)', value: 5, showRepCount: false),
    (exercise: 'Low plank (60 sec)', value: 6, showRepCount: false),
    (exercise: 'Lil baby crunch', value: 7, showRepCount: true),
    (exercise: 'Luge', value: 8, showRepCount: true),
    (exercise: 'High plank (90 sec)', value: 9, showRepCount: false),
    (exercise: 'Rosalita', value: 10, showRepCount: true),
    (exercise: 'Shoulder tap', value: 11, showRepCount: true),
    (exercise: 'Freddie Mercury', value: 12, showRepCount: true),
    (exercise: 'American hammer', value: 13, showRepCount: true),
  ],
  Suit.diamonds: [
    (exercise: 'Arm circle', value: 1, showRepCount: true),
    (exercise: 'Hand clap merkin', value: 2, showRepCount: true),
    (exercise: 'Chuck Norris merkin', value: 3, showRepCount: true),
    (exercise: 'Carolina dry dock', value: 4, showRepCount: true),
    (exercise: 'Hand-release merkin', value: 5, showRepCount: true),
    (exercise: 'Wide-arm merkin', value: 6, showRepCount: true),
    (exercise: 'Derkin', value: 7, showRepCount: true),
    (exercise: 'Merkin', value: 8, showRepCount: true),
    (exercise: 'Ranger Merkin', value: 9, showRepCount: true),
    (exercise: 'Incline Merkin', value: 10, showRepCount: true),
    (exercise: 'Dip', value: 11, showRepCount: true),
    (exercise: 'Diamond merkin', value: 12, showRepCount: true),
    (exercise: 'Merkin', value: 13, showRepCount: true),
  ],
  Suit.spades: [
    (exercise: 'Calf raise', value: 1, showRepCount: true),
    (exercise: 'Bulgarian split squat', value: 2, showRepCount: true),
    (exercise: 'Wojo squat', value: 3, showRepCount: true),
    (exercise: 'Alternating side squat', value: 4, showRepCount: true),
    (exercise: 'Standing lunge', value: 5, showRepCount: true),
    (exercise: 'Jumping lunge', value: 6, showRepCount: true),
    (exercise: 'Monkey humper', value: 7, showRepCount: true),
    (exercise: 'Backward lunge', value: 8, showRepCount: true),
    (exercise: 'Low, slow squat', value: 9, showRepCount: true),
    (exercise: 'Lunge walk 100m', value: 10, showRepCount: false),
    (exercise: 'Smurf jack', value: 11, showRepCount: true),
    (exercise: 'Monkey humper', value: 12, showRepCount: true),
    (exercise: 'Squat', value: 13, showRepCount: true),
  ],
};

import 'dart:math';

import 'package:flutter/material.dart';

extension Utils on TextEditingValue {
  static const _emptyResult = ('', TextRange.empty);

  /// Returns the word that is currently being composed at the caret position
  ///
  /// Returns the word and its range in the entire text string.
  (String, TextRange) currentComposedWord() {
    // Do not perform completions if there is a selection.
    if (!selection.isCollapsed) return _emptyResult;

    // Get the current word being typed by the user.
    final caretIndex = selection.baseOffset;

    // Find whitespace or beginning of line.
    var wordStart =
        text.lastIndexOf(
          RegExp(r'(^|\s)', multiLine: true),
          max(caretIndex - 1, 0),
        ) +
        1;
    if (wordStart > caretIndex) return _emptyResult;

    // Find whitespace or end of line.
    var wordEnd = text.indexOf(
      RegExp(r'(\$|\n|\s)', multiLine: true),
      caretIndex,
    );
    if (wordEnd == -1) wordEnd = text.length;

    final precedingText = text.substring(wordStart, caretIndex);
    if (wordStart != wordEnd && caretIndex == wordEnd) {
      final replacementRange = TextRange(start: wordStart, end: caretIndex);
      debugPrint(
        'wordStart: $wordStart, wordEnd: $wordEnd, '
        'caret index: $caretIndex, '
        'replacementRange: $replacementRange, '
        'currentComposedText: $text '
        'precedingText: $precedingText',
      );
      return (precedingText, replacementRange);
    }
    return _emptyResult;
  }
}

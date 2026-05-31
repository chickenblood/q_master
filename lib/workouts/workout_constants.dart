import 'package:flutter/widgets.dart';

import '../l10n/l10n.dart';

enum ExerciseCategory {
  core,
  cardio,
  strength,
  chest,
  shoulders,
  legs,
  arms,
  coupon,
  fullBody;

  /// Returns a localized display label for this exercise category.
  String displayLabel(BuildContext context) {
    final l10n = L10n.of(context)!;
    return switch (this) {
      .core => l10n.exerciseCategoryCoreLabel,
      .cardio => l10n.exerciseCategoryCardioLabel,
      .strength => l10n.exerciseCategoryStrengthLabel,
      .chest => l10n.exerciseCategoryChestLabel,
      .shoulders => l10n.exerciseCategoryShouldersLabel,
      .legs => l10n.exerciseCategoryLegsLabel,
      .arms => l10n.exerciseCategoryArmsLabel,
      .coupon => l10n.exerciseCategoryCouponLabel,
      .fullBody => l10n.exerciseCategoryFullBodyLabel,
    };
  }
}

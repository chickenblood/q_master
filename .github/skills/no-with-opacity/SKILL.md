# Never Use withOpacity for Colors

**Rule:** Do not use `.withOpacity()` on `Color` objects. Always use `.withValues(alpha: ...)` instead.

## Why?
- `.withOpacity()` is deprecated and less explicit.
- `.withValues(alpha: ...)` is the preferred, future-proof, and more readable method for setting alpha on a color.

## Examples

**✅ Correct:**
```dart
final faded = color.withValues(alpha: 0.38);
```

**❌ Incorrect:**
```dart
final faded = color.withOpacity(0.38); // Do NOT use
```

## Migration
- Replace all usages of `.withOpacity(x)` with `.withValues(alpha: x)`.
- Audit PRs and reviews for `.withOpacity` and reject if found.

## Linting
- If a linter is available, add a rule to flag `.withOpacity` usage.

## Context
- Applies to all Dart/Flutter code in this repository.
- Applies to all color manipulations, including theme, widget, and custom color logic.

---
**Summary:**
> Use `withValues(alpha: ...)` for all color alpha adjustments. Never use `withOpacity()`.

# Q Master - AI Coding Instructions

Q Master is a Flutter app for managing F3 workout routines. Targets all platforms with adaptive UI.

## Design Principles: The Gloom

F3 beatdowns happen at 5:30am in the dark, cold, and rain. Design for:

- **Darkness** — Pre-dawn with no sun. High contrast, audio-first.
- **Cold hands** — Gloves, frozen fingers. Forgiving inputs.
- **Constant movement** — Q is moseying, crawling, circling. Glanceable, hands-free.
- **Any weather** — Rain, heat, humidity. Offline-first, battery conscious.
- **The circle** — PAX spread out, stations rotating. Visible and audible at distance.
- **Simplicity** — No time for complexity. Minimal screens, big buttons, clear text.
- **F3 Lexicon** — Use authentic terminology and exercise names.

## Platform-Adaptive UI

**Always use `flutter_platform_widgets`** (`PlatformScaffold`, `PlatformAppBar`, `PlatformText`, etc.) instead of raw Material/Cupertino widgets.

For platform-specific behavior (see [main.dart#L44](lib/main.dart#L44)):
```dart
if (Theme.of(context).platform == TargetPlatform.iOS) { /* showCupertinoSheet */ }
else { /* Navigator.push with platformPageRoute */ }
```

## State & Models

- **Riverpod**: Providers in model files, access via `ref.watch()`/`ref.read()` in `ConsumerWidget`
- **Freezed**: After modifying `@freezed` classes, run: `dart run build_runner build --delete-conflicting-outputs`

## Key Patterns

| Pattern | Usage |
|---------|-------|
| `AdaptiveIcons` | Platform icons ([adaptive_icons.dart](lib/ui/adaptive_icons.dart)) |
| `AdaptiveMenu` | iOS `PullDownButton` / Material `MenuAnchor` ([adaptive_menu.dart](lib/ui/adaptive_menu.dart)) |
| `adaptiveAlertAction()` | Alert buttons ([adaptive_alert.dart](lib/ui/adaptive_alert.dart)) |
| `L10n.of(context)!.key` | Localization from [app_en.arb](lib/l10n/app_en.arb) |

## Development Practices

**ALWAYS:** Leave code better than you found it, acting as a steward for future maintainers and top 1% Flutter expert with a deep appreciation for beautiful, maintainable code.

### Pre-Commit Checklist
- [ ] `flutter pub get` — if `pubspec.yaml` changed
- [ ] `dart run build_runner build --delete-conflicting-outputs` — if freezed models changed
- [ ] `flutter analyze` — no warnings or errors *(always)*
- [ ] `flutter test` — all tests pass *(always)*
- [ ] `cd ios && pod install` — if plugins changed (iOS only)
- [ ] `flutter run` — verify on target device/simulator

### Code Quality
- Write widget tests for new screens

### iOS Development
- Check `ios/Runner/Info.plist` for required permissions (camera, photos, etc.)

### MCP Tools (when connected)
| Task | Tool |
|------|------|
| Hot reload after changes | `hot_reload` |
| Inspect widget tree | `get_widget_tree` |
| Check runtime errors | `get_runtime_errors` |
| Add packages | `pub` with `add` command |
| Launch on device | `launch_app` with device ID |

### Debugging Workflow
1. Reproduce issue with hot reload enabled
2. Use `get_runtime_errors` to capture stack traces
3. Inspect widget tree for state mismatches
4. Check logs via `get_app_logs` for platform channel errors

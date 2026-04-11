# Q Master

Q Master. An app to manage your F3 workouts  (digital weinke)

## Why Flutter?
I chose Dart/Flutter over native Swift or Kotlin development, so that we can keep changes in lockstep and get them out to iOS and Android users with minimal additional effort. It is by far the, fastest most productive cross-platform development framework I have ever used and perfect for a small team.
Downside: Dart is not a well-known language, but it is very similar to modern languages like Typescript, Swift and Kotlin and it's super-easy to learn.

## A note on platform widgets
Flutter uses "Material Design" by default which is the standard design language for Android. All [widgets](https://docs.flutter.dev/ui/widgets/material) in the flutter/material library support this design system.

Flutter also has a set of "Cupertino" [widgets](https://docs.flutter.dev/ui/widgets/cupertino) in the flutter/cupertino library which mimic Apple's iOS look and feel.

Since I'm a UX purist, I prefer to have the UI look native to the platform where it is used and have iOS users feel at home, so this codebase makes liberal use of:

* Adaptive widgets in the Flutter framework: Switch.adaptive, Slider.adaptive, etc. which wrap the Flutter Material and Cupertino widgets. More examples [here](https://docs.flutter.dev/ui/adaptive-responsive/platform-adaptations#widgets-with-adaptive-constructors)

* Adaptive icons, i.e. Icons.adaptive.more, Icons.adaptive.settings, etc.

* The [flutter_platform_widgets](https://pub.dev/packages/flutter_platform_widgets) package, which wraps equivalent higher-level widgets for both platforms and gives you a simple API to target both.
  * Use PlatformText rather than Text
  * Use PlatformScaffold rather than Scaffold
  * Use PlatformAppBar rather than AppBar
  * Use PlatformIconButton rather than IconButton
  * Use PlatformTextButton rather than TextButton
  * Use PlatformListTile rather than ListTile

In addition, I've added some helper classes that fills any gaps that the utilities above don't fill. See the following in the ui/ directory:

* adaptiveAlertAction for use with Flutter's AlertDialog.adaptive to style the buttons correctly.
* AdaptiveIcons for those not covered by Flutter Icons.adaptive and PlatformIcon.
* AdaptiveMenu (uses the [pull_down_button](https://pub.dev/packages/pull_down_button) package) for a better iOS-styled popup menu.
* showAdaptiveModalSheet that presents full-screen modals in the iOS modal sheet style (with a perspective transform, revealing the content below).

Despite all this, iOS 26 brings [Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass) which is a complete overhaul of the iOS design system, and which will unfortunately make things look a little dated, *for now* :/

## Workout JSON Format

Workouts are persisted to `workouts.json` in the app's documents directory and synced to the paired watch via WatchConnectivity / Wearable Data Layer. The file is a JSON array of workout objects.

### Schema

| Field | Type | Description |
|-------|------|-------------|
| `name` | `string` | Display name of the workout |
| `date` | `string` | ISO-8601 timestamp, e.g. `2026-03-29T05:30:00.000` |
| `sections` | `array` | Ordered list of section objects; each section has a `name` string and an `exercises` string array |

Section names are arbitrary strings. By convention the three standard F3 sections are used (`warmup`, `thang`, `mary`), but any names are valid. Order is preserved through all serialization round-trips.

### Example

```json
[
  {
    "name": "The Bear Crawl Beatdown",
    "date": "2026-03-29T05:30:00.000",
    "sections": [
      {
        "name": "warmup",
        "exercises": ["SSH", "Imperial Walkers", "Arm Circles"]
      },
      {
        "name": "thang",
        "exercises": ["Bear Crawl", "Merkins", "Lunges"]
      },
      {
        "name": "mary",
        "exercises": ["LBCs", "Flutter Kicks"]
      }
    ]
  }
]
```

### Backward Compatibility

The app can read files written by older versions of the app. Legacy layouts are migrated on read and re-written in the current format on next save:

- **v1 (legacy)** — `warmup`, `thang`, and `mary` as top-level keys on the workout object, with section values as either `{ "name": "..." }` objects or plain strings.
- **v2 (current)** — `sections` as an ordered array of section objects (`{ "name": "...", "exercises": ["..."] }`), preserving section order across all platforms.

### Building the app for the Play Store

Build Android app:
  `flutter build appbundle`
  The output AAB will be under

Build Wear app:
  `cd android && ./gradlew :watchapp:bundleRelease`
  The output AAB will be under android/watchapp/build/outputs/bundle/release

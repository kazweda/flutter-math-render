# flutter-math-render

Verification lab for [flutter_math_fork](https://pub.dev/packages/flutter_math_fork) on the latest stable Flutter.

- High-school math and chemistry formula set: `lib/formulas.dart`
- Markdown integration (`$...$` inline, `$$...$$` block) on top of flutter_markdown_plus: `lib/markdown_math.dart`
- Gallery app for visual checks on a device: `lib/main.dart`
  - Open a specific tab on launch: `flutter run --dart-define=TAB=0|1|2`

## Checks

```bash
dart format lib test
flutter analyze
flutter test
```

## Switching the flutter_math_fork source

To verify an upstream PR or a fork, override the dependency in `pubspec.yaml` and rerun the checks.

```yaml
dependency_overrides:
  flutter_math_fork:
    git:
      url: https://github.com/simpleclub/flutter_math
      ref: <commit SHA>
```

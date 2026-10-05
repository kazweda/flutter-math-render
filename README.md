# flutter-math-render

Verification lab for [flutter_math_fork](https://pub.dev/packages/flutter_math_fork) on the latest stable Flutter.

**Web demo: https://kazweda.github.io/flutter-math-render/** — try the rendering and the SelectableMath fixes in a browser without building anything.

- High-school math and chemistry formula set: `lib/formulas.dart`
- Markdown integration (`$...$` inline, `$$...$$` block) on top of flutter_markdown_plus: `lib/markdown_math.dart`
  - When selectable, Copy puts inline formulas on the clipboard as `$...$` and a selected part of a block formula as TeX
- Gallery app for visual checks on a device: `lib/main.dart`
  - Open a specific tab on launch: `flutter run --dart-define=TAB=0|1|2`
  - Start in Japanese: `flutter run --dart-define=LANG=ja`

## Sample content

Sample content comes in English and Japanese, as a real app with math would ship both: formula labels in `lib/formulas.dart` and Markdown samples in `lib/samples.dart`. Switch between them with the EN / JA toggle in the app bar. The Japanese samples check math mixed with CJK text (line height, wrapping, `$` detection next to Japanese characters), and the formula set follows the Japanese high-school curriculum.

## Checks

```bash
dart format lib test
flutter analyze
flutter test
```

CI (`.github/workflows/ci.yml`) runs the same checks on Ubuntu for every pull request, excluding golden tests (`--exclude-tags golden`). `main` is protected: changes go through a pull request with CI passing.

Golden images (`test/goldens/`) are rendered with the real KaTeX fonts (loaded in `test/flutter_test_config.dart`). They are generated on macOS and only comparable on the same host platform, so run them locally (`flutter test --tags golden`). After an intentional rendering change:

```bash
flutter test --update-goldens test/golden_test.dart
```

## Web demo

`.github/workflows/pages.yml` builds the gallery app for the web on every push to `main` and deploys it to GitHub Pages. To try the web build locally:

```bash
flutter run -d chrome
```

On web, copying inline formulas from the selectable Markdown body doesn't work yet: with a mouse, the browser handles both ⌘C / Ctrl+C and the right-click Copy, so the clipboard gets U+FFFC (shown as a blank) instead of `$...$`. Selecting and copying block formulas works.

## Switching the flutter_math_fork source

To verify an upstream PR or a fork, override the dependency in `pubspec.yaml` and rerun the checks.

```yaml
dependency_overrides:
  flutter_math_fork:
    git:
      url: https://github.com/simpleclub/flutter_math
      ref: <commit SHA>
```

## License

MIT. See [LICENSE](LICENSE).

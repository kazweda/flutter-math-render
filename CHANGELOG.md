# Changelog

All notable changes to this lab are documented here. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

This is a verification app, not a published package (`publish_to: 'none'`). Versions mark points worth referring to, for example from upstream comments or the web demo. Pull request numbers refer to this repository unless noted.

## [0.4.0] - 2026-10-05

### Added
- Web platform and a GitHub Pages deployment of the gallery app (`.github/workflows/pages.yml`) (#20).

### Fixed
- Copying inline formulas with ⌘C / Ctrl+C put U+FFFC on the clipboard instead of `$...$`, and on web the right-click Copy did too. The keyboard shortcut now copies TeX, and the web app shows the Flutter context menu instead of the browser's (#22).

## [0.3.0] - 2026-10-05

### Added
- MIT license (#12).
- Sample content in English and Japanese: formula labels and Markdown samples, with an EN / JA toggle in the app bar and `--dart-define=LANG=ja` (#14).
- Verification notes for upstream simpleclub/flutter_math#127 (`docs/upstream-prs/selection-toolbar.md`) (#17).
- This changelog, and versions starting from 0.x.

### Changed
- The repository is English-first: docs, code comments, commits and pull requests (#14). The verification notes for #111 / #112 / #122 are translated (#14).
- CI uses `actions/checkout@v7` (#13).

### Fixed
- SelectableMath toolbar buttons didn't receive taps on iOS devices with a top safe area, so Select All and Copy cleared the selection instead. Uses kazweda/flutter_math@f5385aa (#15).
- Copying selectable Markdown put U+FFFC in place of inline formulas. The toolbar's Copy now writes them as `$tex$` (#16).

## [0.2.0] - 2026-10-04

### Added
- Verification notes for upstream simpleclub/flutter_math #111, #112 and #122 (`docs/upstream-prs/layout-callback-mixin.md`) (#11).

### Fixed
- SelectableMath brought up the software keyboard on Android when tapped (#5).
- SelectableMath's toolbar Copy and Select all threw `NoSuchMethodError` (#7).
- Long-pressing a SelectableMath threw on iOS (`bringIntoView` not implemented). The app now uses the fork kazweda/flutter_math@6ec49b7, which fixes all three problems in the package, and the app-side workarounds from #5 and #7 are removed (#10).

## [0.1.0] - 2026-10-03

### Added
- High-school math (26) and chemistry (6) formula set, and a gallery app to check them on a device.
- Markdown integration on top of flutter_markdown_plus: `$...$` inline and `$$...$$` block math, with currency such as `$5 and $10` left as text.
- Block formulas are rendered with SelectableMath when the Markdown body is selectable.
- Golden tests rendered with the real KaTeX fonts.
- CI on GitHub Actions: format, analyze and tests on Ubuntu, excluding goldens (#6).

[0.4.0]: https://github.com/kazweda/flutter-math-render/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/kazweda/flutter-math-render/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/kazweda/flutter-math-render/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/kazweda/flutter-math-render/releases/tag/v0.1.0

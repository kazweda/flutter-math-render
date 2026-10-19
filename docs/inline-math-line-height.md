# Tall inline formulas and the forced strut

Verified: 2026-10-19 / Target: flutter_markdown_plus 1.0.12, compared with kazweda/flutter_markdown_plus `6fcde7c`
Environment: Flutter 3.47.7, widget tests, iOS simulator (iPhone Air)

## Problem

A tall inline formula (`$...$`) doesn't make its line taller in `MarkdownMathBody`. It sticks out of its block and overlaps the heading or line above and below. Found in kazweda/math-memo-app#12 with the quadratic formula, a limit, a sum and `\begin{cases}`. Block formulas (`$$...$$`) are not affected: written as blocks, the same formulas keep the right spacing.

## Cause

flutter_markdown_plus 1.0.8 forces a fixed line height on every text block, so that bold text no longer shifts the line height. `_buildRichText` in `lib/src/builder.dart` passes `StrutStyle(forceStrutHeight: true)`, derived from the block's own style. `InlineMathBuilder` returns `Text.rich` with a `WidgetSpan`, which the package merges into the block's `Text.rich`, so the forced strut also applies to the line with the formula. The app has no way to turn it off, and going back to 1.0.7 would lose `contextMenuBuilder` (added in 1.0.10).

## Fix (kazweda/flutter_markdown_plus)

Branch `fix/widget-span-line-height`, from v1.0.12. A block whose `TextSpan` contains a `WidgetSpan` keeps the strut as a minimum line height (`forceStrutHeight: false`). Text-only blocks still force it, so the 1.0.8 fix for bold text stays. One test added to `test/text_test.dart`: a 60 px inline widget stays inside its paragraph.

The package's own tests pass, except its 3 golden tests, which fail on Flutter 3.47.7 with or without the change.

## Results

`test/line_height_test.dart`: five tall formulas (quadratic formula with `\frac` and with `\dfrac`, limit, sum, `cases`), each in a paragraph, a heading and a list item, plain and selectable (30 cases). Each checks that the formula stays inside its block.

| | 1.0.12 | Fork |
|---|---|---|
| `line_height_test.dart` | ❌ 30 of 30 fail. The formula sticks out above its block by about 8–20 px | ✅ all pass |
| Rest of the lab tests (goldens included) | ✅ | ✅ |
| math-memo-app tests (87) | ✅ | ✅ |

On the iOS simulator, math-memo-app with the fork shows the notes from kazweda/math-memo-app#12 (the ten formulas inline and as blocks, and tall inline formulas in paragraphs, headings and lists) with no overlaps.

## Side effect

A block with any inline formula no longer forces its strut, so a line with a small formula such as `$a + b = c$` can be a bit taller than a text-only line (20 → 26 px in a widget test), as before 1.0.8. Nothing looked off in the simulator check above.

## Upstream

foresightmobile/flutter_markdown_plus has had no commits since 2026-07-10. No upstream PR. Whether to open an issue is decided separately.

# #128: `\bcancel` and `\xcancel` not rendering

Verified: 2026-10-08 / Target: simpleclub/flutter_math #128 (`98d7721`), compared with kazweda/flutter_math `f5385aa` (main + SelectableMath fixes)
Environment: Flutter 3.47.5, widget tests

The problem was reproduced on current code. #128's fix was checked by reading the diff, not by running it.

## Conclusion

- The bug is real: `\bcancel` draws no line and `\xcancel` draws neither line.
- #128's two one-line fixes are both needed and look correct.
- Of the PRs verified so far, this is the only one that is small, correct on current Flutter, mergeable, and has a signed CLA.

## Reproduction (tested)

`Math.tex('<cmd>{x}')`, counting the `LinePainter` widgets that draw the diagonals:

| Command | Parsed `notation` | Diagonals drawn | Expected |
|---|---|---|---|
| `\cancel` | `['updiagonalstrike']` | 1 | 1 ✅ |
| `\bcancel` | `['downdiagonalstrike']` | 0 | 1 ❌ |
| `\xcancel` | `['updiagonalstrike, downdiagonalstrike']` (one string) | 0 | 2 ❌ |
| `\sout` | `['horizontalstrike']` | 0 (drawn by `HorizontalStrikeDelegate`) | 0 ✅ |

## Cause (from reading the code)

1. `lib/src/ast/nodes/enclosure.dart` checks `notation.contains('downdiagnoalstrike')` (typo), while the parser produces `'downdiagonalstrike'`. So the down diagonal is never drawn.
2. `lib/src/parser/tex/functions/katex_base/enclose.dart` maps `\xcancel` to `['updiagonalstrike, downdiagonalstrike']`, a single string, so neither `contains` check matches.

Fixing only 1 leaves `\xcancel` blank; fixing only 2 gives `\xcancel` the up diagonal only. #128 fixes both.

## Notes

- The doc comment on `EnclosureNode.notation` (`enclosure.dart` line 29) has the same typo (`'downdiagnoalstrike'`). #128 doesn't touch it; harmless.
- #128 has no test. A widget test like the one above would fail on main and pass with the fix.
- CLA signed, CodeRabbit had no comments, no conflicts (2026-10-08).

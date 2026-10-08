# Math inside SelectionArea

Verified: 2026-10-08 / flutter_math_fork: kazweda/flutter_math `f5385aa` (0.7.4 + SelectableMath fixes) / Flutter 3.47.5
Devices: iPad (A16, iPadOS 27.0.1), Chrome on macOS with a mouse, widget tests
Issue: #23 / PRs: #30, #31, #32, #33, #34

## Why

With `MarkdownBody(selectable: true)`, each paragraph is its own `SelectableText`, so a selection can't span paragraphs. An app that wants that wraps the content in `SelectionArea` instead. This page records how flutter_math_fork's `Math` behaves there, and what the lab does about it.

Try it in the gallery: Markdown tab → **SelectionArea**.

## Conclusion

- `Math` doesn't implement `Selectable`, so `SelectionArea` skips it: a formula isn't highlighted and is left out of the copy entirely (not even U+FFFC).
- The lab wraps each formula in `MathSelectionAdapter` (`lib/math_selection.dart`), which makes it one selectable unit that copies as its TeX.
- `SelectionArea` also joins paragraphs with nothing in between. `LineBreakSelectionContainer` puts each block on its own line.
- Result for a whole sample:

  ```
  Quadratic equations
  The solutions of $ax^2 + bx + c = 0$ are:
  $$x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}$$
  • Two distinct real roots if the discriminant $D = b^2 - 4ac$ satisfies $D > 0$
  • A double root when $D = 0$
  ```

## Before (#30)

| What | Result |
|---|---|
| Selection across paragraphs | ✅ works |
| Inline and block formulas in the copy | ❌ left out: `First $a^2$ end.` copies as `First  end.` |
| A plain `Text` in a `WidgetSpan`, for comparison | ✅ copied |
| Line breaks between paragraphs | ❌ none (`end.Second`); `SelectionArea` itself, with or without math |
| Block formula as `SelectableMath` inside `SelectionArea` | ❌ also left out |

Same on the iPad.

## What the lab adds

### MathSelectionAdapter (#31, #33)

Based on Flutter's `SelectableRegion` API sample (`examples/api/lib/material/selectable_region/selectable_region.0.dart`). It registers the formula with the enclosing `SelectionArea` as one `Selectable`:

- A formula is either wholly selected or not at all. Partial selection (for example only `x = `) isn't possible; the **selectable** mode with `SelectableMath` still allows it.
- Selected formulas are highlighted with the selection color, and copy as `$tex$` (inline) or `$$tex$$` (block).
- Its child's own selection is disabled, so only the TeX is copied.
- Outside a `SelectionArea` it returns the child unchanged.

Fix found on the way (#33): a scroll view sends its selectables an edge update at `Offset.infinite` when a selection from outside passes through it ("past the end of everything here"). Block formulas sit in a horizontal `SingleChildScrollView`, so the adapter got a NaN position, answered "previous", and a mouse drag stopped at the first block formula. The adapter now treats a non-finite position as past the end. Flutter's API sample has the same gap. Touch selection wasn't affected.

### LineBreakSelectionContainer (#32, #34)

A `SelectionContainer` around the Markdown body whose delegate (a `StaticSelectionContainerDelegate`) joins the selected blocks:

- with a line break between blocks stacked vertically (headings, paragraphs, block formulas);
- with a space between blocks side by side (a list item's marker and its text, which flutter_markdown_plus builds as two widgets in a `Row`).

Inline formulas register with their paragraph's own container, so they stay in the paragraph's line.

## Device checks

| Check | iPad | Chrome + mouse |
|---|---|---|
| Selection across paragraphs, formulas highlighted | ✅ | ✅ |
| Copy has formulas as TeX, one block per line | ✅ | ✅ |
| Long press on a block formula selects just that formula | ✅ | — |
| Drag past a block formula | ✅ | ✅ (after #33) |
| List items on one line | ✅ | — |

Mouse drags don't switch the gallery's tabs (Flutter doesn't drag-scroll with a mouse by default).

## Limits

- The copy is plain text: bold and other formatting are lost, list markers copy as `•` rather than `-`, and an escaped `\$x\$` copies as `$x$` (what's shown), which reads as math if pasted back as Markdown.
- Select All selects everything in the `SelectionArea` (Flutter's behavior).
- In widget tests, a nested `SelectionContainer` registers with the area a frame after its children, so tests pump once more before selecting.

## Upstream

Kept in the lab for now:

- The ideal fix is for `Math` itself to take part in a `SelectionArea` (it could copy `ast.greenRoot` encoded as TeX). But upstream isn't merging feature work at the moment, and the `$...$` / `$$...$$` delimiters here are a Markdown convention, not something `Math` knows about.
- The `Offset.infinite` gap is in Flutter's API sample, not in flutter_math_fork.

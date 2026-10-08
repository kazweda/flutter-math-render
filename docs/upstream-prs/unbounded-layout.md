# #121: unbounded layout errors

Verified: 2026-10-08 / Target: simpleclub/flutter_math #121 (`c49b340`), compared with kazweda/flutter_math `f5385aa` (main + SelectableMath fixes)
Environment: Flutter 3.47.5, widget tests

#121's code was **not run** here: running an unknown account's fork as a dependency was blocked by this session's safety check, and the conclusion doesn't depend on it. Results below are marked as either *tested* (lab code only) or *from reading the diff*.

## Conclusion

- The reported errors **don't reproduce** on current Flutter (*tested*).
- #121 **can't compile on Flutter 3.32 or later** (*from reading the diff*): it includes `bd30a5f`, a commit by another author with exactly the same diff as #111, which removes `RenderObjectWithLayoutCallbackMixin`. See [layout-callback-mixin.md](layout-callback-mixin.md).
- The one related error that does reproduce (`\left...\right` under `IntrinsicHeight`) **isn't fixed** by #121 (*from reading the diff*).
- Same verdict as #111 / #112 / #122: not mergeable on current Flutter. The right fix for older Flutter is #133 (pin 0.7.3 below 3.32).

## What #121 changes

Two commits on top of `2f270ae` (#109):

| Commit | Change |
|---|---|
| `bd30a5f` (Daksh Vasudev, 2025-06) | Removes `RenderObjectWithLayoutCallbackMixin` and `runLayoutCallback()` from `_RenderLayoutBuilderPreserveBaseline`. Identical to #111 |
| `c49b340` (ss0314, 2025-09) | `sqrt.dart` and `left_right.dart`: `LayoutBuilderPreserveBaseline` → `LayoutBuilder`. `left_right.dart`: a delimiter returns `BoxConstraints(minHeight: 20)` when height or depth isn't finite. `line.dart`: `RenderLine` lays out children with `constraints.loosen()` instead of `infiniteConstraint`, and adds an unused `LineParentData.constraints` field |

## Reproduction attempt (tested)

`Math.tex` and `SelectableMath.tex` with `\sqrt{x}`, `\sqrt{\frac{a}{b}}`, `\left(\frac{a}{b}\right)`, `\left[ x^2 \right]` and `\sqrt[3]{x+1} = \left\{ \frac{1}{2} \right\}`, each inside `Column`, `ListView`, `SingleChildScrollView`, `Row`, `UnconstrainedBox`, `Column > Row` and `IntrinsicHeight` (70 cases):

| Host | Result |
|---|---|
| `Column`, `ListView`, `SingleChildScrollView`, `Row`, `UnconstrainedBox`, `Column > Row` | ✅ no errors |
| `IntrinsicHeight` with `\left...\right` | ❌ "LayoutBuilder does not support returning intrinsic dimensions" |
| `IntrinsicHeight` with `\sqrt` only | ✅ no errors |

The errors #121 describes ("`_RenderLayoutBuilderPreserveBaseline` object was given an infinite size during layout") didn't show up anywhere.

## Reading the diff

- **Compile error on 3.32+.** `RenderConstrainedLayoutBuilder` is declared `on RenderObjectWithChildMixin, RenderObjectWithLayoutCallbackMixin`, so removing the mixin breaks the build, as tested for #111.
- **Likely origin of the reported errors (inference).** On Flutter 3.29, #111's change makes `LayoutBuilderPreserveBaseline` never call its builder, so √ and `\xrightarrow` aren't drawn and parts of them spread across the screen (tested in layout-callback-mixin.md). #121 replaces it with `LayoutBuilder` for √ and `\left...\right` only, which looks like a workaround for that side effect rather than for a bug on main. `stretchy_op.dart` (`\xrightarrow`) still uses `LayoutBuilderPreserveBaseline`.
- **Intrinsics.** Flutter's `LayoutBuilder` doesn't support intrinsic dimensions either, so the `IntrinsicHeight` error stays.
- **Side effects.** `LayoutBuilder` doesn't pass the child's baseline up, so √ and delimiters may lose their baseline alignment. `constraints.loosen()` gives `RenderLine` children a bounded width where they were unbounded before, which changes how wide content is measured.

## Notes

- #121's CLA is not signed (`license/cla` pending). One user thanked the author on 2025-12-04, probably on Flutter below 3.32.
- Unrelated to #121: long expressions under `IntrinsicWidth` report "A RenderLine overflowed" (found while verifying #132). #121 doesn't touch intrinsic width, so this is left as a separate question.

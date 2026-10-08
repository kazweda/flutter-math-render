# #132: null check crash in MultiscriptsLayoutDelegate

Verified: 2026-10-08 / Target: simpleclub/flutter_math #132 (`036bb03`), compared with main (`75a6f61`)
Environment: Flutter 3.47.5, widget tests

## Conclusion

- The crash is real, but it doesn't come from intrinsic layout. It comes from `texBreak()`: when a break falls inside a styled group such as `\mathrm{...}` or `\mathbf{...}`, a middle part **contains the same nodes twice**.
- With #132 alone, the null check error goes away but Flutter throws **"Multiple widgets used the same GlobalKey"** instead, which is upstream #49. The duplicated content is still there.
- The root cause is a one-condition bug in `_ClipChildrenMixin.clipChildrenBetween` (`lib/src/ast/syntax_tree.dart`). Fixing it there fixes #132's crash, the duplicated output, and the GlobalKey error.
- Related upstream issues: #1 (same stack trace at `multiscripts.dart:136`), #49 (GlobalKey error with `texBreak().parts`).

## Reproduction

`Math.tex(tex).texBreak()` on main, parts encoded back to TeX:

| Input | Parts | Rendering the parts in a `Wrap` |
|---|---|---|
| `\mathrm{a = b + c}` | `\mathrm{a=}`, **`\mathrm{b+}\mathrm{b+}`**, `\mathrm{c}` | no error, but `b+` shows twice |
| `\mathbf{x_1 = y_2 + z_3}` | `\mathbf{x_1=}`, **`\mathbf{y_2+}\mathbf{y_2+}`**, `\mathbf{z_3}` | ❌ `Null check operator used on a null value` at `multiscripts.dart:136` |
| `\mathrm{CL_r = CL_{tot} \times f_e}` (from #132) | `\mathrm{CL_r=}`, **`\mathrm{CL_{tot}\times}\mathrm{CL_{tot}\times}`**, `\mathrm{f_e}` | ❌ same null check error |
| `CL_r = CL_{tot} \times f_e` (no style) | `CL_r=`, `CL_{tot}\times`, `f_e` | ✅ |

Rendering the same expressions with plain `Math.tex` (no `texBreak`), including inside `IntrinsicWidth`, `IntrinsicHeight` and a `WidgetSpan` in `Text.rich`, doesn't throw the null check error.

## Root cause

`clipChildrenBetween(pos1, pos2)` builds the clipped row from a `head` (the child containing `pos1`), the whole children in between, and a `tail` (the child containing `pos2`). When `pos1` and `pos2` fall inside the **same** child, and that child is a `TransparentNode` like `StyleNode`, both `head` and `tail` are set to the same clipped child, so it appears twice.

The existing test `preserves styles` (`\mathit{a+b}>c`) doesn't catch it because no part starts and ends inside the same styled group.

When the duplicated part contains a `MultiscriptsNode`, the same node instance (and its widget key) appears twice in one tree, so one of the two base children ends up missing from `childrenWidths`, and `childrenWidths[_ScriptPos.base]!` throws. #132 replaces that `!` with `?? 0.0`, which then lets Flutter detect the duplicate key.

## Fix

kazweda/flutter_math `fix/tex-break-duplicate` (`8023b4c`, kazweda/flutter_math#1), from upstream main:

```dart
// When both positions fall inside the same child, head already holds
// the clipped child.
if (childIndex2Ceil != childIndex2 &&
    !(head != null && childIndex2Floor == childIndex1Floor) &&
    ...
```

Plus two tests in `test/tex_break_test.dart`:

- `does not duplicate a part that lies inside one styled node`: `\mathit{a+b+c}` breaks into `\mathit{a+}`, `\mathit{b+}`, `\mathit{c}`
- `renders scripts inside a styled node`: rendering `\mathrm{x_1=y_2+z_3}` parts in a `Wrap` throws nothing

## Results

| Target | New tests | Full suite |
|---|---|---|
| main | ❌ both fail (duplicate part; null check) | 8 known failures in `selectable_test.dart` |
| main + #132 | ❌ both fail (duplicate part; "Multiple widgets used the same GlobalKey") | — |
| main + fix | ✅ both pass | same 8 known failures, no new ones |

## Notes

- #132's CLA is not signed (`license/cla` pending). Its description says the change "only affects intrinsic-size probing, not final paint", but the stack here is from `performLayout` (`IntrinsicLayoutDelegate.computeLayout`).
- #132 is still useful as defense in depth, but on its own it swaps one error for another.
- Unrelated finding: under `IntrinsicWidth`, long expressions report "A RenderLine overflowed" (intrinsic width smaller than the laid-out width). Look at this when verifying #121.

# #127: SelectableMath toolbar fixes

Verified: 2026-10-05 / Target: simpleclub/flutter_math #127 (`0553865`), compared with main (`127cf24`) and kazweda/flutter_math `fix/selectable-math-runtime` (`f5385aa`)
Environment: Flutter 3.47.5, iPhone Air simulator (iOS 26.5, top safe area 68 pt)

## Conclusion

- #127 fixes both toolbar problems this lab found on main: Copy / Select all throwing, and toolbar buttons not receiving taps on iOS devices with a top safe area.
- But it **doesn't compile on Flutter 3.44 or later**: `TextInputClient.onFocusReceived` is missing. One override fixes it.
- It doesn't fix the Android software keyboard coming up when a SelectableMath is tapped.
- Plan: comment on #127 with these results instead of opening competing PRs for the toolbar. The Android keyboard fix can go in a small separate PR.

## The problems on main

1. **Copy / Select all throw.** `InternalSelectableMathState` implements `TextSelectionDelegate` but not `copySelection`, `selectAll`, `bringIntoView`, `cutSelection`, `pasteText` or `userUpdateTextEditingValue`. They fall through to its `noSuchMethod` override, which throws `NoSuchMethodError`.
2. **Toolbar buttons don't receive taps on iOS with a top safe area** (every recent iPhone: notch or Dynamic Island).
   - `MathSelectionOverlay._buildToolbar` wraps the toolbar in `CompositedTransformFollower(offset: -editingRegion.topLeft)` and lays it out against the whole overlay, like Flutter's `SelectionOverlay`. Flutter passes a **global** editing region there; flutter_math passes `getLocalEditingRegion()`, whose top left is always `(0, 0)`. So the offset is zero and the toolbar's full-screen layout box starts at the formula instead of the top of the screen.
   - The Cupertino toolbar keeps clear of the top padding (safe area + 8 pt) inside that box, so the buttons end up above the box. They are painted (no clipping), but hit testing stops at the parent's bounds, so the tap goes to the widget underneath. That widget takes focus, and SelectableMath clears its selection when it loses focus.
   - Widget tests miss it because the test view has no safe area by default. Setting `tester.view.padding` and `WidgetController.hitTestWarningShouldBeFatal = true` reproduces it.
   - Android's Material toolbar wasn't affected in tests.
3. **Android shows the software keyboard** when a SelectableMath is tapped: `WebSelectionControlsManagerMixin` opens a text input connection on focus on every platform, not only on web.

## What #127 changes here

- Implements the `TextSelectionDelegate` methods and builds the toolbar from `contextMenuButtonItems` (fixes 1).
- Replaces `selectionControls.buildToolbar` + `CompositedTransformFollower` with `AdaptiveTextSelectionToolbar.buttonItems` and `TextSelectionToolbarAnchors.fromSelection(renderBox: manager.rootRenderBox, ...)`, which computes global anchors (fixes 2).
- Removes the `noSuchMethod` fallback from `InternalSelectableMathState`. That's why a member added to `TextInputClient` later breaks the build: `onFocusReceived` was added in Flutter 3.44.0 (flutter/flutter#182024, 2026-03-31), after #127 was opened (2026-03-08). #127 declares `flutter: '>=3.38.0'`, so 3.44+ is in range.

## Results

Lab tests (Flutter 3.47.5) with `dependency_overrides` pointing at each target:

| Target | Result |
|---|---|
| #127 as is | ❌ compile error: missing `TextInputClient.onFocusReceived` |
| #127 + `@override bool onFocusReceived() => false;` in `WebSelectionControlsManagerMixin` | ✅ all pass (goldens, toolbar Copy / Select all, Select All on a view with a top safe area, inline copy) except ❌ the Android keyboard test |
| fork `f5385aa` | ✅ all pass |

iPhone Air simulator (integration test: double-tap the block formula in the Markdown tab, tap Select All, then Copy):

| Target | Result |
|---|---|
| fork `6ec49b7` (fix 1 only) | ❌ Select All misses; the tap lands on the paragraph below and the selection is cleared |
| #127 + `onFocusReceived` | ✅ toolbar above the formula (y 306–324, formula at 332); Select All → Copy puts the whole formula on the clipboard as TeX |
| fork `f5385aa` | ✅ same as above |

## Notes

- `flutter analyze` in the app reported no issues with #127 as a dependency; the compile error only showed up in `flutter test`. (Same as in [layout-callback-mixin.md](layout-callback-mixin.md).)
- #127 is large (153 files, +1547/-553), conflicts with main, and its CLA is pending. The comment sticks to the verification results.

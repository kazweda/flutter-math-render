# #111 / #112 / #122: removing RenderObjectWithLayoutCallbackMixin

Verified: 2026-10-04 / Target: simpleclub/flutter_math main (`75a6f61`)

## Conclusion

- All three PRs revert #108 so that 0.7.4 builds on Flutter 3.29 and earlier, and
  **none of them compile on Flutter 3.32 or later**. They should not be merged.
- The root cause is `flutter: '>=3.0.0'` in `pubspec.yaml`. 0.7.4 uses Flutter 3.32 APIs, so the
  right fix is to raise the lower bound to `'>=3.32.0'` (PR #133). The published 0.7.4 can't be
  fixed, though, so users on Flutter below 3.32 need to pin `flutter_math_fork: 0.7.3`.

## History

| When | What happened |
|---|---|
| Flutter 3.32 | flutter/flutter#164034 redesigns the internals of LayoutBuilder: `rebuildIfNecessary()` becomes `runLayoutCallback()`, and the mechanism moves into `RenderObjectWithLayoutCallbackMixin` |
| 2025-05-21 | #108 (merged by edhom) adapts to it and 0.7.4 is published. The pubspec lower bound stays at `>=3.0.0` |
| 2025-05-22 | Issue #110: `Type 'RenderObjectWithLayoutCallbackMixin' not found` on Flutter 3.29. The report says it was "removed in newer Flutter", but it was actually **added in 3.32** |
| 2025-06 | #111 / #112: the workaround from a #110 comment (deleting two lines) turned into PRs as is. Both have the same diff |
| 2025-11 | #122: removes the mixin and goes back to `rebuildIfNecessary()` (almost a revert of #108) |

## Background

- `LayoutBuilderPreserveBaseline` (`lib/src/render/layout/layout_builder_baseline.dart`) is a copy
  of Flutter's `LayoutBuilder` that also passes the child's baseline up to the parent.
  It is used by `sqrt.dart` (√), `stretchy_op.dart` (`\xrightarrow` and friends) and `left_right.dart`.
  For example, √ receives the size of its content as a constraint and then builds the SVG for the sign.
- `RenderObjectWithLayoutCallbackMixin` (Flutter `rendering/object.dart`) is the base that makes sure
  "rebuilding child widgets during layout" still runs even when an ancestor skips layout.
  `RenderAbstractLayoutBuilderMixin` (= `RenderConstrainedLayoutBuilder`) is declared
  `on RenderObjectWithChildMixin, RenderObjectWithLayoutCallbackMixin`, so removing the base mixin
  breaks compilation. The "unused mixin" claim in #111's description is wrong.

## Results

Flutter 3.47.5 (this lab's 32 golden tests + render tests):

| Target | Result |
|---|---|
| upstream main | ✅ 64/64 pass |
| #122 | ❌ compile error (missing mixin / `rebuildIfNecessary` undefined) |
| #111 (= #112) | ❌ compile error (missing mixin) |
| main + `flutter: '>=3.32.0'` | ✅ 64/64 pass |

Flutter 3.29.3 (minimal project; goldens generated with #122):

| Target | Result |
|---|---|
| upstream main | ❌ reproduces the same error as #110 |
| #122 | ✅ builds and renders (equivalent to 0.7.3) |
| #111 (= #112) | ⚠️ builds, but since `runLayoutCallback()` was removed along with the mixin, the builder is never called and √ and `\xrightarrow` aren't drawn. Parts of the signs spread across the whole screen (800×600). 4 of 32 mismatch |
| 0.7.3 from pub.dev (pinned) | ✅ all 32 match #122 |
| resolved from pub.dev with `^0.7.3` | ⚠️ 0.7.4 is selected (because 0.7.4 itself declares `>=3.0.0`) |
| main + `flutter: '>=3.32.0'` (as a regular path dependency) | ✅ `pub get` stops with "requires Flutter SDK version >=3.32.0" |

## Notes

- `flutter analyze` in an app doesn't check the contents of its dependencies, so it reports
  "No issues found" even with a broken PR as a dependency. The errors only show up at `flutter test`
  or build time. Running `flutter analyze lib` in the flutter_math repository itself reports
  3 errors for #122 on Flutter 3.47.5 (`non_abstract_class_inherits_abstract_member`,
  `mixin_application_not_implemented_interface`, `undefined_method`).
- SDK constraints are not applied to packages specified in `dependency_overrides`. To check the
  effect of the lower bound, specify the package as a regular dependency.
- Raising the lower bound and publishing 0.7.5 does **not** make pub pick 0.7.3 automatically for
  Flutter 3.29 users. The published 0.7.4 declares `>=3.0.0`, so 0.7.4 is selected. pub.dev's retract
  only works within 7 days of publishing, so it can't be used for 0.7.4 (published 2025-05-21).
  PR #133 therefore tells users in the CHANGELOG to pin 0.7.3 on Flutter below 3.32 (found through
  CodeRabbit's review). 0.7.3 was confirmed to render correctly on 3.29.
- #112 and #122 haven't signed the CLA (pending), and #111 shows no CLA status.

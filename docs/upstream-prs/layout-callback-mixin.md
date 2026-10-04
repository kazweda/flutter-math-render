# #111 / #112 / #122: RenderObjectWithLayoutCallbackMixin の削除

検証日: 2026-10-04 / 対象: simpleclub/flutter_math main (`75a6f61`)

## 結論

- 3つの PR はどれも「Flutter 3.29 以前で 0.7.4 をビルドするため」に #108 を戻す変更で、
  **Flutter 3.32 以降ではコンパイルできない**。マージすべきではない。
- 根本原因は `pubspec.yaml` の `flutter: '>=3.0.0'`。0.7.4 は Flutter 3.32 の API を使うので、
  下限を `'>=3.32.0'` に上げるのが正しい修正。

## 経緯

| 時期 | 出来事 |
|---|---|
| Flutter 3.32 | flutter/flutter#164034 で LayoutBuilder の内部を再設計。`rebuildIfNecessary()` → `runLayoutCallback()`、仕組みを `RenderObjectWithLayoutCallbackMixin` に切り出し |
| 2025-05-21 | #108（edhom がマージ）で対応し 0.7.4 を公開。pubspec の下限は `>=3.0.0` のまま |
| 2025-05-22 | issue #110: Flutter 3.29 で `Type 'RenderObjectWithLayoutCallbackMixin' not found`。報告は「新しい Flutter で削除された」としているが、実際は **3.32 で追加された** |
| 2025-06 | #111 / #112: #110 のコメントにある回避策（2行削除）をそのまま PR 化。両者は同一差分 |
| 2025-11 | #122: mixin を削除し `rebuildIfNecessary()` に戻す（ほぼ #108 の revert） |

## 背景知識

- `LayoutBuilderPreserveBaseline`（`lib/src/render/layout/layout_builder_baseline.dart`）は
  Flutter の `LayoutBuilder` のコピーに、子のベースラインを親へ伝える処理を足したもの。
  `sqrt.dart`（√）、`stretchy_op.dart`（`\xrightarrow` など）、`left_right.dart` で使用。
  例えば √ は、中身のサイズを制約として受け取ってから記号の SVG を作る。
- `RenderObjectWithLayoutCallbackMixin`（Flutter `rendering/object.dart`）は「レイアウト中に
  子 Widget を作り直す処理」を、祖先がレイアウトを省略しても確実に実行するための土台。
  `RenderAbstractLayoutBuilderMixin`（= `RenderConstrainedLayoutBuilder`）は
  `on RenderObjectWithChildMixin, RenderObjectWithLayoutCallbackMixin` と宣言しているので、
  土台の mixin を外すとコンパイルできない。#111 の説明にある "unused mixin" は誤り。

## 検証結果

Flutter 3.47.5（このラボのゴールデンテスト 32 件 + 描画テスト）:

| 対象 | 結果 |
|---|---|
| upstream main | ✅ 64/64 成功 |
| #122 | ❌ コンパイルエラー（mixin が足りない／`rebuildIfNecessary` が未定義） |
| #111（= #112） | ❌ コンパイルエラー（mixin が足りない） |
| main + `flutter: '>=3.32.0'` | ✅ 64/64 成功 |

Flutter 3.29.3（最小限のプロジェクト。ゴールデンは #122 で生成）:

| 対象 | 結果 |
|---|---|
| upstream main | ❌ #110 と同じエラーを再現 |
| #122 | ✅ ビルド・描画とも OK（= 0.7.3 相当） |
| #111（= #112） | ⚠️ ビルドは通るが、`runLayoutCallback()` ごと消したため builder が呼ばれず、√ と `\xrightarrow` が描かれない。記号の部品が画面全体（800×600）に広がる。32 件中 4 件が不一致 |
| pub.dev の 0.7.3 | ✅ 32/32 が #122 と一致 |
| main + `flutter: '>=3.32.0'`（通常の path 依存として） | ✅ `pub get` が「requires Flutter SDK version >=3.32.0」で止まる |

## 補足

- アプリ側の `flutter analyze` は依存パッケージの中身を検査しないので、壊れた PR を依存に指定しても
  "No issues found" になる。エラーは `flutter test` やビルドの段階で初めて出る。
  flutter_math リポジトリ自身で `flutter analyze lib` を実行すれば、#122 でも Flutter 3.47.5 で
  error が 3 件出る（`non_abstract_class_inherits_abstract_member`、
  `mixin_application_not_implemented_interface`、`undefined_method`）。
- `dependency_overrides` で指定したパッケージには SDK 制約が適用されない。下限の効果を
  確かめるときは通常の依存で指定する。
- 下限を上げて 0.7.5 などを公開すれば、Flutter 3.29 のユーザーには pub が自動で 0.7.3 を選ぶ
  （0.7.3 は 3.29 で正常に描画できることを確認済み）。
- #112 と #122 は CLA 未署名（pending）、#111 は CLA の状態表示なし。

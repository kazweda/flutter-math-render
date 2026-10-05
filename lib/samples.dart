/// Language of the sample content. The lab ships English and Japanese
/// content, as a real app with math would.
enum SampleLanguage {
  en('EN'),
  ja('JA');

  const SampleLanguage(this.code);

  final String code;

  /// Reads `--dart-define=LANG=en|ja`, defaulting to English.
  static SampleLanguage fromEnvironment() {
    const String lang = String.fromEnvironment('LANG');
    return SampleLanguage.values.firstWhere(
      (SampleLanguage l) => l.name == lang,
      orElse: () => SampleLanguage.en,
    );
  }
}

/// Sample text mixing Markdown and math, as a vocabulary note would.
/// Both languages cover the same cases.
const Map<SampleLanguage, String> markdownSamples = <SampleLanguage, String>{
  SampleLanguage.en: r'''
## Quadratic equations

The solutions of $ax^2 + bx + c = 0$ are:

$$
x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}
$$

- Two distinct real roots if the discriminant $D = b^2 - 4ac$ satisfies $D > 0$
- A **double root** when $D = 0$

This long paragraph contains a fraction $\frac{1}{2}$, a root $\sqrt{\frac{a}{b}}$ and a sum $\sum_{k=1}^{n} k$ inline, to check the line height and any overlap with the lines above and below. One more sentence to see how it wraps.

In chemistry you can write $\mathrm{H_2O}$ and $\mathrm{SO_4^{2-}}$ too.

Currency is not math: $5 and $10, priced at $5-$10.
Escaped: \$x\$ is shown as is.

An invalid formula stays as source: $\frac{1}{$
''',
  SampleLanguage.ja: r'''
## 二次方程式

$ax^2 + bx + c = 0$ の解は次のとおり。

$$
x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}
$$

- 判別式 $D = b^2 - 4ac$ が $D > 0$ なら異なる2つの実数解
- **重解**は $D = 0$ のとき

文中の分数 $\frac{1}{2}$ や $\sqrt{\frac{a}{b}}$ 、総和 $\sum_{k=1}^{n} k$ を含む長い段落で、行の高さと前後の行との重なりを確認するための文章です。もう一行続けて折り返しを見る。

化学では $\mathrm{H_2O}$ や $\mathrm{SO_4^{2-}}$ も書ける。

通貨表記は数式にならない: $5 and $10、価格は $5-$10。
エスケープ: \$x\$ はそのまま表示される。

不正な式はソースのまま: $\frac{1}{$
''',
};

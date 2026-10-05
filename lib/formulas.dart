import 'samples.dart';

/// A formula used for rendering checks.
class Formula {
  const Formula(this.id, this.en, this.ja, this.tex);

  /// ASCII identifier, used for golden file names.
  final String id;
  final String en;
  final String ja;
  final String tex;

  String label(SampleLanguage language) => switch (language) {
    SampleLanguage.en => en,
    SampleLanguage.ja => ja,
  };
}

/// High-school level math, following the Japanese curriculum
/// (Math I, A, II, B, III and C).
const List<Formula> mathFormulas = <Formula>[
  Formula(
    'quadratic_formula',
    'Quadratic formula',
    '解の公式',
    r'x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}',
  ),
  Formula('nth_root', 'Nth root', '累乗根', r'\sqrt[3]{x^2+1}'),
  Formula(
    'rationalize',
    'Rationalizing the denominator',
    '有理化',
    r'\frac{1}{\sqrt{2}} = \frac{\sqrt{2}}{2}',
  ),
  Formula('absolute_value', 'Absolute value', '絶対値', r'|x - 1| < 3'),
  Formula(
    'combination',
    'Combinations',
    '組合せ',
    r'{}_n\mathrm{C}_r = \frac{n!}{r!(n-r)!}',
  ),
  Formula(
    'permutation',
    'Permutations',
    '順列',
    r'{}_n\mathrm{P}_r = \frac{n!}{(n-r)!}',
  ),
  Formula(
    'probability',
    'Probability',
    '確率',
    r'P(A \cup B) = P(A) + P(B) - P(A \cap B)',
  ),
  Formula(
    'trig_identity',
    'Trigonometric identity',
    '三角関数',
    r'\sin^2\theta + \cos^2\theta = 1',
  ),
  Formula(
    'addition_theorem',
    'Angle addition formula',
    '加法定理',
    r'\sin(\alpha + \beta) = \sin\alpha\cos\beta + \cos\alpha\sin\beta',
  ),
  Formula('logarithm', 'Logarithms', '対数', r'\log_a MN = \log_a M + \log_a N'),
  Formula('exponent', 'Exponents', '指数', r'a^{m} \cdot a^{n} = a^{m+n}'),
  Formula(
    'sum_of_squares',
    'Sum of a series',
    '数列の和',
    r'\sum_{k=1}^{n} k^2 = \frac{n(n+1)(2n+1)}{6}',
  ),
  Formula(
    'geometric_series',
    'Geometric series',
    '等比数列',
    r'S_n = \frac{a(1-r^n)}{1-r} \quad (r \neq 1)',
  ),
  Formula('limit', 'Limits', '極限', r'\lim_{x \to 0} \frac{\sin x}{x} = 1'),
  Formula(
    'napier',
    "Euler's number",
    'ネイピア数',
    r'e = \lim_{n \to \infty} \left(1 + \frac{1}{n}\right)^n',
  ),
  Formula(
    'derivative',
    'Derivative',
    '微分',
    r"f'(x) = \lim_{h \to 0} \frac{f(x+h) - f(x)}{h}",
  ),
  Formula(
    'definite_integral',
    'Definite integral',
    '定積分',
    r'\int_0^1 x^2\,dx = \left[\frac{x^3}{3}\right]_0^1 = \frac{1}{3}',
  ),
  Formula(
    'vector_dot',
    'Dot product',
    'ベクトル',
    r'\vec{a} \cdot \vec{b} = |\vec{a}||\vec{b}|\cos\theta',
  ),
  Formula(
    'overrightarrow',
    'Directed segments',
    '有向線分',
    r'\overrightarrow{AB} = \overrightarrow{OB} - \overrightarrow{OA}',
  ),
  Formula(
    'matrix',
    'Matrix',
    '行列',
    r'\begin{pmatrix} a & b \\ c & d \end{pmatrix}',
  ),
  Formula(
    'cases',
    'Simultaneous equations',
    '連立方程式',
    r'\begin{cases} x + y = 3 \\ x - y = 1 \end{cases}',
  ),
  Formula(
    'complex_polar',
    'Complex numbers in polar form',
    '複素数',
    r'z = r(\cos\theta + i\sin\theta)',
  ),
  Formula(
    'de_moivre',
    "De Moivre's theorem",
    'ド・モアブル',
    r'(\cos\theta + i\sin\theta)^n = \cos n\theta + i\sin n\theta',
  ),
  Formula(
    'inequalities',
    'Inequality signs',
    '不等号',
    r'a \leqq b,\ a \geqq b,\ a \neq b',
  ),
  Formula('sets', 'Sets', '集合', r'A \subset B,\ x \in A,\ \overline{A}'),
  Formula('operatorname', 'Operator names', '演算子名', r'\operatorname{arg} z'),
];

/// Chemistry written with plain LaTeX (no mhchem).
const List<Formula> chemistryFormulas = <Formula>[
  Formula('water', 'Water', '水', r'\mathrm{H_2O}'),
  Formula(
    'ions',
    'Ions',
    'イオン',
    r'\mathrm{SO_4^{2-}} + \mathrm{Ba^{2+}} \rightarrow \mathrm{BaSO_4}',
  ),
  Formula(
    'equilibrium',
    'Reversible reaction',
    '可逆反応',
    r'\mathrm{N_2 + 3H_2 \rightleftharpoons 2NH_3}',
  ),
  Formula('hydrate', 'Hydrate', '水和物', r'\mathrm{CuSO_4 \cdot 5H_2O}'),
  Formula('isotope', 'Isotope', '同位体', r'{}^{14}_{6}\mathrm{C}'),
  Formula(
    'reaction_condition',
    'Reaction conditions',
    '反応条件',
    r'\mathrm{2H_2O_2 \xrightarrow{MnO_2} 2H_2O + O_2}',
  ),
];

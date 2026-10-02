/// A formula used for rendering checks.
class Formula {
  const Formula(this.id, this.label, this.tex);

  /// ASCII identifier, used for golden file names.
  final String id;
  final String label;
  final String tex;
}

/// High-school level math (Japanese curriculum: 数学I/A/II/B/III/C).
const List<Formula> mathFormulas = <Formula>[
  Formula('quadratic_formula', '解の公式', r'x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}'),
  Formula('nth_root', '累乗根', r'\sqrt[3]{x^2+1}'),
  Formula('rationalize', '有理化', r'\frac{1}{\sqrt{2}} = \frac{\sqrt{2}}{2}'),
  Formula('absolute_value', '絶対値', r'|x - 1| < 3'),
  Formula('combination', '組合せ', r'{}_n\mathrm{C}_r = \frac{n!}{r!(n-r)!}'),
  Formula('permutation', '順列', r'{}_n\mathrm{P}_r = \frac{n!}{(n-r)!}'),
  Formula('probability', '確率', r'P(A \cup B) = P(A) + P(B) - P(A \cap B)'),
  Formula('trig_identity', '三角関数', r'\sin^2\theta + \cos^2\theta = 1'),
  Formula(
    'addition_theorem',
    '加法定理',
    r'\sin(\alpha + \beta) = \sin\alpha\cos\beta + \cos\alpha\sin\beta',
  ),
  Formula('logarithm', '対数', r'\log_a MN = \log_a M + \log_a N'),
  Formula('exponent', '指数', r'a^{m} \cdot a^{n} = a^{m+n}'),
  Formula(
    'sum_of_squares',
    '数列の和',
    r'\sum_{k=1}^{n} k^2 = \frac{n(n+1)(2n+1)}{6}',
  ),
  Formula(
    'geometric_series',
    '等比数列',
    r'S_n = \frac{a(1-r^n)}{1-r} \quad (r \neq 1)',
  ),
  Formula('limit', '極限', r'\lim_{x \to 0} \frac{\sin x}{x} = 1'),
  Formula(
    'napier',
    'ネイピア数',
    r'e = \lim_{n \to \infty} \left(1 + \frac{1}{n}\right)^n',
  ),
  Formula(
    'derivative',
    '微分',
    r"f'(x) = \lim_{h \to 0} \frac{f(x+h) - f(x)}{h}",
  ),
  Formula(
    'definite_integral',
    '定積分',
    r'\int_0^1 x^2\,dx = \left[\frac{x^3}{3}\right]_0^1 = \frac{1}{3}',
  ),
  Formula(
    'vector_dot',
    'ベクトル',
    r'\vec{a} \cdot \vec{b} = |\vec{a}||\vec{b}|\cos\theta',
  ),
  Formula(
    'overrightarrow',
    '有向線分',
    r'\overrightarrow{AB} = \overrightarrow{OB} - \overrightarrow{OA}',
  ),
  Formula('matrix', '行列', r'\begin{pmatrix} a & b \\ c & d \end{pmatrix}'),
  Formula(
    'cases',
    '連立方程式',
    r'\begin{cases} x + y = 3 \\ x - y = 1 \end{cases}',
  ),
  Formula('complex_polar', '複素数', r'z = r(\cos\theta + i\sin\theta)'),
  Formula(
    'de_moivre',
    'ド・モアブル',
    r'(\cos\theta + i\sin\theta)^n = \cos n\theta + i\sin n\theta',
  ),
  Formula('inequalities', '不等号', r'a \leqq b,\ a \geqq b,\ a \neq b'),
  Formula('sets', '集合', r'A \subset B,\ x \in A,\ \overline{A}'),
  Formula('operatorname', '演算子名', r'\operatorname{arg} z'),
];

/// Chemistry written with plain LaTeX (no mhchem).
const List<Formula> chemistryFormulas = <Formula>[
  Formula('water', '水', r'\mathrm{H_2O}'),
  Formula(
    'ions',
    'イオン',
    r'\mathrm{SO_4^{2-}} + \mathrm{Ba^{2+}} \rightarrow \mathrm{BaSO_4}',
  ),
  Formula(
    'equilibrium',
    '可逆反応',
    r'\mathrm{N_2 + 3H_2 \rightleftharpoons 2NH_3}',
  ),
  Formula('hydrate', '水和物', r'\mathrm{CuSO_4 \cdot 5H_2O}'),
  Formula('isotope', '同位体', r'{}^{14}_{6}\mathrm{C}'),
  Formula(
    'reaction_condition',
    '反応条件',
    r'\mathrm{2H_2O_2 \xrightarrow{MnO_2} 2H_2O + O_2}',
  ),
];

/// A formula used for rendering checks.
class Formula {
  const Formula(this.label, this.tex);

  final String label;
  final String tex;
}

/// High-school level math (Japanese curriculum: 数学I/A/II/B/III/C).
const List<Formula> mathFormulas = <Formula>[
  Formula('解の公式', r'x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}'),
  Formula('累乗根', r'\sqrt[3]{x^2+1}'),
  Formula('有理化', r'\frac{1}{\sqrt{2}} = \frac{\sqrt{2}}{2}'),
  Formula('絶対値', r'|x - 1| < 3'),
  Formula('組合せ', r'{}_n\mathrm{C}_r = \frac{n!}{r!(n-r)!}'),
  Formula('順列', r'{}_n\mathrm{P}_r = \frac{n!}{(n-r)!}'),
  Formula('確率', r'P(A \cup B) = P(A) + P(B) - P(A \cap B)'),
  Formula('三角関数', r'\sin^2\theta + \cos^2\theta = 1'),
  Formula(
    '加法定理',
    r'\sin(\alpha + \beta) = \sin\alpha\cos\beta + \cos\alpha\sin\beta',
  ),
  Formula('対数', r'\log_a MN = \log_a M + \log_a N'),
  Formula('指数', r'a^{m} \cdot a^{n} = a^{m+n}'),
  Formula('数列の和', r'\sum_{k=1}^{n} k^2 = \frac{n(n+1)(2n+1)}{6}'),
  Formula('等比数列', r'S_n = \frac{a(1-r^n)}{1-r} \quad (r \neq 1)'),
  Formula('極限', r'\lim_{x \to 0} \frac{\sin x}{x} = 1'),
  Formula('ネイピア数', r'e = \lim_{n \to \infty} \left(1 + \frac{1}{n}\right)^n'),
  Formula('微分', r"f'(x) = \lim_{h \to 0} \frac{f(x+h) - f(x)}{h}"),
  Formula(
    '定積分',
    r'\int_0^1 x^2\,dx = \left[\frac{x^3}{3}\right]_0^1 = \frac{1}{3}',
  ),
  Formula('ベクトル', r'\vec{a} \cdot \vec{b} = |\vec{a}||\vec{b}|\cos\theta'),
  Formula(
    '有向線分',
    r'\overrightarrow{AB} = \overrightarrow{OB} - \overrightarrow{OA}',
  ),
  Formula('行列', r'\begin{pmatrix} a & b \\ c & d \end{pmatrix}'),
  Formula('連立方程式', r'\begin{cases} x + y = 3 \\ x - y = 1 \end{cases}'),
  Formula('複素数', r'z = r(\cos\theta + i\sin\theta)'),
  Formula(
    'ド・モアブル',
    r'(\cos\theta + i\sin\theta)^n = \cos n\theta + i\sin n\theta',
  ),
  Formula('不等号', r'a \leqq b,\ a \geqq b,\ a \neq b'),
  Formula('集合', r'A \subset B,\ x \in A,\ \overline{A}'),
  Formula('演算子名', r'\operatorname{arg} z'),
];

/// Chemistry written with plain LaTeX (no mhchem).
const List<Formula> chemistryFormulas = <Formula>[
  Formula('水', r'\mathrm{H_2O}'),
  Formula(
    'イオン',
    r'\mathrm{SO_4^{2-}} + \mathrm{Ba^{2+}} \rightarrow \mathrm{BaSO_4}',
  ),
  Formula('可逆反応', r'\mathrm{N_2 + 3H_2 \rightleftharpoons 2NH_3}'),
  Formula('水和物', r'\mathrm{CuSO_4 \cdot 5H_2O}'),
  Formula('同位体', r'{}^{14}_{6}\mathrm{C}'),
  Formula('反応条件', r'\mathrm{2H_2O_2 \xrightarrow{MnO_2} 2H_2O + O_2}'),
];

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import 'formulas.dart';
import 'markdown_math.dart';

void main() {
  runApp(const MathRenderApp());
}

/// Sample text mixing Markdown and math, as a vocabulary note would.
const String markdownSample = r'''
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
''';

class MathRenderApp extends StatelessWidget {
  const MathRenderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_math_fork lab',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const GalleryScreen(),
    );
  }
}

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: const int.fromEnvironment('TAB'),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('flutter_math_fork lab'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: '数学'),
              Tab(text: '化学'),
              Tab(text: 'Markdown'),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            FormulaList(formulas: mathFormulas),
            FormulaList(formulas: chemistryFormulas),
            MarkdownSampleView(),
          ],
        ),
      ),
    );
  }
}

class FormulaList extends StatelessWidget {
  const FormulaList({super.key, required this.formulas});

  final List<Formula> formulas;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: formulas.length,
      separatorBuilder: (BuildContext context, int index) => const Divider(),
      itemBuilder: (BuildContext context, int index) {
        final Formula f = formulas[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(f.label, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                f.tex,
                textStyle: theme.textTheme.titleLarge,
                onErrorFallback: (FlutterMathException e) => Text(
                  e.message,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(f.tex, style: theme.textTheme.bodySmall),
          ],
        );
      },
    );
  }
}

class MarkdownSampleView extends StatefulWidget {
  const MarkdownSampleView({super.key});

  @override
  State<MarkdownSampleView> createState() => _MarkdownSampleViewState();
}

class _MarkdownSampleViewState extends State<MarkdownSampleView> {
  bool _selectable = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        SwitchListTile(
          title: const Text('selectable'),
          value: _selectable,
          onChanged: (bool v) => setState(() => _selectable = v),
        ),
        const Divider(),
        MarkdownMathBody(data: markdownSample, selectable: _selectable),
      ],
    );
  }
}

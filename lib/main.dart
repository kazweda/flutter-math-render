import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import 'formulas.dart';
import 'markdown_math.dart';
import 'samples.dart';

void main() {
  if (kIsWeb) {
    // Use the Flutter context menu, whose Copy writes inline formulas as TeX,
    // instead of the browser's, which copies them as U+FFFC.
    WidgetsFlutterBinding.ensureInitialized();
    BrowserContextMenu.disableContextMenu();
  }
  runApp(const MathRenderApp());
}

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

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  SampleLanguage _language = SampleLanguage.fromEnvironment();

  @override
  Widget build(BuildContext context) {
    final bool ja = _language == SampleLanguage.ja;
    return DefaultTabController(
      length: 3,
      initialIndex: const int.fromEnvironment('TAB'),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('flutter_math_fork lab'),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SegmentedButton<SampleLanguage>(
                showSelectedIcon: false,
                segments: <ButtonSegment<SampleLanguage>>[
                  for (final SampleLanguage l in SampleLanguage.values)
                    ButtonSegment<SampleLanguage>(
                      value: l,
                      label: Text(l.code),
                    ),
                ],
                selected: <SampleLanguage>{_language},
                onSelectionChanged: (Set<SampleLanguage> s) =>
                    setState(() => _language = s.single),
              ),
            ),
          ],
          bottom: TabBar(
            tabs: <Widget>[
              Tab(text: ja ? '数学' : 'Math'),
              Tab(text: ja ? '化学' : 'Chemistry'),
              const Tab(text: 'Markdown'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            FormulaList(formulas: mathFormulas, language: _language),
            FormulaList(formulas: chemistryFormulas, language: _language),
            MarkdownSampleView(data: markdownSamples[_language]!),
          ],
        ),
      ),
    );
  }
}

class FormulaList extends StatelessWidget {
  const FormulaList({
    super.key,
    required this.formulas,
    required this.language,
  });

  final List<Formula> formulas;
  final SampleLanguage language;

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
            Text(f.label(language), style: theme.textTheme.labelLarge),
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
  const MarkdownSampleView({super.key, required this.data});

  final String data;

  @override
  State<MarkdownSampleView> createState() => _MarkdownSampleViewState();
}

/// How the Markdown sample lets the user select text.
enum MarkdownSelection {
  /// Not selectable.
  off('off'),

  /// `MarkdownBody(selectable: true)`: one SelectableText per paragraph.
  selectable('selectable'),

  /// The whole body inside a SelectionArea, so a selection can span
  /// paragraphs.
  selectionArea('SelectionArea');

  const MarkdownSelection(this.label);

  final String label;
}

class _MarkdownSampleViewState extends State<MarkdownSampleView> {
  MarkdownSelection _selection = MarkdownSelection.selectable;

  @override
  Widget build(BuildContext context) {
    final Widget body = MarkdownMathBody(
      data: widget.data,
      selectable: _selection == MarkdownSelection.selectable,
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        SegmentedButton<MarkdownSelection>(
          showSelectedIcon: false,
          segments: <ButtonSegment<MarkdownSelection>>[
            for (final MarkdownSelection s in MarkdownSelection.values)
              ButtonSegment<MarkdownSelection>(value: s, label: Text(s.label)),
          ],
          selected: <MarkdownSelection>{_selection},
          onSelectionChanged: (Set<MarkdownSelection> s) =>
              setState(() => _selection = s.single),
        ),
        const Divider(),
        if (_selection == MarkdownSelection.selectionArea)
          SelectionArea(child: body)
        else
          body,
      ],
    );
  }
}

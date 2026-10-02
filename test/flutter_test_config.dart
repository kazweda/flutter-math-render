import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads every font in the asset FontManifest (KaTeX fonts from
/// flutter_math_fork included) so golden images show real glyphs
/// instead of the Ahem test font.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final String manifest = await rootBundle.loadString('FontManifest.json');
  final List<dynamic> families = jsonDecode(manifest) as List<dynamic>;
  for (final dynamic entry in families) {
    final Map<String, dynamic> family = entry as Map<String, dynamic>;
    final FontLoader loader = FontLoader(family['family'] as String);
    for (final dynamic font in family['fonts'] as List<dynamic>) {
      final String asset = (font as Map<String, dynamic>)['asset'] as String;
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
  await testMain();
}

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// I font di Roboto (Apache 2.0, in `assets/fonts/`): Helvetica, il font
/// di base del PDF, non ha gli accenti né "×".
Future<pw.ThemeData> temaPdf() async {
  Future<pw.Font> font(String nome) async =>
      pw.Font.ttf(await rootBundle.load('assets/fonts/$nome'));
  return pw.ThemeData.withFont(
    base: await font('roboto-regular.ttf'),
    bold: await font('roboto-bold.ttf'),
    italic: await font('roboto-italic.ttf'),
    boldItalic: await font('roboto-bold.ttf'),
  );
}

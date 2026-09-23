import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:seerati/features/resume/templates/pdf_fonts.dart';

/// Guards the vendored pdf patch (third_party/pdf/PATCHES.md): words in a
/// right-to-left line must sit one space apart, measured by advance width.
void main() {
  testWidgets('RTL word gap does not collapse next to digits', (tester) async {
    await tester.runAsync(() async {
      final fonts = await PdfFonts.load();
      const size = 20.0;
      final doc = pw.Document(compress: false);
      doc.addPage(pw.Page(
        theme: pw.ThemeData.withFont(base: fonts.cairo),
        textDirection: pw.TextDirection.rtl,
        build: (_) => pw.Text('يناير 2020',
            style: const pw.TextStyle(fontSize: size)),
      ));
      final content = String.fromCharCodes(await doc.save());

      // Each word is drawn with its own "x y Td" text-position operator.
      final xs = RegExp(r'([-\d.]+) [-\d.]+ Td')
          .allMatches(content)
          .map((m) => double.parse(m.group(1)!))
          .toList()
        ..sort();
      expect(xs, hasLength(2));

      final font = fonts.cairo.getFont(pw.Context(document: doc.document));
      final digits = font.stringMetrics('2020').advanceWidth * size;
      final space = font.stringMetrics(' ').advanceWidth * size;
      // Word origins are one number-advance plus one space apart.
      expect(xs[1] - xs[0], closeTo(digits + space, .01));
    });
  });
}

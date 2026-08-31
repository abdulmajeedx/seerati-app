import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfFonts {
  PdfFonts._({
    required this.cairo,
    required this.cairoBold,
    required this.roboto,
    required this.robotoBold,
  });

  final pw.Font cairo;
  final pw.Font cairoBold;
  final pw.Font roboto;
  final pw.Font robotoBold;

  static PdfFonts? _cached;

  static Future<PdfFonts> load() async {
    if (_cached != null) return _cached!;
    // Sequential on purpose: Future.wait resolves to an empty list inside
    // flutter_test's runAsync zone.
    final cairo = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final cairoBold = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
    final roboto = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final robotoBold = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    _cached = PdfFonts._(
      cairo: pw.Font.ttf(cairo),
      cairoBold: pw.Font.ttf(cairoBold),
      roboto: pw.Font.ttf(roboto),
      robotoBold: pw.Font.ttf(robotoBold),
    );
    return _cached!;
  }
}

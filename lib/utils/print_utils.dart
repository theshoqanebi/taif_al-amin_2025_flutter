import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class PrintUtils {
  static Future<void> printPdf(String path) async {
    final bytes = await File(path).readAsBytes();
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
  }
}

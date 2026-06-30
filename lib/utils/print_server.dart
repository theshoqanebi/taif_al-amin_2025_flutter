import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:taif_alamin/utils/path_utils.dart';

/// Manages the local docx → pdf conversion server (assets/server/server.py
/// — a small Flask app wrapping `docx2pdf`).
///
/// Python and its packages (flask, docx2pdf) must already be installed on
/// the machine running this app — this class only launches the script and
/// talks to it over HTTP, it never installs or checks for packages itself.
class PrintServer {
  static const String baseUrl = 'http://127.0.0.1:5000';
  static Process? _process;

  /// Where start() logs what happened — there's no visible console on a
  /// packaged Windows GUI app, so failures need somewhere to actually land.
  static Future<String> get logPath async =>
      p.join((await getTemporaryDirectory()).path, 'print_server_log.txt');

  static Future<void> _log(String message) async {
    try {
      final file = File(await logPath);
      await file.writeAsString(
        '${DateTime.now()}: $message\n',
        mode: FileMode.append,
      );
    } catch (_) {
      // Logging itself failing isn't worth crashing over.
    }
  }

  /// Launches the local server once, in the background, for the lifetime
  /// of the app. Call at app startup; safe to call again later (a no-op
  /// once it's already running).
  static Future<void> start() async {
    if (_process != null) return;

    final scriptPath = p.join(
      PathUtils.getAssetsPath(),
      'assets',
      'server',
      'server.py',
    );

    if (!await File(scriptPath).exists()) {
      await _log('server.py not found at $scriptPath');
      return;
    }

    // Use the windowless interpreters first so no console window pops up:
    // "pythonw" (python.org / Store installs) and "pyw" (the launcher's
    // windowless variant). Fall back to plain "python"/"py" only if those
    // aren't present, since those will flash a console.
    for (final cmd in ['pythonw', 'pyw', 'python', 'py']) {
      try {
        _process = await Process.start(
          cmd,
          [scriptPath],
          mode: ProcessStartMode.detached,
        );
        await _log('started with "$cmd" $scriptPath');
        return;
      } catch (e) {
        await _log('"$cmd" failed: $e');
      }
    }

    await _log(
      'could not start server.py with pythonw/pyw/python/py — is Python '
      'installed and on PATH?',
    );
  }

  /// Stops the running server (if any) and clears the handle so [start]
  /// can launch a fresh one later. Safe to call when nothing is running.
  ///
  /// Note: launched in [ProcessStartMode.detached], so Dart only holds a
  /// reference to the interpreter process — `kill()` terminates it via
  /// TerminateProcess on Windows. Any Word/COM subprocess docx2pdf spawned
  /// mid-conversion may briefly outlive it.
  static Future<bool> stop() async {
    final process = _process;
    if (process == null) return false;
    _process = null;

    final killed = process.kill();
    await _log(
      killed
          ? 'stopped server (pid ${process.pid})'
          : 'kill signal not delivered to server (pid ${process.pid})',
    );
    return killed;
  }

  /// Uploads [docxPath] to the local server, waits for it to convert to
  /// PDF, and returns the resulting PDF bytes.
  static Future<Uint8List> convertToPdf(String docxPath) async {
    final uploadUri = Uri.parse('$baseUrl/upload');
    http.StreamedResponse streamed;
    try {
      final request = http.MultipartRequest('POST', uploadUri)
        ..files.add(await http.MultipartFile.fromPath('file', docxPath));
      streamed = await request.send();
    } on SocketException {
      throw Exception(
        'تعذّر الاتصال بخادم التحويل (127.0.0.1:5000) — تأكد إن Python '
        'مثبت وبه flask و docx2pdf. التفاصيل بملف: ${await logPath}',
      );
    }
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception(
        'فشل تحويل الملف (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final downloadUrl = data['download_url'] as String?;
    if (downloadUrl == null) {
      throw Exception('استجابة غير متوقعة من خادم التحويل: ${response.body}');
    }

    final pdfResponse = await http.get(Uri.parse('$baseUrl$downloadUrl'));
    if (pdfResponse.statusCode != 200) {
      throw Exception('فشل تحميل ملف PDF (${pdfResponse.statusCode})');
    }
    return pdfResponse.bodyBytes;
  }
}
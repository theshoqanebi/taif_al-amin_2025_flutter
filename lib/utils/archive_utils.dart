import 'dart:io';
import 'package:archive/archive.dart';

class ArchiveUtils {
  static Future<void> unzipFile(String zipFilePath, String outputDir) async {
    var bytes = File(zipFilePath).readAsBytesSync();
    var archive = ZipDecoder().decodeBytes(bytes);
    for (var file in archive) {
      var filename = '$outputDir/${file.name}';
      if (file.isFile) {
        File(filename)
          ..createSync(recursive: true)
          ..writeAsBytesSync(file.content);
      }
    }
  }
}

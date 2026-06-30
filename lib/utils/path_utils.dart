import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PathUtils {
  static String getAssetsPath() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;

    final assetsPath = path.join(exeDir, 'data', 'flutter_assets');

    return assetsPath;
  }

  static Future<String> getAppDataPath() async {
    Directory appDataRoamingDir = Directory(Platform.environment['APPDATA']!);
    return appDataRoamingDir.path;
  }

  static Future<String> getDocumentsPath() async {
    Directory documentsDir = await getApplicationDocumentsDirectory();
    return documentsDir.path;
  }
}

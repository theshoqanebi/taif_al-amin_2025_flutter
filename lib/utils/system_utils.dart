import 'dart:io';

class SystemUtils {
  static Future<String> getResolution() async {
    try {
      final result = await Process.run('powershell', [
        '-command',
        r"Add-Type -AssemblyName System.Windows.Forms; "
            r"$s = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds; "
            r"Write-Output ($s.Width.ToString() + 'x' + $s.Height.ToString())",
      ]);
      return result.stdout.toString().trim();
    } catch (_) {
      return 'Unavailable';
    }
  }
}

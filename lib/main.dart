import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taif_alamin/app.dart';
import 'package:taif_alamin/utils/print_server.dart';
import 'package:window_manager/window_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Fire-and-forget: launches assets/server/server.py in the background for
  // docx -> pdf conversion when printing. Doesn't block startup.
  unawaited(PrintServer.start());

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    size: Size(1366, 768),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  WindowManager.instance.setMinimumSize(const Size(1366, 800));
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  runApp(MyApp(flavor: 'dev'));
}

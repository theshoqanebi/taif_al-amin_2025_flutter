import 'dart:ui';

import 'package:taif_alamin/widgets/app_button/app_button_theme.dart';

AppButtonColor hoverColor = const AppButtonColor(
  textColor: Color(0xFF66758C),
  backgroundColor: Color(0xFFD2E4FF),
  iconBackgroundColor: Color(0xFFFFDDBA),
  iconColor: Color(0xFF2B1700),
);

AppButtonColor defaultColor = const AppButtonColor(
  textColor: Color(0xFF66758C),
  backgroundColor: Color(0xFFFFFFFF),
  iconBackgroundColor: Color(0xFFF2F4F5),
  iconColor: Color(0xFF000000),
);

// Ready theme used by menu buttons.
AppButtonTheme defaultButtonTheme = AppButtonTheme(
  defaultColor: defaultColor,
  hoverColor: hoverColor,
);

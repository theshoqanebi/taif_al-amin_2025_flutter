import 'dart:ui';

class AppButtonTheme {
  final AppButtonColor defaultColor;
  final AppButtonColor hoverColor;

  AppButtonTheme({required this.defaultColor, required this.hoverColor});
}

class AppButtonColor {
  final Color textColor;
  final Color backgroundColor;
  final Color iconBackgroundColor;
  final Color iconColor;

  const AppButtonColor({
    required this.textColor,
    required this.backgroundColor,
    required this.iconBackgroundColor,
    required this.iconColor,
  });
}

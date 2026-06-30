import 'package:flutter/material.dart';
import 'package:taif_alamin/theme/app_colors.dart';
import 'package:taif_alamin/router.dart';

class MyApp extends StatelessWidget {
  final String flavor;
  const MyApp({required this.flavor, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: Color(0xFFF7F9FB),
      ),
    );
  }
}

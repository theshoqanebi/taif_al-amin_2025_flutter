import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taif_alamin/app_window.dart';
import 'package:taif_alamin/presentation/screens/analytics_screen.dart';
import 'package:taif_alamin/presentation/screens/home_screen.dart';
import 'package:taif_alamin/presentation/screens/settings_screen.dart';
import 'package:taif_alamin/widgets/home/home_app_bar.dart';
import 'package:taif_alamin/widgets/home/nav_item.dart';
import 'package:taif_alamin/presentation/cubits/main_cubit/main_cubit.dart';
import 'package:taif_alamin/presentation/cubits/main_cubit/main_state.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  static List<NavItem> navItems = [
    NavItem(title: 'الرئيسية', widget: HomeScreen()),
    NavItem(title: 'الإحصائات', widget: AnalyticsScreen()),
    NavItem(title: 'الإعدادات', widget: SettingsScreen()),
    NavItem(title: 'حول', widget: Container()),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainCubit, MainState>(
      builder: (context, state) {
        return AppWindow(
          showBack: false,
          body: Column(
            children: [
              HomeAppBar(
                navItems: navItems,
                selected: state.selected,
                onClick: (index) {
                  context.read<MainCubit>().select(index);
                },
              ),
              Expanded(child: navItems[state.selected].widget),
            ],
          ),
        );
      },
    );
  }
}

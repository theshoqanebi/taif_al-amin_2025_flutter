import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taif_alamin/app_window.dart';
import 'package:taif_alamin/data/constants/supply_companies.dart';
import 'package:taif_alamin/data/constants/supply_type.dart';
import 'package:taif_alamin/presentation/cubits/supplies_cubit/supplies_cubit.dart';
import 'package:taif_alamin/presentation/screens/supply_data_screen.dart';
import 'package:taif_alamin/widgets/app_button/app_button.dart';
import 'package:taif_alamin/widgets/app_button/button_themes.dart';

class SupplyCompaniesScreen extends StatelessWidget {
  final SupplyType type;
  const SupplyCompaniesScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final companies = companiesFor(type);

    return AppWindow(
      showBack: true,
      body: Center(
        child: _grid(context, [
          for (final entry in companies.entries)
            AppButton(
              title: entry.key,
              theme: defaultButtonTheme,
              materialIcon: _iconFor(type),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => SuppliesCubit(),
                    child: SupplyDataScreen(
                      type: type,
                      belongTo: entry.value,
                      title: entry.key,
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

IconData _iconFor(SupplyType type) {
  switch (type) {
    case SupplyType.fabric:
      return Icons.chair;
    case SupplyType.wood:
      return Icons.forest;
    case SupplyType.sponge:
      return Icons.layers;
    case SupplyType.paint:
      return Icons.format_paint;
  }
}

Widget _grid(BuildContext context, List<Widget> children) {
  return GridView(
    shrinkWrap: true,
    padding: const EdgeInsets.all(16),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: MediaQuery.sizeOf(context).width > 1366 ? 6 : 5,
      mainAxisSpacing: 32,
      crossAxisSpacing: 32,
      childAspectRatio: 0.75,
    ),
    children: children,
  );
}

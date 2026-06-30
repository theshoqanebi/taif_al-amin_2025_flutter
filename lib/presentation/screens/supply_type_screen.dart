import 'package:flutter/material.dart';
import 'package:taif_alamin/app_window.dart';
import 'package:taif_alamin/data/constants/supply_type.dart';
import 'package:taif_alamin/presentation/screens/supply_companies_screen.dart';
import 'package:taif_alamin/widgets/app_button/app_button.dart';
import 'package:taif_alamin/widgets/app_button/button_themes.dart';

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

// ===========================================================================
// Screen 1 — choose the supply type
// ===========================================================================
class SupplyTypeScreen extends StatelessWidget {
  const SupplyTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppWindow(
      showBack: true,
      body: Center(
        child: _grid(context, [
          for (final type in SupplyType.values)
            AppButton(
              title: type.toDisplayString(),
              theme: defaultButtonTheme,
              materialIcon: _iconFor(type),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SupplyCompaniesScreen(type: type),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

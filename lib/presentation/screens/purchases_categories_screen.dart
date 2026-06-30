import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taif_alamin/app_window.dart';
import 'package:taif_alamin/data/constants/purchase_category.dart';
import 'package:taif_alamin/presentation/cubits/items_cubit/item_cubit.dart';
import 'package:taif_alamin/presentation/screens/item_data_screen.dart';
import 'package:taif_alamin/widgets/app_button/app_button.dart';
import 'package:taif_alamin/widgets/app_button/button_themes.dart';

const _kAccent = Color(0xFF003763);

IconData _iconFor(String belongTo) {
  switch (belongTo) {
    case 'Electrical':
      return Icons.electrical_services;
    case 'CurrentExpenses':
      return Icons.receipt_long;
    case 'Electronic':
      return Icons.memory;
    case 'RawMaterials':
      return Icons.category;
    case 'Stock':
      return Icons.warehouse;
    case 'Construction':
      return Icons.handyman;
    case 'Furniture':
      return Icons.chair_alt;
    case 'Machinery':
      return Icons.precision_manufacturing;
    default:
      return Icons.inventory_2;
  }
}

class PurchasesCategoriesScreen extends StatelessWidget {
  const PurchasesCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppWindow(
      showBack: true,
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Text(
                  'المشتريات',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _kAccent,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.sizeOf(context).width > 1366 ? 6 : 5,
                mainAxisSpacing: 32,
                crossAxisSpacing: 32,
                childAspectRatio: 0.75,
              ),
              children: [
                for (final entry in purchasesCategories.entries)
                  AppButton(
                    title: entry.key,
                    theme: defaultButtonTheme,
                    materialIcon: _iconFor(entry.value),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider(
                          create: (_) => ItemsCubit(),
                          child: ItemsDataScreen(
                            belongTo: entry.value,
                            title: entry.key,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
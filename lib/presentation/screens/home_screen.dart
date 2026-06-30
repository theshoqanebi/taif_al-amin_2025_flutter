import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taif_alamin/presentation/cubits/backup_cubit/backup_cubit.dart';
import 'package:taif_alamin/presentation/cubits/debts_cubit/debts_cubit.dart';
import 'package:taif_alamin/presentation/cubits/exhibitions_info_cubit/exhibitions_info_cubit.dart';
import 'package:taif_alamin/presentation/cubits/on_us_debts_cubit/on_us_debts_cubit.dart';
import 'package:taif_alamin/presentation/cubits/sells_cubit/sells_cubit.dart';
import 'package:taif_alamin/presentation/cubits/sells_models_cubit.dart';
import 'package:taif_alamin/presentation/cubits/supplies_cubit/supplies_cubit.dart';
import 'package:taif_alamin/presentation/cubits/transport_cubit/transport_cubit.dart';
import 'package:taif_alamin/presentation/screens/backup_restore_screen.dart';
import 'package:taif_alamin/presentation/screens/debts_screen.dart';
import 'package:taif_alamin/presentation/screens/exhibitions_list_screen.dart';
import 'package:taif_alamin/presentation/screens/on_us_debts_screen.dart';
import 'package:taif_alamin/presentation/screens/purchases_categories_screen.dart';
import 'package:taif_alamin/presentation/screens/sells_screen.dart';
import 'package:taif_alamin/presentation/screens/supply_type_screen.dart';
import 'package:taif_alamin/presentation/screens/transport_screen.dart';
import 'package:taif_alamin/widgets/app_button/app_button.dart';

import 'package:taif_alamin/widgets/app_button/button_themes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _NavTile(
        'المبيعات',
        Icons.money,
        () => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => SellsCubit()),
            BlocProvider(create: (_) => SellsModelsCubit()),
          ],
          child: const SellsScreen(),
        ),
      ),

      _NavTile(
        'المواد الأولية',
        Icons.store,
        () => MultiBlocProvider(
          providers: [BlocProvider(create: (_) => SuppliesCubit())],
          child: const SupplyTypeScreen(),
        ),
      ),
      _NavTile(
        'تكاليف النقل',
        Icons.local_shipping,
        () => BlocProvider(
          create: (_) => TransportCubit(),
          child: TransportScreen(),
        ),
      ),
      _NavTile(
        'المشتريات والصرفيات',
        Icons.shopping_cart,
        () => BlocProvider(
          create: (_) => TransportCubit(),
          child: PurchasesCategoriesScreen(),
        ),
      ),

      _NavTile(
        'المعارض',
        Icons.view_carousel,
        () => BlocProvider(
          create: (_) => ExhibitionsInfoCubit(),
          child: ExhibitionsListScreen(),
        ),
      ),

      _NavTile(
        'الديون',
        Icons.account_balance_wallet,
        () => BlocProvider(
          create: (_) => DebtsCubit(),
          child: DebtsScreen(),
        ),
      ),

      _NavTile(
        'ديون علينا',
        Icons.request_quote,
        () => BlocProvider(
          create: (_) => OnUsDebtsCubit(),
          child: const OnUsDebtsScreen(),
        ),
      ),
      _NavTile(
        'النسخ الاحتياطي والاستعادة',
        Icons.settings_backup_restore,
        () => BlocProvider(
          create: (_) => BackupCubit(),
          child: const BackupRestoreScreen(),
        ),
      ),
    ];

    return Scaffold(
      body: GridView(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.sizeOf(context).width > 1366 ? 6 : 5,
          mainAxisSpacing: 32,
          crossAxisSpacing: 32,
          childAspectRatio: 0.75,
        ),
        // (context)=> t.builder()
        children: [
          for (final t in tiles)
            AppButton(
              title: t.title,
              theme: defaultButtonTheme,
              materialIcon: t.icon,
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => t.builder()));
              },
            ),
        ],
      ),
    );
  }
}

class _NavTile {
  final String title;
  final IconData icon;
  final Widget Function() builder;
  _NavTile(this.title, this.icon, this.builder);
}

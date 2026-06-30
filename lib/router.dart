import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taif_alamin/presentation/cubits/main_cubit/main_cubit.dart';
import 'package:taif_alamin/presentation/cubits/transport_cubit/transport_cubit.dart';
import 'package:taif_alamin/presentation/screens/analytics_screen.dart';
import 'package:taif_alamin/presentation/cubits/sells_cubit/sells_cubit.dart';
import 'package:taif_alamin/presentation/cubits/sells_models_cubit.dart';
import 'package:taif_alamin/presentation/screens/sells_screen.dart';
import 'package:taif_alamin/presentation/screens/main_screen.dart';
import 'package:taif_alamin/presentation/screens/supply_type_screen.dart';
import 'package:taif_alamin/presentation/screens/transport_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) =>
          BlocProvider(create: (context) => MainCubit(), child: MainScreen()),
      routes: [
        GoRoute(
          path: 'settings',
          builder: (context, state) => BlocProvider(
            create: (_) => TransportCubit(),
            child: TransportScreen(),
          ),
        ),
        GoRoute(
          path: 'analytics',
          builder: (context, state) => AnalyticsScreen(),
        ),
        GoRoute(
          path: 'sells',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => SellsCubit()),
              BlocProvider(create: (_) => SellsModelsCubit()),
            ],
            child: const SellsScreen(),
          ),
        ),
        GoRoute(
          path: 'supplies',
          builder: (context, state) => const SupplyTypeScreen(),
        ),
      ],
    ),
  ],
);

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taif_alamin/app_window.dart';
import 'package:taif_alamin/presentation/cubits/exhibitions_cubit/exhibitions_cubit.dart';
import 'package:taif_alamin/presentation/cubits/exhibitions_info_cubit/exhibitions_info_cubit.dart';
import 'package:taif_alamin/presentation/cubits/exhibitions_info_cubit/exhibitions_info_state.dart';
import 'package:taif_alamin/presentation/cubits/exhibitions_models_cubit/exhibitions_models_cubit.dart';
import 'package:taif_alamin/presentation/screens/exhibition_data_screen.dart';
import 'package:taif_alamin/widgets/app_button/app_button.dart';
import 'package:taif_alamin/widgets/app_button/button_themes.dart';

class ExhibitionsListScreen extends StatefulWidget {
  const ExhibitionsListScreen({super.key});

  @override
  State<ExhibitionsListScreen> createState() => _ExhibitionsListScreenState();
}

class _ExhibitionsListScreenState extends State<ExhibitionsListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ExhibitionsInfoCubit>().loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return AppWindow(
      showBack: true,
      body: BlocBuilder<ExhibitionsInfoCubit, ExhibitionsInfoState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.hasError) {
            return Center(child: Text(state.error ?? 'حدث خطأ'));
          }
          if (state.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد معارض',
                style: TextStyle(fontFamily: 'Amiri', fontSize: 18),
              ),
            );
          }

          return Center(
            child: _grid(context, [
              for (final ex in state.exhibitions)
                AppButton(
                  title: ex.label,
                  theme: defaultButtonTheme,
                  materialIcon: Icons.storefront,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MultiBlocProvider(
                        providers: [
                          BlocProvider(create: (_) => ExhibitionsCubit()),
                          BlocProvider(create: (_) => ExhibitionsModelsCubit()),
                        ],
                        child: ExhibitionDataScreen(
                          belongTo: ex.belongTo ?? '',
                          title: ex.label,
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          );
        },
      ),
    );
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

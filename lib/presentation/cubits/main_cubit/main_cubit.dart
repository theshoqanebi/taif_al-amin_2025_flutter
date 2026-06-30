import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taif_alamin/presentation/cubits/main_cubit/main_state.dart';

class MainCubit extends Cubit<MainState> {
  MainCubit() : super(MainState(selected: 0));

  void select(int selected) {
    emit(MainState(selected: selected));
  }
}

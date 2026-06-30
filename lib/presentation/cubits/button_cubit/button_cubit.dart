import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taif_alamin/presentation/cubits/button_cubit/button_state.dart';
import 'package:taif_alamin/widgets/app_button/app_button_theme.dart';

class ButtonCubit extends Cubit<ButtonState> {
  ButtonCubit(super.initialState);

  void changeState(AppButtonColor color) {
    emit(ButtonState(color: color));
  }
}

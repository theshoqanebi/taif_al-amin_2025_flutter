import 'package:equatable/equatable.dart';
import 'package:taif_alamin/widgets/app_button/app_button_theme.dart';

class ButtonState extends Equatable {
  final AppButtonColor color;
  const ButtonState({required this.color});

  @override
  List<Object?> get props => [color];
}

class ButtonHover extends ButtonState {
  const ButtonHover({required super.color});
}

import 'package:equatable/equatable.dart';

class MainState extends Equatable {
  final int selected;
  const MainState({required this.selected});

  @override
  List<Object?> get props => [selected];
}

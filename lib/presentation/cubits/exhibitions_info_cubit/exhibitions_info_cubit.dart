import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taif_alamin/data/repositories/exhibitions_info_repository.dart';
import 'package:taif_alamin/presentation/cubits/exhibitions_info_cubit/exhibitions_info_state.dart';

class ExhibitionsInfoCubit extends Cubit<ExhibitionsInfoState> {
  final ExhibitionsInfoRepository _repository = ExhibitionsInfoRepository();

  ExhibitionsInfoCubit() : super(const ExhibitionsInfoState());

  Future<void> loadAll() async {
    try {
      emit(state.copyWith(status: ExhibitionsInfoStatus.loading));
      final exhibitions = await _repository.getAll();
      emit(
        state.copyWith(
          status: ExhibitionsInfoStatus.success,
          exhibitions: exhibitions,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ExhibitionsInfoStatus.error,
          error: e.toString(),
        ),
      );
    }
  }
}

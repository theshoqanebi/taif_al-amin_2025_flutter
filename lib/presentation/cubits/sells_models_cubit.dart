import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taif_alamin/data/models/models_model.dart';
import 'package:taif_alamin/data/repositories/sells_models_repository.dart';

enum SellsModelsStatus { initial, loading, success, saving, error }

class SellsModelsState {
  final SellsModelsStatus status;
  final List<SellsModel> models;
  final String? error;

  const SellsModelsState({
    this.status = SellsModelsStatus.initial,
    this.models = const [],
    this.error,
  });

  SellsModelsState copyWith({
    SellsModelsStatus? status,
    List<SellsModel>? models,
    String? error,
  }) => SellsModelsState(
    status: status ?? this.status,
    models: models ?? this.models,
    error: error,
  );

  bool get isLoading => status == SellsModelsStatus.loading;
  bool get isSuccess => status == SellsModelsStatus.success;
  bool get hasError => status == SellsModelsStatus.error;
}

class SellsModelsCubit extends Cubit<SellsModelsState> {
  final SellsModelsRepository _repository = SellsModelsRepository();

  SellsModelsCubit() : super(const SellsModelsState());

  Future<void> loadModels() async {
    try {
      emit(state.copyWith(status: SellsModelsStatus.loading));
      final models = await _repository.getAllActive();
      emit(state.copyWith(status: SellsModelsStatus.success, models: models));
    } catch (e) {
      emit(
        state.copyWith(status: SellsModelsStatus.error, error: e.toString()),
      );
    }
  }

  Future<void> add(SellsModel model) async {
    try {
      emit(state.copyWith(status: SellsModelsStatus.saving));
      await _repository.insert(model);
      await loadModels();
    } catch (e) {
      emit(
        state.copyWith(status: SellsModelsStatus.error, error: e.toString()),
      );
    }
  }

  /// Edit by appending a new revision sharing the same UUID.
  Future<void> edit(SellsModel revised) async {
    try {
      emit(state.copyWith(status: SellsModelsStatus.saving));
      await _repository.insertRevision(revised);
      await loadModels();
    } catch (e) {
      emit(
        state.copyWith(status: SellsModelsStatus.error, error: e.toString()),
      );
    }
  }

  Future<void> remove(String uuid) async {
    try {
      emit(state.copyWith(status: SellsModelsStatus.saving));
      await _repository.deleteByUuid(uuid);
      await loadModels();
    } catch (e) {
      emit(
        state.copyWith(status: SellsModelsStatus.error, error: e.toString()),
      );
    }
  }
}

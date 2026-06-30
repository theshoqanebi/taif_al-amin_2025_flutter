import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taif_alamin/data/models/exhibitions_model_model.dart';
import 'package:taif_alamin/data/repositories/exhibitions_models_repository.dart';
import 'package:taif_alamin/presentation/cubits/exhibitions_models_cubit/exhibitions_models_state.dart';

class ExhibitionsModelsCubit extends Cubit<ExhibitionsModelsState> {
  final ExhibitionsModelsRepository _repository = ExhibitionsModelsRepository();

  ExhibitionsModelsCubit() : super(const ExhibitionsModelsState());

  /// Load active models (optionally scoped to a showroom).
  Future<void> loadModels({String? belongTo}) async {
    try {
      emit(
        state.copyWith(
          status: ExhibitionsModelsStatus.loading,
          belongTo: belongTo ?? state.belongTo,
        ),
      );
      final scope = belongTo ?? state.belongTo;
      final models = scope == null
          ? await _repository.getAllActive()
          : await _repository.getActiveByBelongTo(scope);
      emit(
        state.copyWith(status: ExhibitionsModelsStatus.success, models: models),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ExhibitionsModelsStatus.error,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> add(ExhibitionsModel model) async {
    try {
      emit(state.copyWith(status: ExhibitionsModelsStatus.saving));
      await _repository.insert(model);
      await loadModels();
    } catch (e) {
      emit(
        state.copyWith(
          status: ExhibitionsModelsStatus.error,
          error: e.toString(),
        ),
      );
    }
  }

  /// Edit by appending a new revision sharing the same uuid.
  Future<void> edit(ExhibitionsModel revised) async {
    try {
      emit(state.copyWith(status: ExhibitionsModelsStatus.saving));
      await _repository.insertRevision(revised);
      await loadModels();
    } catch (e) {
      emit(
        state.copyWith(
          status: ExhibitionsModelsStatus.error,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> remove(String uuid) async {
    try {
      emit(state.copyWith(status: ExhibitionsModelsStatus.saving));
      await _repository.deleteByUuid(uuid);
      await loadModels();
    } catch (e) {
      emit(
        state.copyWith(
          status: ExhibitionsModelsStatus.error,
          error: e.toString(),
        ),
      );
    }
  }
}

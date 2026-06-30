import 'package:taif_alamin/data/models/exhibitions_model_model.dart';

enum ExhibitionsModelsStatus { initial, loading, success, saving, error }

class ExhibitionsModelsState {
  final ExhibitionsModelsStatus status;
  final List<ExhibitionsModel> models;

  /// Showroom scope used for refreshing after writes.
  final String? belongTo;
  final String? error;

  const ExhibitionsModelsState({
    this.status = ExhibitionsModelsStatus.initial,
    this.models = const [],
    this.belongTo,
    this.error,
  });

  ExhibitionsModelsState copyWith({
    ExhibitionsModelsStatus? status,
    List<ExhibitionsModel>? models,
    String? belongTo,
    String? error,
  }) => ExhibitionsModelsState(
    status: status ?? this.status,
    models: models ?? this.models,
    belongTo: belongTo ?? this.belongTo,
    error: error,
  );

  bool get isLoading => status == ExhibitionsModelsStatus.loading;
  bool get isSaving => status == ExhibitionsModelsStatus.saving;
  bool get isSuccess => status == ExhibitionsModelsStatus.success;
  bool get hasError => status == ExhibitionsModelsStatus.error;
}

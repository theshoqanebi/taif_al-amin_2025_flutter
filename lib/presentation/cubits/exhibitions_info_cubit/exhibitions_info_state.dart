import 'package:taif_alamin/data/models/exhibition_info_model.dart';

enum ExhibitionsInfoStatus { initial, loading, success, error }

class ExhibitionsInfoState {
  final ExhibitionsInfoStatus status;
  final List<ExhibitionInfo> exhibitions;
  final String? error;

  const ExhibitionsInfoState({
    this.status = ExhibitionsInfoStatus.initial,
    this.exhibitions = const [],
    this.error,
  });

  ExhibitionsInfoState copyWith({
    ExhibitionsInfoStatus? status,
    List<ExhibitionInfo>? exhibitions,
    String? error,
  }) => ExhibitionsInfoState(
    status: status ?? this.status,
    exhibitions: exhibitions ?? this.exhibitions,
    error: error,
  );

  bool get isLoading => status == ExhibitionsInfoStatus.loading;
  bool get isSuccess => status == ExhibitionsInfoStatus.success;
  bool get hasError => status == ExhibitionsInfoStatus.error;
  bool get isEmpty => exhibitions.isEmpty;
}

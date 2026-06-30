
import 'package:taif_alamin/data/models/additional_amount_model.dart';

enum AdditionalAmountsStatus { initial, loading, success, error }

class AdditionalAmountsState {
  final AdditionalAmountsStatus status;
  final List<AdditionalAmount> items;
  final int total;
  final String? error;

  const AdditionalAmountsState({
    this.status = AdditionalAmountsStatus.initial,
    this.items = const [],
    this.total = 0,
    this.error,
  });

  AdditionalAmountsState copyWith({
    AdditionalAmountsStatus? status,
    List<AdditionalAmount>? items,
    int? total,
    String? error,
  }) =>
      AdditionalAmountsState(
        status: status ?? this.status,
        items: items ?? this.items,
        total: total ?? this.total,
        error: error ?? this.error,
      );
}

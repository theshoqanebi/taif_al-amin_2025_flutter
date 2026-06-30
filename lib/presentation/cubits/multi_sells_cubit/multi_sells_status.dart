import 'package:taif_alamin/data/models/multi_sells_model.dart';

enum MultiSellsStatus { initial, loading, success, error }

class MultiSellsState {
  final MultiSellsStatus status;
  final List<MultiSell> items;
  final String? error;

  const MultiSellsState({
    this.status = MultiSellsStatus.initial,
    this.items = const [],
    this.error,
  });

  MultiSellsState copyWith({
    MultiSellsStatus? status,
    List<MultiSell>? items,
    String? error,
  }) => MultiSellsState(
    status: status ?? this.status,
    items: items ?? this.items,
    error: error ?? this.error,
  );
}

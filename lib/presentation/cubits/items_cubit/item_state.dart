import 'package:taif_alamin/data/models/item_model.dart';

enum ItemsStatus { initial, loading, success, saving, error }

class ItemsState {
  final ItemsStatus status;
  final List<Item> items;

  /// The category currently being viewed (used to auto-refresh after writes).
  final String? belongTo;
  final String? error;

  const ItemsState({
    this.status = ItemsStatus.initial,
    this.items = const [],
    this.belongTo,
    this.error,
  });

  ItemsState copyWith({
    ItemsStatus? status,
    List<Item>? items,
    String? belongTo,
    String? error,
  }) => ItemsState(
    status: status ?? this.status,
    items: items ?? this.items,
    belongTo: belongTo ?? this.belongTo,
    error: error,
  );

  bool get isLoading => status == ItemsStatus.loading;
  bool get isSaving => status == ItemsStatus.saving;
  bool get isSuccess => status == ItemsStatus.success;
  bool get hasError => status == ItemsStatus.error;

  int get totalValue => items.fold(0, (sum, i) => sum + i.total);
  double get totalCount => items.fold(0.0, (sum, i) => sum + i.count);
  int get count => items.length;
}

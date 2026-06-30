import 'package:taif_alamin/data/constants/supply_type.dart';
import 'package:taif_alamin/data/models/supply_model.dart';

enum SuppliesStatus { initial, loading, success, saving, error }

class SuppliesState {
  final SuppliesStatus status;
  final List<Supply> supplies;
  final SupplyType? selectedType;
  final String? error;

  const SuppliesState({
    this.status = SuppliesStatus.initial,
    this.supplies = const [],
    this.selectedType,
    this.error,
  });

  SuppliesState copyWith({
    SuppliesStatus? status,
    List<Supply>? supplies,
    SupplyType? selectedType,
    String? error,
  }) => SuppliesState(
    status: status ?? this.status,
    supplies: supplies ?? this.supplies,
    selectedType: selectedType ?? this.selectedType,
    error: error ?? this.error,
  );

  bool get isLoading => status == SuppliesStatus.loading;
  bool get isSaving => status == SuppliesStatus.saving;
  bool get isSuccess => status == SuppliesStatus.success;
  bool get hasError => status == SuppliesStatus.error;

  /// Get count by type
  Map<SupplyType, int> get countByType {
    final counts = <SupplyType, int>{};
    for (final supply in supplies) {
      counts[supply.type] = (counts[supply.type] ?? 0) + 1;
    }
    return counts;
  }

  /// Get total unpaid
  int get totalUnpaid =>
      supplies.fold(0, (sum, supply) => sum + supply.remaining);

  /// Get unpaid supplies
  List<Supply> get unpaidSupplies => supplies.where((s) => !s.isPaid).toList();

  /// Filter by type
  List<Supply> filterByType(SupplyType type) =>
      supplies.where((s) => s.type == type).toList();
}

import 'package:taif_alamin/data/models/transport_model.dart';

enum TransportStatus { initial, loading, success, saving, error }

class TransportState {
  final TransportStatus status;
  final List<Transport> transports;
  final Transport? selectedTransport;
  final int totalPrice;
  final int averagePrice;
  final int count;
  final String? error;

  const TransportState({
    this.status = TransportStatus.initial,
    this.transports = const [],
    this.selectedTransport,
    this.totalPrice = 0,
    this.averagePrice = 0,
    this.count = 0,
    this.error,
  });

  TransportState copyWith({
    TransportStatus? status,
    List<Transport>? transports,
    Transport? selectedTransport,
    int? totalPrice,
    int? averagePrice,
    int? count,
    String? error,
  }) => TransportState(
    status: status ?? this.status,
    transports: transports ?? this.transports,
    selectedTransport: selectedTransport ?? this.selectedTransport,
    totalPrice: totalPrice ?? this.totalPrice,
    averagePrice: averagePrice ?? this.averagePrice,
    count: count ?? this.count,
    error: error ?? this.error,
  );

  bool get isLoading => status == TransportStatus.loading;
  bool get isSaving => status == TransportStatus.saving;
  bool get isSuccess => status == TransportStatus.success;
  bool get hasError => status == TransportStatus.error;

  /// Average cost per record
  int get costPerRecord => count > 0 ? (totalPrice ~/ count) : 0;

  /// Check if records are loaded
  bool get hasRecords => transports.isNotEmpty;

  /// Get sorted by price (descending)
  List<Transport> get sortedByPriceDesc =>
      [...transports]..sort((a, b) => b.price.compareTo(a.price));

  /// Get sorted by date (newest first)
  List<Transport> get sortedByDateDesc =>
      [...transports]..sort((a, b) => b.date.compareTo(a.date));

  /// Get most expensive transport
  Transport? get mostExpensive =>
      transports.isEmpty ? null : sortedByPriceDesc.first;

  /// Get least expensive transport
  Transport? get leastExpensive =>
      transports.isEmpty ? null : sortedByPriceDesc.last;
}

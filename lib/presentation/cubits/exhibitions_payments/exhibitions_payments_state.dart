import 'package:taif_alamin/data/models/exhibition_payment_model.dart';
enum ExhibitionsPaymentsStatus { initial, loading, success, saving, error }

class ExhibitionsPaymentsState {
  final ExhibitionsPaymentsStatus status;
  final List<ExhibitionPayment> payments;

  /// When set, the screen is scoped to a single exhibition (auto-refresh key).
  final String? belongTo;
  final String? error;

  const ExhibitionsPaymentsState({
    this.status = ExhibitionsPaymentsStatus.initial,
    this.payments = const [],
    this.belongTo,
    this.error,
  });

  ExhibitionsPaymentsState copyWith({
    ExhibitionsPaymentsStatus? status,
    List<ExhibitionPayment>? payments,
    String? belongTo,
    String? error,
  }) => ExhibitionsPaymentsState(
    status: status ?? this.status,
    payments: payments ?? this.payments,
    belongTo: belongTo ?? this.belongTo,
    error: error,
  );

  bool get isLoading => status == ExhibitionsPaymentsStatus.loading;
  bool get isSaving => status == ExhibitionsPaymentsStatus.saving;
  bool get isSuccess => status == ExhibitionsPaymentsStatus.success;
  bool get hasError => status == ExhibitionsPaymentsStatus.error;

  int get total => payments.fold(0, (sum, p) => sum + p.payment);
  int get count => payments.length;
}

import 'package:taif_alamin/data/models/customer_debt_model.dart';
import 'package:taif_alamin/data/models/customer_payment_model.dart';

enum DebtsStatus { initial, loading, success, saving, error }

class DebtsState {
  final DebtsStatus status;
  final List<CustomerDebt> debts;
  final Map<int, int> paidByDebtId;

  /// Payments of the currently opened debt (for the payments dialog).
  final int? openDebtId;
  final List<CustomerPayment> openPayments;
  final String? error;

  const DebtsState({
    this.status = DebtsStatus.initial,
    this.debts = const [],
    this.paidByDebtId = const {},
    this.openDebtId,
    this.openPayments = const [],
    this.error,
  });

  DebtsState copyWith({
    DebtsStatus? status,
    List<CustomerDebt>? debts,
    Map<int, int>? paidByDebtId,
    int? openDebtId,
    List<CustomerPayment>? openPayments,
    String? error,
  }) => DebtsState(
    status: status ?? this.status,
    debts: debts ?? this.debts,
    paidByDebtId: paidByDebtId ?? this.paidByDebtId,
    openDebtId: openDebtId ?? this.openDebtId,
    openPayments: openPayments ?? this.openPayments,
    error: error,
  );

  bool get isLoading => status == DebtsStatus.loading;
  bool get hasError => status == DebtsStatus.error;

  int paidOf(CustomerDebt d) => paidByDebtId[d.id] ?? 0;
  int remainingOf(CustomerDebt d) =>
      (d.finalPrice - paidOf(d)).clamp(0, d.finalPrice);

  int get openPaid =>
      openPayments.fold(0, (sum, p) => sum + p.paymentAmount);
}
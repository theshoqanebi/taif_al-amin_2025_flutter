import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taif_alamin/data/models/customer_debt_model.dart';
import 'package:taif_alamin/data/models/customer_payment_model.dart';
import 'package:taif_alamin/data/repositories/additional_amounts_repository.dart';
import 'package:taif_alamin/data/repositories/customers_debts_repository.dart';
import 'package:taif_alamin/data/repositories/customers_payments_repository.dart';
import 'package:taif_alamin/data/repositories/multi_sells_repository.dart';

enum DebtsStatus { initial, loading, success, saving, error }

class DebtsState {
  final DebtsStatus status;
  final List<CustomerDebt> debts;
  final Map<int, int> paidByDebtId;

  /// Total of the linked sale's items, keyed by bill. Used as the debt total
  /// (legacy sells debts store total_price = 0; the truth is the sale items).
  final Map<String, int> billTotals;

  final int? openDebtId;
  final List<CustomerPayment> openPayments;
  final String? error;

  const DebtsState({
    this.status = DebtsStatus.initial,
    this.debts = const [],
    this.paidByDebtId = const {},
    this.billTotals = const {},
    this.openDebtId,
    this.openPayments = const [],
    this.error,
  });

  DebtsState copyWith({
    DebtsStatus? status,
    List<CustomerDebt>? debts,
    Map<int, int>? paidByDebtId,
    Map<String, int>? billTotals,
    int? openDebtId,
    List<CustomerPayment>? openPayments,
    String? error,
  }) => DebtsState(
    status: status ?? this.status,
    debts: debts ?? this.debts,
    paidByDebtId: paidByDebtId ?? this.paidByDebtId,
    billTotals: billTotals ?? this.billTotals,
    openDebtId: openDebtId ?? this.openDebtId,
    openPayments: openPayments ?? this.openPayments,
    error: error,
  );

  bool get isLoading => status == DebtsStatus.loading;
  bool get hasError => status == DebtsStatus.error;

  /// Total = the linked sale's items total; if there is no sale (manual debt),
  /// fall back to the stored total_price.
  int totalOf(CustomerDebt d) {
    final fromItems = d.bill == null ? 0 : (billTotals[d.bill] ?? 0);
    return fromItems > 0 ? fromItems : d.totalPrice;
  }

  int finalOf(CustomerDebt d) => totalOf(d) - d.discount;
  int paidOf(CustomerDebt d) => paidByDebtId[d.id] ?? 0;

  /// May be negative (over-payment / advance) — matches the legacy app.
  int remainingOf(CustomerDebt d) => finalOf(d) - paidOf(d);

  int get openPaid => openPayments.fold(0, (sum, p) => sum + p.paymentAmount);
}

class DebtsCubit extends Cubit<DebtsState> {
  final CustomersDebtsRepository _debtsRepository = CustomersDebtsRepository();
  final CustomersPaymentsRepository _paymentsRepository =
      CustomersPaymentsRepository();
  final MultiSellsRepository _multiRepository = MultiSellsRepository();
  final AdditionalAmountsRepository _additionalRepository =
      AdditionalAmountsRepository();

  DebtsCubit() : super(const DebtsState());

  /// Sum every sale's items, grouped by bill.
  Future<Map<String, int>> _buildBillTotals() async {
    final totals = <String, int>{};
    final multi = await _multiRepository.getAll();
    for (final m in multi) {
      totals[m.bill] = (totals[m.bill] ?? 0) + m.totalPrice;
    }
    final extras = await _additionalRepository.getAll();
    for (final a in extras) {
      final bill = a.belongTo;
      if (bill != null) {
        totals[bill] = (totals[bill] ?? 0) + a.totalPrice;
      }
    }
    return totals;
  }

  Future<void> loadAll() async {
    try {
      emit(state.copyWith(status: DebtsStatus.loading));
      final debts = await _debtsRepository.getAll();
      final paid = await _paymentsRepository.totalsByDebt();
      final billTotals = await _buildBillTotals();
      emit(
        state.copyWith(
          status: DebtsStatus.success,
          debts: debts,
          paidByDebtId: paid,
          billTotals: billTotals,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: DebtsStatus.error, error: e.toString()));
    }
  }

  Future<void> openDebt(int debtId) async {
    try {
      final payments = await _paymentsRepository.getByDebtId(debtId);
      emit(state.copyWith(openDebtId: debtId, openPayments: payments));
    } catch (e) {
      emit(state.copyWith(status: DebtsStatus.error, error: e.toString()));
    }
  }

  Future<void> addPayment(CustomerPayment payment) async {
    try {
      emit(state.copyWith(status: DebtsStatus.saving));
      await _paymentsRepository.insert(payment);
      await _refresh(payment.debtId);
    } catch (e) {
      emit(state.copyWith(status: DebtsStatus.error, error: e.toString()));
    }
  }

  Future<void> updatePayment(CustomerPayment payment) async {
    try {
      emit(state.copyWith(status: DebtsStatus.saving));
      await _paymentsRepository.update(payment);
      await _refresh(payment.debtId);
    } catch (e) {
      emit(state.copyWith(status: DebtsStatus.error, error: e.toString()));
    }
  }

  Future<void> deletePayment(int id, int debtId) async {
    try {
      emit(state.copyWith(status: DebtsStatus.saving));
      await _paymentsRepository.deleteById(id);
      await _refresh(debtId);
    } catch (e) {
      emit(state.copyWith(status: DebtsStatus.error, error: e.toString()));
    }
  }

  Future<void> _refresh(int debtId) async {
    final debts = await _debtsRepository.getAll();
    final paid = await _paymentsRepository.totalsByDebt();
    final payments = await _paymentsRepository.getByDebtId(debtId);
    emit(
      state.copyWith(
        status: DebtsStatus.success,
        debts: debts,
        paidByDebtId: paid,
        openDebtId: debtId,
        openPayments: payments,
      ),
    );
  }
}

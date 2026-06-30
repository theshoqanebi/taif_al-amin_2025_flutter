import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taif_alamin/data/models/on_us_debt_model.dart';
import 'package:taif_alamin/data/models/on_us_payment_model.dart';
import 'package:taif_alamin/data/repositories/on_us_debts_repository.dart';
import 'package:taif_alamin/data/repositories/on_us_payments_repository.dart';

enum OnUsDebtsStatus { initial, loading, success, saving, error }

class OnUsDebtsState {
  final OnUsDebtsStatus status;
  final List<OnUsDebt> debts;
  final Map<int, int> paidByDebtId;

  final int? openDebtId;
  final List<OnUsPayment> openPayments;
  final String? error;

  const OnUsDebtsState({
    this.status = OnUsDebtsStatus.initial,
    this.debts = const [],
    this.paidByDebtId = const {},
    this.openDebtId,
    this.openPayments = const [],
    this.error,
  });

  OnUsDebtsState copyWith({
    OnUsDebtsStatus? status,
    List<OnUsDebt>? debts,
    Map<int, int>? paidByDebtId,
    int? openDebtId,
    List<OnUsPayment>? openPayments,
    String? error,
  }) => OnUsDebtsState(
    status: status ?? this.status,
    debts: debts ?? this.debts,
    paidByDebtId: paidByDebtId ?? this.paidByDebtId,
    openDebtId: openDebtId ?? this.openDebtId,
    openPayments: openPayments ?? this.openPayments,
    error: error,
  );

  bool get isLoading => status == OnUsDebtsStatus.loading;
  bool get hasError => status == OnUsDebtsStatus.error;

  /// No discount concept for OnUsDebts — total is whatever was entered.
  int totalOf(OnUsDebt d) => d.tPrice;
  int paidOf(OnUsDebt d) => paidByDebtId[d.id] ?? 0;

  /// May be negative (over-payment / advance) — matches the customer-debts
  /// convention: never clamp.
  int remainingOf(OnUsDebt d) => totalOf(d) - paidOf(d);

  int get openPaid => openPayments.fold(0, (sum, p) => sum + p.paymentAmount);
}

/// Debts the business itself owes to someone else ("ديون علينا") — a
/// completely separate ledger from [CustomerDebt]/DebtsCubit (money
/// customers owe the business). Every debt here is created and edited
/// directly (no Sell/Exhibition auto-creates it), so this cubit owns full
/// CRUD on the debt header itself, not just its payments.
class OnUsDebtsCubit extends Cubit<OnUsDebtsState> {
  final OnUsDebtsRepository _debtsRepository = OnUsDebtsRepository();
  final OnUsPaymentsRepository _paymentsRepository = OnUsPaymentsRepository();

  OnUsDebtsCubit() : super(const OnUsDebtsState());

  Future<void> loadAll() async {
    try {
      emit(state.copyWith(status: OnUsDebtsStatus.loading));
      final debts = await _debtsRepository.getAll();
      final paid = await _paymentsRepository.totalsByDebt();
      emit(
        state.copyWith(
          status: OnUsDebtsStatus.success,
          debts: debts,
          paidByDebtId: paid,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: OnUsDebtsStatus.error, error: e.toString()));
    }
  }

  Future<void> add(OnUsDebt debt) async {
    try {
      emit(state.copyWith(status: OnUsDebtsStatus.saving));
      await _debtsRepository.insert(debt);
      await loadAll();
    } catch (e) {
      emit(state.copyWith(status: OnUsDebtsStatus.error, error: e.toString()));
    }
  }

  Future<void> update(OnUsDebt debt) async {
    try {
      emit(state.copyWith(status: OnUsDebtsStatus.saving));
      await _debtsRepository.update(debt);
      await loadAll();
    } catch (e) {
      emit(state.copyWith(status: OnUsDebtsStatus.error, error: e.toString()));
    }
  }

  /// Deletes the debt and all of its payments. The schema declares
  /// ON DELETE CASCADE on OnUsPayments, but payments are deleted
  /// explicitly first too — defensive in case PRAGMA foreign_keys was ever
  /// off when a row was inserted.
  Future<void> delete(int id) async {
    try {
      emit(state.copyWith(status: OnUsDebtsStatus.saving));
      await _paymentsRepository.deleteByDebtId(id);
      await _debtsRepository.deleteById(id);
      await loadAll();
    } catch (e) {
      emit(state.copyWith(status: OnUsDebtsStatus.error, error: e.toString()));
    }
  }

  Future<void> openDebt(int debtId) async {
    try {
      final payments = await _paymentsRepository.getByDebtId(debtId);
      emit(state.copyWith(openDebtId: debtId, openPayments: payments));
    } catch (e) {
      emit(state.copyWith(status: OnUsDebtsStatus.error, error: e.toString()));
    }
  }

  Future<void> addPayment(OnUsPayment payment) async {
    try {
      emit(state.copyWith(status: OnUsDebtsStatus.saving));
      await _paymentsRepository.insert(payment);
      await _refresh(payment.debtId);
    } catch (e) {
      emit(state.copyWith(status: OnUsDebtsStatus.error, error: e.toString()));
    }
  }

  Future<void> updatePayment(OnUsPayment payment) async {
    try {
      emit(state.copyWith(status: OnUsDebtsStatus.saving));
      await _paymentsRepository.update(payment);
      await _refresh(payment.debtId);
    } catch (e) {
      emit(state.copyWith(status: OnUsDebtsStatus.error, error: e.toString()));
    }
  }

  Future<void> deletePayment(int id, int debtId) async {
    try {
      emit(state.copyWith(status: OnUsDebtsStatus.saving));
      await _paymentsRepository.deleteById(id);
      await _refresh(debtId);
    } catch (e) {
      emit(state.copyWith(status: OnUsDebtsStatus.error, error: e.toString()));
    }
  }

  Future<void> _refresh(int debtId) async {
    final debts = await _debtsRepository.getAll();
    final paid = await _paymentsRepository.totalsByDebt();
    final payments = await _paymentsRepository.getByDebtId(debtId);
    emit(
      state.copyWith(
        status: OnUsDebtsStatus.success,
        debts: debts,
        paidByDebtId: paid,
        openDebtId: debtId,
        openPayments: payments,
      ),
    );
  }
}

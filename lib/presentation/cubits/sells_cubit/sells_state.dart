import 'package:taif_alamin/data/constants/currency.dart';
import 'package:taif_alamin/data/models/additional_amount_model.dart';
import 'package:taif_alamin/data/models/customer_debt_model.dart';
import 'package:taif_alamin/data/models/multi_sells_model.dart';
import 'package:taif_alamin/data/models/sells_model.dart';

enum SellsStatus { initial, loading, success, saving, error }

class SellsState {
  final SellsStatus status;
  final List<Sell> sells;

  /// Each sale's total computed from its items (multiSells + additionalAmount),
  /// keyed by sell id. This mirrors the legacy SellsItem.getTotalPrice().
  final Map<int, int> childTotals;

  /// Linked debt keyed by Sells.payment_uuid.
  final Map<String, CustomerDebt> debtByUuid;

  /// Linked debt keyed by bill_number (fallback when uuid doesn't match,
  /// mirroring the legacy SellsItem.getCustomerDebt()).
  final Map<String, CustomerDebt> debtByBill;

  /// Paid amount keyed by debt id.
  final Map<int, int> paidByDebtId;

  final List<MultiSell> draftMultiSells;
  final List<AdditionalAmount> draftAdditional;
  final String? error;

  const SellsState({
    this.status = SellsStatus.initial,
    this.sells = const [],
    this.childTotals = const {},
    this.debtByUuid = const {},
    this.debtByBill = const {},
    this.paidByDebtId = const {},
    this.draftMultiSells = const [],
    this.draftAdditional = const [],
    this.error,
  });

  SellsState copyWith({
    SellsStatus? status,
    List<Sell>? sells,
    Map<int, int>? childTotals,
    Map<String, CustomerDebt>? debtByUuid,
    Map<String, CustomerDebt>? debtByBill,
    Map<int, int>? paidByDebtId,
    List<MultiSell>? draftMultiSells,
    List<AdditionalAmount>? draftAdditional,
    String? error,
  }) => SellsState(
    status: status ?? this.status,
    sells: sells ?? this.sells,
    childTotals: childTotals ?? this.childTotals,
    debtByUuid: debtByUuid ?? this.debtByUuid,
    debtByBill: debtByBill ?? this.debtByBill,
    paidByDebtId: paidByDebtId ?? this.paidByDebtId,
    draftMultiSells: draftMultiSells ?? this.draftMultiSells,
    draftAdditional: draftAdditional ?? this.draftAdditional,
    error: error,
  );

  bool get isLoading => status == SellsStatus.loading;
  bool get isSaving => status == SellsStatus.saving;
  bool get isSuccess => status == SellsStatus.success;
  bool get hasError => status == SellsStatus.error;

  // ---- financial accessors (debt-backed, with child fallback) ----
  /// Match the debt by payment_uuid first, then by bill (legacy fallback).
  CustomerDebt? debtOf(Sell s) {
    if (s.paymentUuid != null && debtByUuid.containsKey(s.paymentUuid)) {
      return debtByUuid[s.paymentUuid];
    }
    return debtByBill[s.bill];
  }

  /// Total = sale items (authoritative). Falls back to the debt's stored
  /// total_price only if items are unavailable.
  int totalOf(Sell s) => (childTotals[s.id] ?? 0) > 0
      ? childTotals[s.id]!
      : (debtOf(s)?.totalPrice ?? 0);

  int discountOf(Sell s) => debtOf(s)?.discount ?? 0;
  int finalOf(Sell s) => totalOf(s) - discountOf(s);
  int paidOf(Sell s) {
    final d = debtOf(s);
    return d == null ? 0 : (paidByDebtId[d.id] ?? 0);
  }

  int remainingOf(Sell s) => finalOf(s) - paidOf(s);
  Currency currencyOf(Sell s) => debtOf(s)?.currency ?? Currency.iqd;

  // ---- draft ----
  int get draftMultiTotal =>
      draftMultiSells.fold(0, (sum, m) => sum + m.totalPrice);
  int get draftAdditionalTotal =>
      draftAdditional.fold(0, (sum, a) => sum + a.totalPrice);
  int get draftTotal => draftMultiTotal + draftAdditionalTotal;

  // ---- footer aggregates by currency ----
  int remainingByCurrency(bool usd) => sells
      .where((s) => (currencyOf(s).name == 'usd') == usd)
      .fold(0, (sum, s) => sum + remainingOf(s));

  int paidByCurrency(bool usd) => sells
      .where((s) => (currencyOf(s).name == 'usd') == usd)
      .fold(0, (sum, s) => sum + paidOf(s));

  int get count => sells.length;
}

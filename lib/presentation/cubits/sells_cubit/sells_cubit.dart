import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taif_alamin/data/models/additional_amount_model.dart';
import 'package:taif_alamin/data/models/customer_debt_model.dart';
import 'package:taif_alamin/data/models/multi_sells_model.dart';
import 'package:taif_alamin/data/models/sells_model.dart';
import 'package:taif_alamin/data/repositories/additional_amounts_repository.dart';
import 'package:taif_alamin/data/repositories/customers_debts_repository.dart';
import 'package:taif_alamin/data/repositories/customers_payments_repository.dart';
import 'package:taif_alamin/data/repositories/multi_sells_repository.dart';
import 'package:taif_alamin/data/repositories/sells_repository.dart';
import 'package:taif_alamin/presentation/cubits/sells_cubit/sells_state.dart';

class SellsCubit extends Cubit<SellsState> {
  final SellsRepository _repository = SellsRepository();
  final MultiSellsRepository _multiSellsRepository = MultiSellsRepository();
  final AdditionalAmountsRepository _additionalRepository =
      AdditionalAmountsRepository();
  final CustomersDebtsRepository _debtsRepository = CustomersDebtsRepository();
  final CustomersPaymentsRepository _paymentsRepository =
      CustomersPaymentsRepository();

  SellsCubit() : super(const SellsState());

  /// Load sales + their debts + paid amounts. Sales without a debt fall back
  /// to a total computed from their children.
  Future<void> loadSells() async {
    try {
      emit(state.copyWith(status: SellsStatus.loading));
      final sells = await _repository.getAll();

      final debts = await _debtsRepository.getAll();
      final debtByUuid = <String, CustomerDebt>{};
      final debtByBill = <String, CustomerDebt>{};
      for (final d in debts) {
        if (d.uuid != null && d.uuid!.isNotEmpty) debtByUuid[d.uuid!] = d;
        if (d.bill != null && d.bill!.isNotEmpty) debtByBill[d.bill!] = d;
      }
      final paidByDebtId = await _paymentsRepository.totalsByDebt();

      // Each sale's total from its own items (mirrors SellsItem.getTotalPrice).
      final childTotals = <int, int>{};
      for (final s in sells) {
        childTotals[s.id] = await s.computeTotal();
      }

      emit(
        state.copyWith(
          status: SellsStatus.success,
          sells: sells,
          debtByUuid: debtByUuid,
          debtByBill: debtByBill,
          paidByDebtId: paidByDebtId,
          childTotals: childTotals,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: SellsStatus.error, error: e.toString()));
    }
  }

  Future<int> nextBillNumber() async {
    try {
      return (await _repository.maxBillNumber()) + 1;
    } catch (_) {
      return 1;
    }
  }

  // ---- draft management ----
  void addDraftMultiSell(MultiSell item) =>
      emit(state.copyWith(draftMultiSells: [...state.draftMultiSells, item]));

  void replaceDraftMultiSell(int index, MultiSell item) {
    final list = [...state.draftMultiSells];
    if (index >= 0 && index < list.length) {
      list[index] = item;
      emit(state.copyWith(draftMultiSells: list));
    }
  }

  void removeDraftMultiSellAt(int index) {
    final list = [...state.draftMultiSells]..removeAt(index);
    emit(state.copyWith(draftMultiSells: list));
  }

  void addDraftAdditional(AdditionalAmount item) =>
      emit(state.copyWith(draftAdditional: [...state.draftAdditional, item]));

  void replaceDraftAdditional(int index, AdditionalAmount item) {
    final list = [...state.draftAdditional];
    if (index >= 0 && index < list.length) {
      list[index] = item;
      emit(state.copyWith(draftAdditional: list));
    }
  }

  void removeDraftAdditionalAt(int index) {
    final list = [...state.draftAdditional]..removeAt(index);
    emit(state.copyWith(draftAdditional: list));
  }

  void clearDraft() =>
      emit(state.copyWith(draftMultiSells: [], draftAdditional: []));

  /// Load an existing sale's children into the draft (by bill) for editing.
  Future<void> loadDraftFor(String bill) async {
    try {
      final multi = await _multiSellsRepository.getByBill(bill);
      final extras = await _additionalRepository.getByBill(bill);
      emit(state.copyWith(draftMultiSells: multi, draftAdditional: extras));
    } catch (e) {
      emit(state.copyWith(status: SellsStatus.error, error: e.toString()));
    }
  }

  // ---- persistence (sale + linked debt + first payment) ----
  Future<void> createSell(
    Sell sell, {
    required CustomerDebt debt,
    int firstPayment = 0,
  }) async {
    try {
      emit(state.copyWith(status: SellsStatus.saving));
      if (await _repository.billExists(sell.bill)) {
        emit(
          state.copyWith(
            status: SellsStatus.error,
            error: 'رقم الوصل ${sell.bill} موجود مسبقاً',
          ),
        );
        return;
      }
      await _repository.createFull(
        sell: sell,
        multiSells: state.draftMultiSells,
        additionalAmounts: state.draftAdditional,
        debt: debt,
        firstPayment: firstPayment,
      );
      clearDraft();
      await loadSells();
    } catch (e) {
      emit(state.copyWith(status: SellsStatus.error, error: e.toString()));
    }
  }

  Future<void> updateSell(Sell sell, {required CustomerDebt debt}) async {
    try {
      emit(state.copyWith(status: SellsStatus.saving));
      if (await _repository.billExists(sell.bill, excludeId: sell.id)) {
        emit(
          state.copyWith(
            status: SellsStatus.error,
            error: 'رقم الوصل ${sell.bill} موجود مسبقاً',
          ),
        );
        return;
      }
      await _repository.updateFull(
        sell: sell,
        multiSells: state.draftMultiSells,
        additionalAmounts: state.draftAdditional,
        debt: debt,
      );
      clearDraft();
      await loadSells();
    } catch (e) {
      emit(state.copyWith(status: SellsStatus.error, error: e.toString()));
    }
  }

  Future<void> deleteSell(Sell sell) async {
    try {
      emit(state.copyWith(status: SellsStatus.saving));
      await _repository.deleteFull(sell);
      await loadSells();
    } catch (e) {
      emit(state.copyWith(status: SellsStatus.error, error: e.toString()));
    }
  }
}

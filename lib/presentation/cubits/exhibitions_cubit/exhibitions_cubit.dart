import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taif_alamin/data/models/exhibition_additional_amount_model.dart';
import 'package:taif_alamin/data/models/exhibition_model.dart';
import 'package:taif_alamin/data/models/exhibition_multi_sell_model.dart';
import 'package:taif_alamin/data/repositories/exhibitions_additional_amount_repository.dart';
import 'package:taif_alamin/data/repositories/exhibitions_multi_sells_repository.dart';
import 'package:taif_alamin/data/repositories/exhibitions_repository.dart';
import 'package:taif_alamin/presentation/cubits/exhibitions_cubit/exhibitions_state.dart';

class ExhibitionsCubit extends Cubit<ExhibitionsState> {
  final ExhibitionsRepository _repository = ExhibitionsRepository();
  final ExhibitionsMultiSellsRepository _multiRepo =
      ExhibitionsMultiSellsRepository();
  final ExhibitionsAdditionalAmountRepository _additionalRepo =
      ExhibitionsAdditionalAmountRepository();

  ExhibitionsCubit() : super(const ExhibitionsState());

  /// Load all exhibitions for a showroom + compute each one's total.
  Future<void> loadByBelongTo(String belongTo) async {
    try {
      emit(
        state.copyWith(status: ExhibitionsStatus.loading, belongTo: belongTo),
      );
      final exhibitions = await _repository.getByBelongTo(belongTo);

      final totals = <int, int>{};
      for (final e in exhibitions) {
        totals[e.id] = await e.computeTotal();
      }

      emit(
        state.copyWith(
          status: ExhibitionsStatus.success,
          exhibitions: exhibitions,
          totals: totals,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: ExhibitionsStatus.error, error: e.toString()),
      );
    }
  }

  Future<void> _reload() async {
    final belongTo = state.belongTo;
    if (belongTo != null) await loadByBelongTo(belongTo);
  }

  /// Next bill number for this showroom (its own max + 1) — each showroom
  /// keeps its own sequence, matching the legacy app.
  Future<int> nextBillNumber() async {
    try {
      final belongTo = state.belongTo ?? '';
      final max = await _repository.maxBillNumber(belongTo);
      return max + 1;
    } catch (_) {
      return 1;
    }
  }

  // ---- draft management ----
  void addDraftMultiSell(ExhibitionMultiSell item) =>
      emit(state.copyWith(draftMultiSells: [...state.draftMultiSells, item]));

  void replaceDraftMultiSell(int index, ExhibitionMultiSell item) {
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

  void addDraftAdditional(ExhibitionAdditionalAmount item) =>
      emit(state.copyWith(draftAdditional: [...state.draftAdditional, item]));

  void replaceDraftAdditional(int index, ExhibitionAdditionalAmount item) {
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

  /// Load an existing exhibition's children into the draft (for editing).
  Future<void> loadDraftFor(String bill) async {
    try {
      final belongTo = state.belongTo ?? '';
      final multi = await _multiRepo.getByBill(bill, belongTo);
      final extras = await _additionalRepo.getByBill(bill, belongTo);
      emit(state.copyWith(draftMultiSells: multi, draftAdditional: extras));
    } catch (e) {
      emit(
        state.copyWith(status: ExhibitionsStatus.error, error: e.toString()),
      );
    }
  }

  // ---- persistence ----
  Future<void> createExhibition(Exhibition exhibition) async {
    try {
      emit(state.copyWith(status: ExhibitionsStatus.saving));
      if (await _repository.billExists(
        exhibition.bill,
        belongTo: exhibition.belongTo ?? state.belongTo ?? '',
      )) {
        emit(
          state.copyWith(
            status: ExhibitionsStatus.error,
            error: 'رقم الوصل ${exhibition.bill} موجود مسبقاً',
          ),
        );
        return;
      }
      await _repository.createFull(
        exhibition: exhibition,
        multiSells: state.draftMultiSells,
        additionalAmounts: state.draftAdditional,
      );
      clearDraft();
      await _reload();
    } catch (e) {
      emit(
        state.copyWith(status: ExhibitionsStatus.error, error: e.toString()),
      );
    }
  }

  Future<void> updateExhibition(Exhibition exhibition) async {
    try {
      emit(state.copyWith(status: ExhibitionsStatus.saving));
      if (await _repository.billExists(
        exhibition.bill,
        belongTo: exhibition.belongTo ?? state.belongTo ?? '',
        excludeId: exhibition.id,
      )) {
        emit(
          state.copyWith(
            status: ExhibitionsStatus.error,
            error: 'رقم الوصل ${exhibition.bill} موجود مسبقاً',
          ),
        );
        return;
      }
      await _repository.updateFull(
        exhibition: exhibition,
        multiSells: state.draftMultiSells,
        additionalAmounts: state.draftAdditional,
      );
      clearDraft();
      await _reload();
    } catch (e) {
      emit(
        state.copyWith(status: ExhibitionsStatus.error, error: e.toString()),
      );
    }
  }

  Future<void> deleteExhibition(Exhibition exhibition) async {
    try {
      emit(state.copyWith(status: ExhibitionsStatus.saving));
      await _repository.deleteFull(exhibition);
      await _reload();
    } catch (e) {
      emit(
        state.copyWith(status: ExhibitionsStatus.error, error: e.toString()),
      );
    }
  }
}
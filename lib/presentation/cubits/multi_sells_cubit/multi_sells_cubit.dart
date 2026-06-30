import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taif_alamin/data/models/multi_sells_model.dart';
import 'package:taif_alamin/data/repositories/multi_sells_repository.dart';
import 'package:taif_alamin/presentation/cubits/multi_sells_cubit/multi_sells_status.dart';

class MultiSellsCubit extends Cubit<MultiSellsState> {
  final MultiSellsRepository _repository = MultiSellsRepository();

  MultiSellsCubit() : super(const MultiSellsState());

  /// Load all multi-sells for a bill
  Future<void> loadByBill(String bill) async {
    try {
      emit(state.copyWith(status: MultiSellsStatus.loading));
      final items = await _repository.getByBill(bill);
      emit(state.copyWith(status: MultiSellsStatus.success, items: items));
    } catch (e) {
      emit(state.copyWith(status: MultiSellsStatus.error, error: e.toString()));
    }
  }

  /// Add a new multi-sell
  Future<void> add(MultiSell item) async {
    try {
      await _repository.insert(item);
      emit(
        state.copyWith(
          status: MultiSellsStatus.success,
          items: [...state.items, item],
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: MultiSellsStatus.error, error: e.toString()));
    }
  }

  /// Update an existing multi-sell
  Future<void> update(MultiSell item) async {
    try {
      await _repository.update(item);
      emit(
        state.copyWith(
          status: MultiSellsStatus.success,
          items: [
            for (final existing in state.items)
              if (existing.id == item.id) item else existing,
          ],
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: MultiSellsStatus.error, error: e.toString()));
    }
  }

  /// Delete a multi-sell
  Future<void> delete(int id) async {
    try {
      await _repository.deleteById(id);
      emit(
        state.copyWith(
          status: MultiSellsStatus.success,
          items: state.items.where((item) => item.id != id).toList(),
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: MultiSellsStatus.error, error: e.toString()));
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taif_alamin/data/models/item_model.dart';
import 'package:taif_alamin/data/repositories/item_repository.dart';
import 'package:taif_alamin/presentation/cubits/items_cubit/item_state.dart';

class ItemsCubit extends Cubit<ItemsState> {
  final ItemsRepository _repository = ItemsRepository();

  ItemsCubit() : super(const ItemsState());

  /// Load items for a category (belongTo).
  Future<void> loadByBelongTo(String belongTo) async {
    try {
      emit(state.copyWith(status: ItemsStatus.loading, belongTo: belongTo));
      final items = await _repository.getByBelongTo(belongTo);
      emit(state.copyWith(status: ItemsStatus.success, items: items));
    } catch (e) {
      emit(state.copyWith(status: ItemsStatus.error, error: e.toString()));
    }
  }

  /// Re-query the current category from the DB.
  Future<void> _reload() async {
    final belongTo = state.belongTo;
    if (belongTo == null) return;
    final items = await _repository.getByBelongTo(belongTo);
    emit(state.copyWith(status: ItemsStatus.success, items: items));
  }

  Future<void> add(Item item) async {
    try {
      emit(state.copyWith(status: ItemsStatus.saving));
      await _repository.insert(item);
      await _reload();
    } catch (e) {
      emit(state.copyWith(status: ItemsStatus.error, error: e.toString()));
    }
  }

  Future<void> update(Item item) async {
    try {
      emit(state.copyWith(status: ItemsStatus.saving));
      await _repository.update(item);
      await _reload();
    } catch (e) {
      emit(state.copyWith(status: ItemsStatus.error, error: e.toString()));
    }
  }

  Future<void> delete(int id) async {
    try {
      emit(state.copyWith(status: ItemsStatus.saving));
      await _repository.deleteById(id);
      await _reload();
    } catch (e) {
      emit(state.copyWith(status: ItemsStatus.error, error: e.toString()));
    }
  }
}

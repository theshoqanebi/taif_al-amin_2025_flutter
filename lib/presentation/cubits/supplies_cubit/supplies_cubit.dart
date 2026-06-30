import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taif_alamin/data/constants/supply_type.dart';
import 'package:taif_alamin/data/models/supply_model.dart';
import 'package:taif_alamin/data/repositories/supplies_repository.dart';
import 'package:taif_alamin/presentation/cubits/supplies_cubit/supplies_state.dart';

class SuppliesCubit extends Cubit<SuppliesState> {
  final SuppliesRepository _repository = SuppliesRepository();

  SuppliesCubit() : super(const SuppliesState());

  /// Load all supplies
  Future<void> loadAll() async {
    try {
      emit(state.copyWith(status: SuppliesStatus.loading));
      final supplies = await _repository.getAll();
      emit(state.copyWith(status: SuppliesStatus.success, supplies: supplies));
    } catch (e) {
      emit(state.copyWith(status: SuppliesStatus.error, error: e.toString()));
    }
  }

  /// Load supplies by type (paint, wood, sponge, fabric)
  Future<void> loadByType(SupplyType type) async {
    try {
      emit(state.copyWith(status: SuppliesStatus.loading));
      final supplies = await _repository.getByType(type);
      emit(
        state.copyWith(
          status: SuppliesStatus.success,
          supplies: supplies,
          selectedType: type,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: SuppliesStatus.error, error: e.toString()));
    }
  }

  /// Load supplies by type AND belongTo (third-screen filtered view)
  Future<void> loadByTypeAndBelongTo(SupplyType type, String belongTo) async {
    try {
      emit(state.copyWith(status: SuppliesStatus.loading));
      final supplies = await _repository.getByTypeAndBelongTo(type, belongTo);
      emit(
        state.copyWith(
          status: SuppliesStatus.success,
          supplies: supplies,
          selectedType: type,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: SuppliesStatus.error, error: e.toString()));
    }
  }

  /// Load only unpaid supplies
  Future<void> loadUnpaid() async {
    try {
      emit(state.copyWith(status: SuppliesStatus.loading));
      final supplies = await _repository.getUnpaid();
      emit(state.copyWith(status: SuppliesStatus.success, supplies: supplies));
    } catch (e) {
      emit(state.copyWith(status: SuppliesStatus.error, error: e.toString()));
    }
  }

  /// Load unpaid supplies by type
  Future<void> loadUnpaidByType(SupplyType type) async {
    try {
      emit(state.copyWith(status: SuppliesStatus.loading));
      final supplies = await _repository.getUnpaidByType(type);
      emit(state.copyWith(status: SuppliesStatus.success, supplies: supplies));
    } catch (e) {
      emit(state.copyWith(status: SuppliesStatus.error, error: e.toString()));
    }
  }

  /// Add a new supply
  Future<void> add(Supply supply) async {
    try {
      emit(state.copyWith(status: SuppliesStatus.saving));
      await _repository.insert(supply);
      emit(
        state.copyWith(
          status: SuppliesStatus.success,
          supplies: [...state.supplies, supply],
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: SuppliesStatus.error, error: e.toString()));
    }
  }

  /// Update an existing supply
  Future<void> update(Supply supply) async {
    try {
      emit(state.copyWith(status: SuppliesStatus.saving));
      await _repository.update(supply);
      emit(
        state.copyWith(
          status: SuppliesStatus.success,
          supplies: [
            for (final existing in state.supplies)
              if (existing.id == supply.id) supply else existing,
          ],
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: SuppliesStatus.error, error: e.toString()));
    }
  }

  /// Delete a supply
  Future<void> delete(int id) async {
    try {
      emit(state.copyWith(status: SuppliesStatus.saving));
      await _repository.deleteById(id);
      emit(
        state.copyWith(
          status: SuppliesStatus.success,
          supplies: state.supplies.where((s) => s.id != id).toList(),
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: SuppliesStatus.error, error: e.toString()));
    }
  }

  /// Get total unpaid by type (useful for display)
  Future<int> getTotalUnpaidByType(SupplyType type) async {
    try {
      return await _repository.getTotalUnpaidByType(type);
    } catch (e) {
      return 0;
    }
  }
}

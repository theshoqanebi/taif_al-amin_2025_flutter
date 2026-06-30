import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taif_alamin/data/models/additional_amount_model.dart';
import 'package:taif_alamin/data/repositories/additional_amounts_repository.dart';
import 'package:taif_alamin/presentation/cubits/additional_amounts_cubit/additional_amounts_state.dart';

class AdditionalAmountsCubit extends Cubit<AdditionalAmountsState> {
  final AdditionalAmountsRepository _repository = AdditionalAmountsRepository();

  AdditionalAmountsCubit() : super(const AdditionalAmountsState());

  /// Add
  Future<void> add(AdditionalAmount item) async {
    try {
      await _repository.insert(item);
      emit(
        state.copyWith(
          status: AdditionalAmountsStatus.success,
          items: [...state.items, item],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AdditionalAmountsStatus.error,
          error: e.toString(),
        ),
      );
    }
  }

  /// Delete
  Future<void> delete(int id) async {
    try {
      await _repository.deleteById(id);
      emit(
        state.copyWith(
          status: AdditionalAmountsStatus.success,
          items: state.items.where((item) => item.id != id).toList(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AdditionalAmountsStatus.error,
          error: e.toString(),
        ),
      );
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taif_alamin/data/models/exhibition_payment_model.dart';
import 'package:taif_alamin/data/repositories/exhibitions_payments_repository.dart';
import 'package:taif_alamin/presentation/cubits/exhibitions_payments/exhibitions_payments_state.dart';

class ExhibitionsPaymentsCubit extends Cubit<ExhibitionsPaymentsState> {
  final ExhibitionsPaymentsRepository _repository =
      ExhibitionsPaymentsRepository();

  ExhibitionsPaymentsCubit() : super(const ExhibitionsPaymentsState());

  /// Load all payments.
  Future<void> loadAll() async {
    try {
      emit(state.copyWith(status: ExhibitionsPaymentsStatus.loading));
      final payments = await _repository.getAll();
      emit(
        state.copyWith(
          status: ExhibitionsPaymentsStatus.success,
          payments: payments,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ExhibitionsPaymentsStatus.error,
          error: e.toString(),
        ),
      );
    }
  }

  /// Load payments scoped to a single exhibition.
  Future<void> loadByBelongTo(String belongTo) async {
    try {
      emit(
        state.copyWith(
          status: ExhibitionsPaymentsStatus.loading,
          belongTo: belongTo,
        ),
      );
      final payments = await _repository.getByBelongTo(belongTo);
      emit(
        state.copyWith(
          status: ExhibitionsPaymentsStatus.success,
          payments: payments,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ExhibitionsPaymentsStatus.error,
          error: e.toString(),
        ),
      );
    }
  }

  /// Re-query from the DB using the current scope (all or one exhibition).
  Future<void> _reload() async {
    final belongTo = state.belongTo;
    final payments = belongTo == null
        ? await _repository.getAll()
        : await _repository.getByBelongTo(belongTo);
    emit(
      state.copyWith(
        status: ExhibitionsPaymentsStatus.success,
        payments: payments,
      ),
    );
  }

  Future<void> add(ExhibitionPayment payment) async {
    try {
      emit(state.copyWith(status: ExhibitionsPaymentsStatus.saving));
      await _repository.insert(payment);
      await _reload();
    } catch (e) {
      emit(
        state.copyWith(
          status: ExhibitionsPaymentsStatus.error,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> update(ExhibitionPayment payment) async {
    try {
      emit(state.copyWith(status: ExhibitionsPaymentsStatus.saving));
      await _repository.update(payment);
      await _reload();
    } catch (e) {
      emit(
        state.copyWith(
          status: ExhibitionsPaymentsStatus.error,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> delete(int id) async {
    try {
      emit(state.copyWith(status: ExhibitionsPaymentsStatus.saving));
      await _repository.deleteById(id);
      await _reload();
    } catch (e) {
      emit(
        state.copyWith(
          status: ExhibitionsPaymentsStatus.error,
          error: e.toString(),
        ),
      );
    }
  }
}

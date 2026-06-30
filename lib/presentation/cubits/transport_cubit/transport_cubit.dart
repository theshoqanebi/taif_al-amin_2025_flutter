import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taif_alamin/data/models/transport_model.dart';
import 'package:taif_alamin/data/repositories/transport_repository.dart';
import 'package:taif_alamin/presentation/cubits/transport_cubit/transport_state.dart';

class TransportCubit extends Cubit<TransportState> {
  final TransportRepository _repository = TransportRepository();

  TransportCubit() : super(const TransportState());

  /// Load all transport records
  Future<void> loadAll() async {
    try {
      emit(state.copyWith(status: TransportStatus.loading));
      final transports = await _repository.getAll();
      final total = await _repository.getTotalPrice();
      final count = await _repository.getCount();
      final average = await _repository.getAveragePrice();

      emit(
        state.copyWith(
          status: TransportStatus.success,
          transports: transports,
          totalPrice: total,
          averagePrice: average,
          count: count,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: TransportStatus.error, error: e.toString()));
    }
  }

  /// Load transport records from last N days
  Future<void> loadFromLastDays(int days) async {
    try {
      emit(state.copyWith(status: TransportStatus.loading));
      final transports = await _repository.getFromLastDays(days);
      final total = await _repository.getTotalPriceByDateRange(
        DateTime.now().subtract(Duration(days: days)),
        DateTime.now(),
      );

      emit(
        state.copyWith(
          status: TransportStatus.success,
          transports: transports,
          totalPrice: total,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: TransportStatus.error, error: e.toString()));
    }
  }

  /// Load transport records within date range
  Future<void> loadByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      emit(state.copyWith(status: TransportStatus.loading));
      final transports = await _repository.getByDateRange(startDate, endDate);
      final total = await _repository.getTotalPriceByDateRange(
        startDate,
        endDate,
      );

      emit(
        state.copyWith(
          status: TransportStatus.success,
          transports: transports,
          totalPrice: total,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: TransportStatus.error, error: e.toString()));
    }
  }

  /// Load single transport by ID
  Future<void> loadById(int id) async {
    try {
      emit(state.copyWith(status: TransportStatus.loading));
      final transport = await _repository.getById(id);
      if (transport == null) {
        emit(
          state.copyWith(
            status: TransportStatus.error,
            error: 'Transport record not found',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: TransportStatus.success,
          selectedTransport: transport,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: TransportStatus.error, error: e.toString()));
    }
  }

  /// Load latest transport record
  Future<void> loadLatest() async {
    try {
      final transport = await _repository.getLatest();
      if (transport != null) {
        emit(
          state.copyWith(
            status: TransportStatus.success,
            selectedTransport: transport,
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(status: TransportStatus.error, error: e.toString()));
    }
  }

  /// Add a new transport record
  Future<void> add(Transport transport) async {
    try {
      emit(state.copyWith(status: TransportStatus.saving));
      await _repository.insert(transport);
      emit(
        state.copyWith(
          status: TransportStatus.success,
          transports: [...state.transports, transport],
        ),
      );
      // Reload stats
      await loadAll();
    } catch (e) {
      emit(state.copyWith(status: TransportStatus.error, error: e.toString()));
    }
  }

  /// Update a transport record
  Future<void> update(Transport transport) async {
    try {
      emit(state.copyWith(status: TransportStatus.saving));
      await _repository.update(transport);
      emit(
        state.copyWith(
          status: TransportStatus.success,
          transports: [
            for (final existing in state.transports)
              if (existing.id == transport.id) transport else existing,
          ],
        ),
      );
      // Reload stats
      await loadAll();
    } catch (e) {
      emit(state.copyWith(status: TransportStatus.error, error: e.toString()));
    }
  }

  /// Delete a transport record
  Future<void> delete(int id) async {
    try {
      emit(state.copyWith(status: TransportStatus.saving));
      await _repository.deleteById(id);
      emit(
        state.copyWith(
          status: TransportStatus.success,
          transports: state.transports.where((t) => t.id != id).toList(),
        ),
      );
      // Reload stats
      await loadAll();
    } catch (e) {
      emit(state.copyWith(status: TransportStatus.error, error: e.toString()));
    }
  }
}

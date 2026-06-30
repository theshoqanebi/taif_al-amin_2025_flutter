import 'package:taif_alamin/data/constants/currency.dart';
import 'package:taif_alamin/data/models/exhibition_additional_amount_model.dart';
import 'package:taif_alamin/data/models/exhibition_model.dart';
import 'package:taif_alamin/data/models/exhibition_multi_sell_model.dart';

enum ExhibitionsStatus { initial, loading, success, saving, error }

class ExhibitionsState {
  final ExhibitionsStatus status;

  /// Saved exhibitions (invoices) for the current showroom.
  final List<Exhibition> exhibitions;

  /// exhibitionId -> computed total (sum of its children).
  final Map<int, int> totals;

  /// The showroom this screen is scoped to.
  final String? belongTo;

  /// Draft children being edited before saving.
  final List<ExhibitionMultiSell> draftMultiSells;
  final List<ExhibitionAdditionalAmount> draftAdditional;

  final String? error;

  const ExhibitionsState({
    this.status = ExhibitionsStatus.initial,
    this.exhibitions = const [],
    this.totals = const {},
    this.belongTo,
    this.draftMultiSells = const [],
    this.draftAdditional = const [],
    this.error,
  });

  ExhibitionsState copyWith({
    ExhibitionsStatus? status,
    List<Exhibition>? exhibitions,
    Map<int, int>? totals,
    String? belongTo,
    List<ExhibitionMultiSell>? draftMultiSells,
    List<ExhibitionAdditionalAmount>? draftAdditional,
    String? error,
  }) => ExhibitionsState(
    status: status ?? this.status,
    exhibitions: exhibitions ?? this.exhibitions,
    totals: totals ?? this.totals,
    belongTo: belongTo ?? this.belongTo,
    draftMultiSells: draftMultiSells ?? this.draftMultiSells,
    draftAdditional: draftAdditional ?? this.draftAdditional,
    error: error,
  );

  bool get isLoading => status == ExhibitionsStatus.loading;
  bool get isSaving => status == ExhibitionsStatus.saving;
  bool get isSuccess => status == ExhibitionsStatus.success;
  bool get hasError => status == ExhibitionsStatus.error;

  int totalOf(Exhibition e) => totals[e.id] ?? 0;

  /// Final price after discount for an exhibition.
  int finalOf(Exhibition e) => (totalOf(e) - e.discount).clamp(0, totalOf(e));

  int get draftMultiTotal =>
      draftMultiSells.fold(0, (sum, m) => sum + m.totalPrice);
  int get draftAdditionalTotal =>
      draftAdditional.fold(0, (sum, a) => sum + a.totalPrice);
  int get draftTotal => draftMultiTotal + draftAdditionalTotal;

  int get count => exhibitions.length;

  /// المجموع الكلي النهائي — sum of [finalOf] across every exhibition
  /// currently loaded for this showroom, regardless of currency.
  int get grandFinalTotal =>
      exhibitions.fold(0, (sum, e) => sum + finalOf(e));

  /// IQD bills that have NO exchange rate — pure IQD total.
  int get totalIqdOnly => exhibitions
      .where(
        (e) =>
            e.currency == Currency.iqd &&
            (e.exchangeRate == null || e.exchangeRate == 0),
      )
      .fold(0, (sum, e) => sum + finalOf(e));

  /// USD equivalent total:
  ///   • USD bills: add their final directly (already in USD).
  ///   • IQD bills WITH exchange rate: add (final ÷ rate) → USD.
  double get totalUsd {
    double t = 0;
    for (final e in exhibitions) {
      if (e.currency == Currency.usd) {
        t += finalOf(e);
      } else if (e.currency == Currency.iqd &&
          (e.exchangeRate ?? 0) > 0) {
        t += finalOf(e) / e.exchangeRate!;
      }
    }
    return t;
  }

  /// For a given IQD exhibition with exchange rate: its final ÷ rate (→ USD).
  /// Returns null if the exhibition is not IQD-with-rate.
  double? iqdAsUsd(Exhibition e) {
    if (e.currency != Currency.iqd) return null;
    if ((e.exchangeRate ?? 0) <= 0) return null;
    return finalOf(e) / e.exchangeRate!;
  }
}
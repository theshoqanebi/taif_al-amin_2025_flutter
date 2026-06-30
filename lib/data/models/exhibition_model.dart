import 'package:taif_alamin/data/constants/currency.dart';
import 'package:taif_alamin/data/models/exhibition_additional_amount_model.dart';
import 'package:taif_alamin/data/models/exhibition_multi_sell_model.dart';
import 'package:taif_alamin/data/repositories/exhibitions_additional_amount_repository.dart';
import 'package:taif_alamin/data/repositories/exhibitions_multi_sells_repository.dart';

/// An exhibition invoice (header).
///
/// Schema (Exhibitions): id, bill, date, discount, discount_details,
/// notes, currency, exchange_rate, belongTo. Children (multiSells /
/// additionalAmount) are linked by [bill] and fetched lazily via
/// [getMultiSells] / [getAdditionalAmounts].
class Exhibition {
  final int id;
  final String bill;
  final DateTime date;
  final int discount;
  final String? discountDetails;
  final String? notes;
  final Currency currency;

  /// Exchange rate (دينار لكل دولار) for this bill — works in both
  /// directions: for a USD bill it converts the total to its IQD
  /// equivalent (× rate); for an IQD bill it converts the total to its USD
  /// equivalent (÷ rate). Optional either way; only enforced as required
  /// when [currency] is USD.
  final double? exchangeRate;
  final String? belongTo;

  Exhibition({
    required this.id,
    required this.bill,
    required this.date,
    this.discount = 0,
    this.discountDetails,
    this.notes,
    this.currency = Currency.iqd,
    this.exchangeRate,
    this.belongTo,
  });

  // ---- child loaders (as requested) ----

  final ExhibitionsMultiSellsRepository _multiRepo =
      ExhibitionsMultiSellsRepository();
  final ExhibitionsAdditionalAmountRepository _additionalRepo =
      ExhibitionsAdditionalAmountRepository();

  /// Fetch this exhibition's furniture line-items.
  Future<List<ExhibitionMultiSell>> getMultiSells() =>
      _multiRepo.getByBill(bill, belongTo ?? '');

  /// Fetch this exhibition's extra charges.
  Future<List<ExhibitionAdditionalAmount>> getAdditionalAmounts() =>
      _additionalRepo.getByBill(bill, belongTo ?? '');

  /// Convenience: total of all children (multiSells + additionalAmount).
  Future<int> computeTotal() async {
    final multi = await getMultiSells();
    final extras = await getAdditionalAmounts();
    final multiTotal = multi.fold<int>(0, (s, m) => s + m.totalPrice);
    final extrasTotal = extras.fold<int>(0, (s, a) => s + a.totalPrice);
    return multiTotal + extrasTotal;
  }

  Exhibition copyWith({
    int? id,
    String? bill,
    DateTime? date,
    int? discount,
    String? discountDetails,
    String? notes,
    Currency? currency,
    double? exchangeRate,
    String? belongTo,
    bool clearExchangeRate = false,
  }) => Exhibition(
    id: id ?? this.id,
    bill: bill ?? this.bill,
    date: date ?? this.date,
    discount: discount ?? this.discount,
    discountDetails: discountDetails ?? this.discountDetails,
    notes: notes ?? this.notes,
    currency: currency ?? this.currency,
    exchangeRate: clearExchangeRate ? null : (exchangeRate ?? this.exchangeRate),
    belongTo: belongTo ?? this.belongTo,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'bill': bill,
    'date': date.millisecondsSinceEpoch,
    'discount': discount,
    'discount_details': discountDetails,
    'notes': notes,
    'currency': currency.name.toUpperCase(),
    'exchange_rate': exchangeRate,
    'belongTo': belongTo,
  };

  factory Exhibition.fromMap(Map<String, dynamic> map) => Exhibition(
    id: _toInt(map['id']),
    bill: (map['bill']?.toString()) ?? '',
    date: _toDate(map['date']),
    discount: _toInt(map['discount']),
    discountDetails: map['discount_details']?.toString(),
    notes: map['notes']?.toString(),
    currency: Currency.fromString(map['currency']?.toString() ?? 'IQD'),
    exchangeRate: _toDoubleOrNull(map['exchange_rate']),
    belongTo: map['belongTo']?.toString(),
  );

  static int _toInt(Object? v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim()) ?? 0;
  }

  static double? _toDoubleOrNull(Object? v) {
    if (v == null) return null;
    if (v is double) return v == 0 ? null : v;
    if (v is num) return v.toDouble() == 0 ? null : v.toDouble();
    final s = v.toString().replaceAll(',', '').trim();
    if (s.isEmpty) return null;
    final d = double.tryParse(s);
    return (d == null || d == 0) ? null : d;
  }

  static DateTime _toDate(Object? v) {
    if (v == null) return DateTime.now();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    final s = v.toString().trim();
    final ms = int.tryParse(s);
    if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    return DateTime.tryParse(s) ?? DateTime.now();
  }

  @override
  String toString() =>
      'Exhibition(id: $id, bill: $bill, belongTo: $belongTo)';
}
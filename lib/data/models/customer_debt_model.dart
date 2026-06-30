import 'package:taif_alamin/data/constants/currency.dart';

/// A customer debt — the financial side of a sale (or a manual debt).
///
/// Schema (CustomersDebts):
///   id, debtor_name, debt_date TEXT(ISO), bill_number TEXT,
///   total_price INTEGER, discount INTEGER, currency TEXT, notes TEXT,
///   uuid TEXT UNIQUE
///
/// Linked to a sale by [uuid] (== Sells.payment_uuid). Payments live in
/// CustomersPayments (by debt_id); paid/remaining are computed from them.
class CustomerDebt {
  final int id;
  final String debtorName;
  final DateTime debtDate;
  final String? bill;
  final int totalPrice;
  final int discount;
  final Currency currency;
  final String? notes;
  final String? uuid;

  CustomerDebt({
    required this.id,
    required this.debtorName,
    required this.debtDate,
    this.bill,
    required this.totalPrice,
    this.discount = 0,
    this.currency = Currency.iqd,
    this.notes,
    this.uuid,
  });

  /// Total after discount.
  int get finalPrice => (totalPrice - discount).clamp(0, totalPrice);

  CustomerDebt copyWith({
    int? id,
    String? debtorName,
    DateTime? debtDate,
    String? bill,
    int? totalPrice,
    int? discount,
    Currency? currency,
    String? notes,
    String? uuid,
  }) => CustomerDebt(
    id: id ?? this.id,
    debtorName: debtorName ?? this.debtorName,
    debtDate: debtDate ?? this.debtDate,
    bill: bill ?? this.bill,
    totalPrice: totalPrice ?? this.totalPrice,
    discount: discount ?? this.discount,
    currency: currency ?? this.currency,
    notes: notes ?? this.notes,
    uuid: uuid ?? this.uuid,
  );

  static String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() => {
    'id': id,
    'debtor_name': debtorName,
    'debt_date': _iso(debtDate),
    'bill_number': bill,
    'total_price': totalPrice,
    'discount': discount,
    'currency': currency.name.toUpperCase(),
    'notes': notes,
    'uuid': uuid,
  };

  factory CustomerDebt.fromMap(Map<String, dynamic> map) => CustomerDebt(
    id: _toInt(map['id']),
    debtorName: (map['debtor_name'] as String?) ?? '',
    debtDate: _toDate(map['debt_date']),
    bill: map['bill_number']?.toString(),
    totalPrice: _toInt(map['total_price']),
    discount: _toInt(map['discount']),
    currency: Currency.fromString(map['currency']?.toString() ?? 'IQD'),
    notes: map['notes'] as String?,
    uuid: map['uuid'] as String?,
  );

  static int _toInt(Object? v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    final s = v.toString().replaceAll(',', '').trim();
    return int.tryParse(s) ?? double.tryParse(s)?.toInt() ?? 0;
  }

  static DateTime _toDate(Object? v) {
    if (v == null) return DateTime.now();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    final s = v.toString().trim();
    return DateTime.tryParse(s) ??
        (int.tryParse(s) != null
            ? DateTime.fromMillisecondsSinceEpoch(int.parse(s))
            : DateTime.now());
  }

  @override
  String toString() =>
      'CustomerDebt(id: $id, name: $debtorName, total: $totalPrice, uuid: $uuid)';
}

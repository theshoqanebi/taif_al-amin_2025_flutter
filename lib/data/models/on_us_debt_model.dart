import 'package:taif_alamin/data/constants/currency.dart';

/// A debt the business itself owes to someone else ("ديون علينا") —
/// completely independent from [CustomerDebt] (money customers owe the
/// business). No discount concept here, and no link to Sells/Exhibitions:
/// every row is created and edited directly on this screen.
///
/// Real schema (OnUsDebts), from the legacy Java:
///   id, name, date TEXT(ISO), bill TEXT, tPrice INTEGER, notes TEXT,
///   currency TEXT
class OnUsDebt {
  final int id;
  final String name;
  final DateTime date;
  final String? bill;
  final int tPrice;
  final String? notes;
  final Currency currency;

  OnUsDebt({
    required this.id,
    required this.name,
    required this.date,
    this.bill,
    required this.tPrice,
    this.notes,
    this.currency = Currency.iqd,
  });

  OnUsDebt copyWith({
    int? id,
    String? name,
    DateTime? date,
    String? bill,
    int? tPrice,
    String? notes,
    Currency? currency,
  }) => OnUsDebt(
    id: id ?? this.id,
    name: name ?? this.name,
    date: date ?? this.date,
    bill: bill ?? this.bill,
    tPrice: tPrice ?? this.tPrice,
    notes: notes ?? this.notes,
    currency: currency ?? this.currency,
  );

  static String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'date': _iso(date),
    'bill': bill,
    'tPrice': tPrice,
    'notes': notes,
    'currency': currency.name.toUpperCase(),
  };

  factory OnUsDebt.fromMap(Map<String, dynamic> map) => OnUsDebt(
    id: _toInt(map['id']),
    name: map['name']?.toString() ?? '',
    date: _toDate(map['date']),
    bill: map['bill']?.toString(),
    tPrice: _toInt(map['tPrice']),
    notes: map['notes']?.toString(),
    currency: Currency.fromString(map['currency']?.toString() ?? 'IQD'),
  );

  static int _toInt(Object? v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    final s = v.toString().replaceAll(',', '').trim();
    return int.tryParse(s) ?? double.tryParse(s)?.toInt() ?? 0;
  }

  /// Tolerant: ISO string ('yyyy-MM-dd' / full ISO) or millis (int/num/string).
  static DateTime _toDate(Object? v) {
    if (v == null) return DateTime.now();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    final s = v.toString().trim();
    final parsed = DateTime.tryParse(s);
    if (parsed != null) return parsed;
    final ms = int.tryParse(s);
    if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    return DateTime.now();
  }

  @override
  String toString() => 'OnUsDebt(id: $id, name: $name, tPrice: $tPrice)';
}

/// A payment row in the `exhibitions_payments` table.
///
/// Schema: id INTEGER PK AUTOINCREMENT, date TEXT, payment INTEGER, belongTo TEXT
///
/// `date` is modeled as a [DateTime]. It is read tolerantly (millis as int or
/// numeric string, or an ISO string) and written as millisecondsSinceEpoch to
/// stay consistent with the rest of the app's date storage.
class ExhibitionPayment {
  final int id;
  final DateTime date;
  final int payment;
  final String? belongTo;

  ExhibitionPayment({
    required this.id,
    required this.date,
    required this.payment,
    this.belongTo,
  });

  ExhibitionPayment copyWith({
    int? id,
    DateTime? date,
    int? payment,
    String? belongTo,
  }) => ExhibitionPayment(
    id: id ?? this.id,
    date: date ?? this.date,
    payment: payment ?? this.payment,
    belongTo: belongTo ?? this.belongTo,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.millisecondsSinceEpoch,
    'payment': payment,
    'belongTo': belongTo,
  };

  factory ExhibitionPayment.fromMap(Map<String, dynamic> map) =>
      ExhibitionPayment(
        id: _toInt(map['id']),
        date: _toDate(map['date']),
        payment: _toInt(map['payment']),
        belongTo: map['belongTo']?.toString(),
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
    final ms = int.tryParse(s);
    if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    return DateTime.tryParse(s) ?? DateTime.now();
  }

  @override
  String toString() =>
      'ExhibitionPayment(id: $id, payment: $payment, belongTo: $belongTo, date: $date)';
}
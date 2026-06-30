/// A single payment made against a [CustomerDebt].
///
/// Schema (CustomersPayments):
///   id, debt_id INTEGER(FK), payment_amount INTEGER, payment_date TEXT(ISO),
///   notes TEXT
class CustomerPayment {
  final int id;
  final int debtId;
  final int paymentAmount;
  final DateTime paymentDate;
  final String? notes;

  CustomerPayment({
    required this.id,
    required this.debtId,
    required this.paymentAmount,
    required this.paymentDate,
    this.notes,
  });

  CustomerPayment copyWith({
    int? id,
    int? debtId,
    int? paymentAmount,
    DateTime? paymentDate,
    String? notes,
  }) => CustomerPayment(
    id: id ?? this.id,
    debtId: debtId ?? this.debtId,
    paymentAmount: paymentAmount ?? this.paymentAmount,
    paymentDate: paymentDate ?? this.paymentDate,
    notes: notes ?? this.notes,
  );

  static String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() => {
    'id': id,
    'debt_id': debtId,
    'payment_amount': paymentAmount,
    'payment_date': _iso(paymentDate),
    'notes': notes,
  };

  factory CustomerPayment.fromMap(Map<String, dynamic> map) => CustomerPayment(
    id: _toInt(map['id']),
    debtId: _toInt(map['debt_id']),
    paymentAmount: _toInt(map['payment_amount']),
    paymentDate: _toDate(map['payment_date']),
    notes: map['notes'] as String?,
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
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    final s = v.toString().trim();
    return DateTime.tryParse(s) ??
        (int.tryParse(s) != null
            ? DateTime.fromMillisecondsSinceEpoch(int.parse(s))
            : DateTime.now());
  }

  @override
  String toString() =>
      'CustomerPayment(id: $id, debtId: $debtId, amount: $paymentAmount)';
}

import 'package:taif_alamin/data/constants/supply_type.dart';

class Supply {
  final int id;
  final String? bill;
  final DateTime date;
  final int tPrice; // Total price
  final int pPrice; // Paid price
  final String? notes;
  final String? belongTo;
  final SupplyType type;

  Supply({
    required this.id,
    this.bill,
    required this.date,
    required this.tPrice,
    required this.pPrice,
    this.notes,
    this.belongTo,
    required this.type,
  });

  /// Calculate remaining/unpaid amount
  int get remaining => tPrice - pPrice;

  /// Check if fully paid
  bool get isPaid => remaining == 0;

  Supply copyWith({
    int? id,
    String? bill,
    DateTime? date,
    int? tPrice,
    int? pPrice,
    String? notes,
    String? belongTo,
    SupplyType? type,
  }) => Supply(
    id: id ?? this.id,
    bill: bill ?? this.bill,
    date: date ?? this.date,
    tPrice: tPrice ?? this.tPrice,
    pPrice: pPrice ?? this.pPrice,
    notes: notes ?? this.notes,
    belongTo: belongTo ?? this.belongTo,
    type: type ?? this.type,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'bill': bill,
    'date': date.millisecondsSinceEpoch,
    'tPrice': tPrice,
    'pPrice': pPrice,
    'notes': notes,
    'belongTo': belongTo,
    'type': type.name,
  };

  factory Supply.fromMap(Map<String, dynamic> map) => Supply(
    id: map['id'] as int,
    bill: map['bill'] as String?,
    date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
    tPrice: map['tPrice'] as int,
    pPrice: map['pPrice'] as int,
    notes: map['notes'] as String?,
    belongTo: map['belongTo'] as String?,
    type: SupplyType.fromString(map['type'] as String),
  );

  @override
  String toString() =>
      'Supply(id: $id, type: ${type.name}, tPrice: $tPrice, remaining: $remaining)';
}

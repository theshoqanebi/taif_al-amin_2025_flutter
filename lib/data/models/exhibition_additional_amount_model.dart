/// An extra charge attached to an exhibition invoice.
///
/// Schema (ExhibitionsAdditionalAmount): id, bill, name, count REAL,
/// price INTEGER, belongTo. Linked to its exhibition by [bill].
class ExhibitionAdditionalAmount {
  final int id;
  final String? bill;
  final String? name;
  final double count;
  final int price;
  final String? belongTo;

  ExhibitionAdditionalAmount({
    required this.id,
    this.bill,
    this.name,
    required this.count,
    required this.price,
    this.belongTo,
  });

  /// Line total.
  int get totalPrice => (count * price).round();

  ExhibitionAdditionalAmount copyWith({
    int? id,
    String? bill,
    String? name,
    double? count,
    int? price,
    String? belongTo,
  }) => ExhibitionAdditionalAmount(
    id: id ?? this.id,
    bill: bill ?? this.bill,
    name: name ?? this.name,
    count: count ?? this.count,
    price: price ?? this.price,
    belongTo: belongTo ?? this.belongTo,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'bill': bill,
    'name': name,
    'count': count,
    'price': price,
    'belongTo': belongTo,
  };

  factory ExhibitionAdditionalAmount.fromMap(Map<String, dynamic> map) =>
      ExhibitionAdditionalAmount(
        id: _toInt(map['id']),
        bill: map['bill']?.toString(),
        name: map['name']?.toString(),
        count: _toDouble(map['count']),
        price: _toInt(map['price']),
        belongTo: map['belongTo']?.toString(),
      );

  static int _toInt(Object? v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    final s = v.toString().replaceAll(',', '').trim();
    return int.tryParse(s) ?? double.tryParse(s)?.toInt() ?? 0;
  }

  static double _toDouble(Object? v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll(',', '').trim();
    return double.tryParse(s) ?? 0;
  }

  @override
  String toString() =>
      'ExhibitionAdditionalAmount(id: $id, name: $name, total: $totalPrice)';
}

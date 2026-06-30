/// An extra charge attached to a sale.
///
/// Real schema (additionalAmount), from the legacy Java:
///   id, name, count REAL, price INTEGER, belongTo
/// Linked to its sale by [belongTo] (= the sale's bill).
class AdditionalAmount {
  final int id;
  final String? name;
  final double count;
  final int price;

  /// The sale's bill this charge belongs to.
  final String? belongTo;

  AdditionalAmount({
    required this.id,
    this.name,
    required this.count,
    required this.price,
    this.belongTo,
  });

  int get totalPrice => (count * price).round();

  AdditionalAmount copyWith({
    int? id,
    String? name,
    double? count,
    int? price,
    String? belongTo,
  }) => AdditionalAmount(
    id: id ?? this.id,
    name: name ?? this.name,
    count: count ?? this.count,
    price: price ?? this.price,
    belongTo: belongTo ?? this.belongTo,
  );

  /// Persisted columns only.
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'count': count,
    'price': price,
    'belongTo': belongTo,
  };

  factory AdditionalAmount.fromMap(Map<String, dynamic> map) =>
      AdditionalAmount(
        id: _toInt(map['id']),
        name: (map['name'] as String?) ?? (map['description'] as String?),
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
      'AdditionalAmount(id: $id, name: $name, total: $totalPrice)';
}
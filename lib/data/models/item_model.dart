/// A purchase line in the `Items` table.
///
/// Matches the legacy purchases schema:
///   id INTEGER PK AUTOINCREMENT, item_name TEXT, count REAL,
///   price INTEGER, date INTEGER (millis), belongTo TEXT
class Item {
  final int id;
  final String? itemName;
  final double count;
  final int price;
  final DateTime date;
  final String? belongTo;

  Item({
    required this.id,
    this.itemName,
    required this.count,
    required this.price,
    required this.date,
    this.belongTo,
  });

  /// Line value (quantity * unit price), rounded to an int.
  int get total => (count * price).round();

  Item copyWith({
    int? id,
    String? itemName,
    double? count,
    int? price,
    DateTime? date,
    String? belongTo,
  }) => Item(
    id: id ?? this.id,
    itemName: itemName ?? this.itemName,
    count: count ?? this.count,
    price: price ?? this.price,
    date: date ?? this.date,
    belongTo: belongTo ?? this.belongTo,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'item_name': itemName,
    'count': count,
    'price': price,
    'date': date.millisecondsSinceEpoch,
    'belongTo': belongTo,
  };

  factory Item.fromMap(Map<String, dynamic> map) => Item(
    id: _toInt(map['id']),
    itemName: map['item_name']?.toString(),
    count: _toDouble(map['count']),
    price: _toInt(map['price']),
    date: _toDate(map['date']),
    belongTo: map['belongTo']?.toString(),
  );

  /// Tolerant int parse — the live `Items` table may store numbers as TEXT.
  static int _toInt(Object? v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    final s = v.toString().replaceAll(',', '').trim();
    return int.tryParse(s) ?? double.tryParse(s)?.toInt() ?? 0;
  }

  /// Tolerant double parse — same reason as [_toInt].
  static double _toDouble(Object? v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll(',', '').trim();
    return double.tryParse(s) ?? 0;
  }

  /// Tolerant date parse: millis (int or numeric String) or an ISO String.
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
      'Item(id: $id, name: $itemName, count: $count, price: $price, total: $total)';
}
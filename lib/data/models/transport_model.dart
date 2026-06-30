class Transport {
  final int id;
  final int price;
  final DateTime date;
  final String? notes;

  Transport({
    required this.id,
    required this.price,
    required this.date,
    this.notes,
  });

  Transport copyWith({int? id, int? price, DateTime? date, String? notes}) =>
      Transport(
        id: id ?? this.id,
        price: price ?? this.price,
        date: date ?? this.date,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'price': price,
    'date': date.millisecondsSinceEpoch,
    'notes': notes,
  };

  factory Transport.fromMap(Map<String, dynamic> map) => Transport(
    id: map['id'] as int,
    price: map['price'] as int,
    date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
    notes: map['notes'] as String?,
  );

  @override
  String toString() =>
      'Transport(id: $id, price: $price, date: $date, notes: $notes)';
}

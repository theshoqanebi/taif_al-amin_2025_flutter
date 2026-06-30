/// A row in the `exhibitionsInfo` table (one exhibition / showroom).
///
/// Schema: id INTEGER PK AUTOINCREMENT, bill INTEGER, name TEXT,
/// phone TEXT, address TEXT, belongTo TEXT UNIQUE
class ExhibitionInfo {
  final int id;
  final int bill;
  final String? name;
  final String? phone;
  final String? address;
  final String? belongTo;

  ExhibitionInfo({
    required this.id,
    required this.bill,
    this.name,
    this.phone,
    this.address,
    this.belongTo,
  });

  /// A label for the button (falls back to belongTo / bill).
  String get label {
    if (name != null && name!.trim().isNotEmpty) return name!.trim();
    if (belongTo != null && belongTo!.trim().isNotEmpty) return belongTo!.trim();
    return 'معرض $bill';
  }

  ExhibitionInfo copyWith({
    int? id,
    int? bill,
    String? name,
    String? phone,
    String? address,
    String? belongTo,
  }) => ExhibitionInfo(
    id: id ?? this.id,
    bill: bill ?? this.bill,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    belongTo: belongTo ?? this.belongTo,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'bill': bill,
    'name': name,
    'phone': phone,
    'address': address,
    'belongTo': belongTo,
  };

  factory ExhibitionInfo.fromMap(Map<String, dynamic> map) => ExhibitionInfo(
    id: _toInt(map['id']),
    bill: _toInt(map['bill']),
    name: map['name']?.toString(),
    phone: map['phone']?.toString(),
    address: map['address']?.toString(),
    belongTo: map['belongTo']?.toString(),
  );

  static int _toInt(Object? v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim()) ?? 0;
  }

  @override
  String toString() =>
      'ExhibitionInfo(id: $id, name: $name, belongTo: $belongTo)';
}
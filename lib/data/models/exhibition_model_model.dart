/// Exhibition furniture design / price book.
///
/// Schema (ExhibitionsModels): id, name, uuid, ten_chairs, eight_chairs,
/// seven_chairs, three, two, chair, diwan, belongTo, hidden.
/// Mirrors [SellsModel] but is scoped to an exhibition via [belongTo].
class ExhibitionsModel {
  final int id;
  final String name;
  final String uuid;
  final int tenChairs;
  final int eightChairs;
  final int sevenChairs;
  final int three;
  final int two;
  final int chair;
  final int diwan;
  final String? belongTo;
  final int hidden;

  ExhibitionsModel({
    required this.id,
    required this.name,
    required this.uuid,
    required this.tenChairs,
    required this.eightChairs,
    required this.sevenChairs,
    required this.three,
    required this.two,
    required this.chair,
    required this.diwan,
    this.belongTo,
    this.hidden = 0,
  });

  ExhibitionsModel copyWith({
    int? id,
    String? name,
    String? uuid,
    int? tenChairs,
    int? eightChairs,
    int? sevenChairs,
    int? three,
    int? two,
    int? chair,
    int? diwan,
    String? belongTo,
    int? hidden,
  }) => ExhibitionsModel(
    id: id ?? this.id,
    name: name ?? this.name,
    uuid: uuid ?? this.uuid,
    tenChairs: tenChairs ?? this.tenChairs,
    eightChairs: eightChairs ?? this.eightChairs,
    sevenChairs: sevenChairs ?? this.sevenChairs,
    three: three ?? this.three,
    two: two ?? this.two,
    chair: chair ?? this.chair,
    diwan: diwan ?? this.diwan,
    belongTo: belongTo ?? this.belongTo,
    hidden: hidden ?? this.hidden,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'uuid': uuid,
    'ten_chairs': tenChairs,
    'eight_chairs': eightChairs,
    'seven_chairs': sevenChairs,
    'three': three,
    'two': two,
    'chair': chair,
    'diwan': diwan,
    'belongTo': belongTo,
    'hidden': hidden,
  };

  factory ExhibitionsModel.fromMap(Map<String, dynamic> map) =>
      ExhibitionsModel(
        id: _toInt(map['id']),
        name: (map['name'] as String?) ?? '',
        uuid: (map['uuid'] as String?) ?? '',
        tenChairs: _toInt(map['ten_chairs']),
        eightChairs: _toInt(map['eight_chairs']),
        sevenChairs: _toInt(map['seven_chairs']),
        three: _toInt(map['three']),
        two: _toInt(map['two']),
        chair: _toInt(map['chair']),
        diwan: _toInt(map['diwan']),
        belongTo: map['belongTo']?.toString(),
        hidden: _toInt(map['hidden']),
      );

  static int _toInt(Object? v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim()) ?? 0;
  }

  @override
  String toString() =>
      'ExhibitionsModel(id: $id, name: $name, belongTo: $belongTo)';
}
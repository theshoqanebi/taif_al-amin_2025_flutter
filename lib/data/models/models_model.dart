/// Sells model (furniture design)
class SellsModel {
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
  final int hidden;

  SellsModel({
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
    this.hidden = 0,
  });

  SellsModel copyWith({
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
    int? hidden,
  }) =>
      SellsModel(
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
        'hidden': hidden,
      };

  factory SellsModel.fromMap(Map<String, dynamic> map) => SellsModel(
        id: map['id'] as int,
        name: map['name'] as String,
        uuid: map['uuid'] as String,
        tenChairs: map['ten_chairs'] as int,
        eightChairs: map['eight_chairs'] as int,
        sevenChairs: map['seven_chairs'] as int,
        three: map['three'] as int,
        two: map['two'] as int,
        chair: map['chair'] as int,
        diwan: map['diwan'] as int,
        hidden: map['hidden'] as int? ?? 0,
      );

  @override
  String toString() => 'SellsModel(id: $id, name: $name, uuid: $uuid)';
}

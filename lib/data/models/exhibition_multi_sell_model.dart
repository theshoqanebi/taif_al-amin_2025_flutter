import 'package:taif_alamin/data/models/exhibitions_model_model.dart';
import 'package:taif_alamin/data/models/multi_sells_model.dart' show SellType;

/// Price calculation for an exhibition line, on the [SellType] enum.
/// Mirrors the legacy Java `MultiSell.getTotalPrice()`:
///   سيت (set) -> (seven/eight/ten chairs price, by [count]) * [setNumber]
///   ثنائية    -> model.two   * count
///   ثلاثية    -> model.three * count
///   كرسي      -> model.chair * count
///   ديوان     -> model.diwan * count
extension ExhibitionPricing on SellType {
  int priceFor(ExhibitionsModel model, int setNumber, double count) {
    switch (this) {
      case SellType.set:
        switch (count.round()) {
          case 7:
            return model.sevenChairs * setNumber;
          case 8:
            return model.eightChairs * setNumber;
          case 10:
            return model.tenChairs * setNumber;
          default:
            return 0;
        }
      case SellType.double: // ثنائية
        return (model.two * count).round();
      case SellType.triple: // ثلاثية
        return (model.three * count).round();
      case SellType.chair:
        return (model.chair * count).round();
      case SellType.diwan:
        return (model.diwan * count).round();
    }
  }
}

/// A furniture line-item of an exhibition invoice.
///
/// Real schema (ExhibitionsMultiSells), per the legacy Java insert:
///   id, bill, model_id, type, set_number, count, color, belongTo
/// There is NO stored price and NO model_name. [totalPrice] is computed from
/// the linked [ExhibitionsModel] (resolved by JOIN on read, or from the form
/// on create). `count` is REAL (float).
class ExhibitionMultiSell {
  final int id;
  final String bill;
  final int modelId;

  /// Display only — from the JOIN with ExhibitionsModels (not persisted).
  final String modelName;
  final SellType type;
  final int setNumber;

  /// REAL. For a "set" this is chairs-per-set (7/8/10); else the quantity.
  final double count;
  final String? color;
  final String? belongTo;

  /// Resolved model for pricing (JOIN on read / picked model on create).
  final ExhibitionsModel? model;

  ExhibitionMultiSell({
    required this.id,
    required this.bill,
    required this.modelId,
    this.modelName = '',
    required this.type,
    this.setNumber = 0,
    required this.count,
    this.color,
    this.belongTo,
    this.model,
  });

  int get totalPrice =>
      model == null ? 0 : type.priceFor(model!, setNumber, count);

  factory ExhibitionMultiSell.fromForm({
    required int id,
    required String bill,
    required ExhibitionsModel model,
    required SellType type,
    int setNumber = 0,
    required double count,
    String? color,
    String? belongTo,
  }) => ExhibitionMultiSell(
    id: id,
    bill: bill,
    modelId: model.id,
    modelName: model.name,
    type: type,
    setNumber: setNumber,
    count: count,
    color: color,
    belongTo: belongTo ?? model.belongTo,
    model: model,
  );

  ExhibitionMultiSell copyWith({
    int? id,
    String? bill,
    int? modelId,
    String? modelName,
    SellType? type,
    int? setNumber,
    double? count,
    String? color,
    String? belongTo,
    ExhibitionsModel? model,
  }) => ExhibitionMultiSell(
    id: id ?? this.id,
    bill: bill ?? this.bill,
    modelId: modelId ?? this.modelId,
    modelName: modelName ?? this.modelName,
    type: type ?? this.type,
    setNumber: setNumber ?? this.setNumber,
    count: count ?? this.count,
    color: color ?? this.color,
    belongTo: belongTo ?? this.belongTo,
    model: model ?? this.model,
  );

  /// Persisted columns only (no price, no model_name).
  Map<String, dynamic> toMap() => {
    'id': id,
    'bill': bill,
    'model_id': modelId,
    'type': type.label,
    'set_number': setNumber,
    'count': count,
    'color': color,
    'belongTo': belongTo,
  };

  /// Expects the row + JOINed model columns (ten_chairs ... name).
  factory ExhibitionMultiSell.fromMap(Map<String, dynamic> map) {
    ExhibitionsModel? model;
    if (map.containsKey('ten_chairs') || map.containsKey('chair')) {
      model = ExhibitionsModel(
        id: _toInt(map['model_id']),
        name: (map['model_name'] as String?) ?? (map['name'] as String?) ?? '',
        uuid: (map['uuid'] as String?) ?? '',
        tenChairs: _toInt(map['ten_chairs']),
        eightChairs: _toInt(map['eight_chairs']),
        sevenChairs: _toInt(map['seven_chairs']),
        three: _toInt(map['three']),
        two: _toInt(map['two']),
        chair: _toInt(map['chair']),
        diwan: _toInt(map['diwan']),
        belongTo: map['belongTo']?.toString(),
      );
    }
    return ExhibitionMultiSell(
      id: _toInt(map['id']),
      bill: map['bill']?.toString() ?? '',
      modelId: _toInt(map['model_id']),
      modelName:
          (map['model_name'] as String?) ?? (map['name'] as String?) ?? '',
      type: SellType.fromLabel(map['type']?.toString() ?? 'سيت'),
      setNumber: _toInt(map['set_number']),
      count: _toDouble(map['count']),
      color: map['color'] as String?,
      belongTo: map['belongTo']?.toString(),
      model: model,
    );
  }

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
      'ExhibitionMultiSell(id: $id, model: $modelName, type: ${type.label}, total: $totalPrice)';
}
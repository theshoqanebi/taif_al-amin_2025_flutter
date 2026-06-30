import 'package:taif_alamin/data/database/database_service.dart';
import 'package:taif_alamin/data/models/exhibition_multi_sell_model.dart';

/// Real schema (ExhibitionsMultiSells), from the legacy Java insert:
///   id, bill, model_id, type, set_number, count, color, belongTo
/// No price column — reads JOIN ExhibitionsModels so the line price can be
/// computed from the model (same as the Java MultiSell.getTotalPrice()).
class ExhibitionsMultiSellsRepository {
  static const _table = 'exhibitions_multisells';

  // persisted columns (no price, no model_name)
  static const _cols = 'bill, model_id, type, set_number, count, color, belongTo';

  /// SELECT that brings each row + its model's pricing columns.
  static const _selectWithModel = '''
    SELECT ms.*,
           m.name         AS model_name,
           m.uuid         AS uuid,
           m.ten_chairs   AS ten_chairs,
           m.eight_chairs AS eight_chairs,
           m.seven_chairs AS seven_chairs,
           m.three        AS three,
           m.two          AS two,
           m.chair        AS chair,
           m.diwan        AS diwan
    FROM $_table ms
    LEFT JOIN ExhibitionsModels m ON m.id = ms.model_id
  ''';

  List<Object?> _args(ExhibitionMultiSell m) => [
    m.bill,
    m.modelId,
    m.type.label,
    m.setNumber,
    m.count,
    m.color,
    m.belongTo,
  ];

  /// Scope by bill AND belongTo — bill is not unique across showrooms.
  Future<List<ExhibitionMultiSell>> getByBill(
    String bill,
    String belongTo,
  ) async {
    final results = await DatabaseService.query(
      '$_selectWithModel WHERE ms.bill = ? AND ms.belongTo = ?',
      [bill, belongTo],
    );
    return results.map(ExhibitionMultiSell.fromMap).toList();
  }

  Future<List<ExhibitionMultiSell>> getByBelongTo(String belongTo) async {
    final results = await DatabaseService.query(
      '$_selectWithModel WHERE ms.belongTo = ?',
      [belongTo],
    );
    return results.map(ExhibitionMultiSell.fromMap).toList();
  }

  Future<int> insert(ExhibitionMultiSell m) async {
    return DatabaseService.execute(
      'INSERT INTO $_table ($_cols) VALUES (?, ?, ?, ?, ?, ?, ?)',
      _args(m),
    );
  }

  Future<void> insertBatch(List<ExhibitionMultiSell> items) async {
    if (items.isEmpty) return;
    const sql = 'INSERT INTO $_table ($_cols) VALUES (?, ?, ?, ?, ?, ?, ?)';
    await DatabaseService.insertBatch(sql, items.map(_args).toList());
  }

  Future<int> update(ExhibitionMultiSell m) async {
    return DatabaseService.execute(
      '''
      UPDATE $_table
      SET bill = ?, model_id = ?, type = ?, set_number = ?, count = ?,
          color = ?, belongTo = ?
      WHERE id = ?
      ''',
      [..._args(m), m.id],
    );
  }

  Future<int> deleteById(int id) async {
    return DatabaseService.execute('DELETE FROM $_table WHERE id = ?', [id]);
  }

  Future<int> deleteByBill(String bill, String belongTo) async {
    return DatabaseService.execute(
      'DELETE FROM $_table WHERE bill = ? AND belongTo = ?',
      [bill, belongTo],
    );
  }
}
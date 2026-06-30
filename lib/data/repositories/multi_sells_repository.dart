import 'package:taif_alamin/data/database/database_service.dart';
import 'package:taif_alamin/data/models/multi_sells_model.dart';

/// Real schema (multiSells), from the legacy Java:
///   id, bill, model_id, type, set_number, count REAL, color
/// No price column — reads JOIN sellsModels so the price is computed from the
/// model. Linked by [bill].
class MultiSellsRepository {
  static const _table = 'multiSells';

  static const _cols = 'bill, model_id, type, set_number, count, color';

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
    LEFT JOIN sellsModels m ON m.id = ms.model_id
  ''';

  List<Object?> _args(MultiSell s) => [
    s.bill,
    s.modelId,
    s.type.label,
    s.setNumber,
    s.count,
    s.color,
  ];

  Future<int> insert(MultiSell sell) async {
    return DatabaseService.execute(
      'INSERT INTO $_table ($_cols) VALUES (?, ?, ?, ?, ?, ?)',
      _args(sell),
    );
  }

  Future<void> insertBatch(List<MultiSell> sells) async {
    if (sells.isEmpty) return;
    const sql = 'INSERT INTO $_table ($_cols) VALUES (?, ?, ?, ?, ?, ?)';
    await DatabaseService.insertBatch(sql, sells.map(_args).toList());
  }

  Future<int> update(MultiSell sell) async {
    return DatabaseService.execute(
      '''
      UPDATE $_table
      SET bill = ?, model_id = ?, type = ?, set_number = ?, count = ?, color = ?
      WHERE id = ?
      ''',
      [..._args(sell), sell.id],
    );
  }

  /// All line items (with model JOIN) — for aggregate totals by bill.
  Future<List<MultiSell>> getAll() async {
    final results = await DatabaseService.query(_selectWithModel);
    return results.map(MultiSell.fromMap).toList();
  }

  Future<List<MultiSell>> getByBill(String bill) async {
    final results = await DatabaseService.query(
      '$_selectWithModel WHERE ms.bill = ?',
      [bill],
    );
    return results.map(MultiSell.fromMap).toList();
  }

  Future<int> deleteById(int id) async {
    return DatabaseService.execute('DELETE FROM $_table WHERE id = ?', [id]);
  }

  Future<int> deleteByBill(String bill) async {
    return DatabaseService.execute('DELETE FROM $_table WHERE bill = ?', [bill]);
  }
}

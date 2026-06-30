import 'package:taif_alamin/data/database/database_service.dart';
import 'package:taif_alamin/data/models/additional_amount_model.dart';

/// Real schema (additionalAmount): id, name, count REAL, price INTEGER, belongTo
/// Linked by [belongTo] (= the sale's bill).
class AdditionalAmountsRepository {
  static const _table = 'additionalAmount';
  static const _cols = 'name, count, price, belongTo';

  List<Object?> _args(AdditionalAmount a) => [a.name, a.count, a.price, a.belongTo];

  Future<int> insert(AdditionalAmount amount) async {
    return DatabaseService.execute(
      'INSERT INTO $_table ($_cols) VALUES (?, ?, ?, ?)',
      _args(amount),
    );
  }

  Future<void> insertBatch(List<AdditionalAmount> amounts) async {
    if (amounts.isEmpty) return;
    const sql = 'INSERT INTO $_table ($_cols) VALUES (?, ?, ?, ?)';
    await DatabaseService.insertBatch(sql, amounts.map(_args).toList());
  }

  Future<int> update(AdditionalAmount amount) async {
    return DatabaseService.execute(
      'UPDATE $_table SET name = ?, count = ?, price = ?, belongTo = ? WHERE id = ?',
      [..._args(amount), amount.id],
    );
  }

  /// All extras — for aggregate totals by bill (belongTo).
  Future<List<AdditionalAmount>> getAll() async {
    final results = await DatabaseService.query('SELECT * FROM $_table');
    return results.map(AdditionalAmount.fromMap).toList();
  }

  Future<List<AdditionalAmount>> getByBill(String bill) async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table WHERE belongTo = ?',
      [bill],
    );
    return results.map(AdditionalAmount.fromMap).toList();
  }

  Future<int> deleteById(int id) async {
    return DatabaseService.execute('DELETE FROM $_table WHERE id = ?', [id]);
  }

  Future<int> deleteByBill(String bill) async {
    return DatabaseService.execute(
      'DELETE FROM $_table WHERE belongTo = ?',
      [bill],
    );
  }
}

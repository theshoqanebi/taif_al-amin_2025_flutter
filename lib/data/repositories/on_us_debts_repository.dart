import 'package:taif_alamin/data/database/database_service.dart';
import 'package:taif_alamin/data/models/on_us_debt_model.dart';

/// Real schema (OnUsDebts): id, name, date TEXT, bill TEXT, tPrice INTEGER,
/// notes TEXT, currency TEXT
class OnUsDebtsRepository {
  static const _table = 'OnUsDebts';

  Future<List<OnUsDebt>> getAll() async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table ORDER BY id DESC',
    );
    return results.map(OnUsDebt.fromMap).toList();
  }

  Future<OnUsDebt?> getById(int id) async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table WHERE id = ?',
      [id],
    );
    return results.isEmpty ? null : OnUsDebt.fromMap(results.first);
  }

  /// Insert and return the new row id.
  Future<int> insert(OnUsDebt debt) async {
    final db = await DatabaseService.db;
    return db.insert(_table, debt.toMap()..remove('id'));
  }

  Future<int> update(OnUsDebt debt) async {
    return DatabaseService.execute(
      '''
      UPDATE $_table
      SET name = ?, date = ?, bill = ?, tPrice = ?, notes = ?, currency = ?
      WHERE id = ?
      ''',
      [
        debt.name,
        debt.toMap()['date'],
        debt.bill,
        debt.tPrice,
        debt.notes,
        debt.currency.name.toUpperCase(),
        debt.id,
      ],
    );
  }

  Future<int> deleteById(int id) async {
    return DatabaseService.execute('DELETE FROM $_table WHERE id = ?', [id]);
  }
}

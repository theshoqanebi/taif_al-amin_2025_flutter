import 'package:taif_alamin/data/database/database_service.dart';
import 'package:taif_alamin/data/models/customer_debt_model.dart';

/// Real schema (CustomersDebts):
///   id, debtor_name, debt_date TEXT, bill_number TEXT, total_price INTEGER,
///   discount INTEGER, currency TEXT, notes TEXT, uuid TEXT UNIQUE
class CustomersDebtsRepository {
  static const _table = 'CustomersDebts';
  // static const _cols =
  //     'debtor_name, debt_date, bill_number, total_price, discount, currency, notes, uuid';

  // List<Object?> _args(CustomerDebt d) {
  //   final m = d.toMap();
  //   return [
  //     m['debtor_name'],
  //     m['debt_date'],
  //     m['bill_number'],
  //     m['total_price'],
  //     m['discount'],
  //     m['currency'],
  //     m['notes'],
  //     m['uuid'],
  //   ];
  // }

  Future<List<CustomerDebt>> getAll() async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table ORDER BY id DESC',
    );
    return results.map(CustomerDebt.fromMap).toList();
  }

  Future<CustomerDebt?> getByUuid(String uuid) async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table WHERE uuid = ?',
      [uuid],
    );
    return results.isEmpty ? null : CustomerDebt.fromMap(results.first);
  }

  Future<CustomerDebt?> getById(int id) async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table WHERE id = ?',
      [id],
    );
    return results.isEmpty ? null : CustomerDebt.fromMap(results.first);
  }

  /// Insert and return the new row id.
  Future<int> insert(CustomerDebt debt) async {
    final db = await DatabaseService.db;
    return db.insert(_table, debt.toMap()..remove('id'));
  }

  Future<int> updateByUuid(CustomerDebt debt) async {
    return DatabaseService.execute(
      '''
      UPDATE $_table
      SET debtor_name = ?, debt_date = ?, bill_number = ?, total_price = ?,
          discount = ?, currency = ?, notes = ?
      WHERE uuid = ?
      ''',
      [
        debt.debtorName,
        debt.toMap()['debt_date'],
        debt.bill,
        debt.totalPrice,
        debt.discount,
        debt.currency.name.toUpperCase(),
        debt.notes,
        debt.uuid,
      ],
    );
  }

  Future<int> deleteByUuid(String uuid) async {
    return DatabaseService.execute('DELETE FROM $_table WHERE uuid = ?', [uuid]);
  }

  Future<int> deleteById(int id) async {
    return DatabaseService.execute('DELETE FROM $_table WHERE id = ?', [id]);
  }
}

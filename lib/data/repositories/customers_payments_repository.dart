import 'package:taif_alamin/data/database/database_service.dart';
import 'package:taif_alamin/data/models/customer_payment_model.dart';

/// Real schema (CustomersPayments):
///   id, debt_id INTEGER, payment_amount INTEGER, payment_date TEXT, notes TEXT
class CustomersPaymentsRepository {
  static const _table = 'CustomersPayments';

  Future<List<CustomerPayment>> getByDebtId(int debtId) async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table WHERE debt_id = ? ORDER BY payment_date ASC, id ASC',
      [debtId],
    );
    return results.map(CustomerPayment.fromMap).toList();
  }

  Future<int> getTotalByDebtId(int debtId) async {
    final results = await DatabaseService.query(
      'SELECT SUM(payment_amount) AS total FROM $_table WHERE debt_id = ?',
      [debtId],
    );
    if (results.isEmpty) return 0;
    return _toInt(results.first['total']);
  }

  /// Total paid grouped by debt_id (single query for the whole list).
  Future<Map<int, int>> totalsByDebt() async {
    final results = await DatabaseService.query(
      'SELECT debt_id, SUM(payment_amount) AS total FROM $_table GROUP BY debt_id',
    );
    final map = <int, int>{};
    for (final r in results) {
      final id = _toInt(r['debt_id']);
      final t = _toInt(r['total']);
      if (id != 0) map[id] = t;
    }
    return map;
  }

  Future<CustomerPayment?> getFirstPayment(int debtId) async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table WHERE debt_id = ? ORDER BY payment_date ASC, id ASC LIMIT 1',
      [debtId],
    );
    return results.isEmpty ? null : CustomerPayment.fromMap(results.first);
  }

  Future<int> insert(CustomerPayment payment) async {
    return DatabaseService.execute(
      'INSERT INTO $_table (debt_id, payment_amount, payment_date, notes) VALUES (?, ?, ?, ?)',
      [
        payment.debtId,
        payment.paymentAmount,
        payment.toMap()['payment_date'],
        payment.notes,
      ],
    );
  }

  Future<int> update(CustomerPayment payment) async {
    return DatabaseService.execute(
      'UPDATE $_table SET payment_amount = ?, payment_date = ?, notes = ? WHERE id = ?',
      [
        payment.paymentAmount,
        payment.toMap()['payment_date'],
        payment.notes,
        payment.id,
      ],
    );
  }

  Future<int> deleteById(int id) async {
    return DatabaseService.execute('DELETE FROM $_table WHERE id = ?', [id]);
  }

  Future<int> deleteByDebtId(int debtId) async {
    return DatabaseService.execute(
      'DELETE FROM $_table WHERE debt_id = ?',
      [debtId],
    );
  }

  static int _toInt(Object? v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    final s = v.toString().replaceAll(',', '').trim();
    return int.tryParse(s) ?? double.tryParse(s)?.toInt() ?? 0;
  }
}
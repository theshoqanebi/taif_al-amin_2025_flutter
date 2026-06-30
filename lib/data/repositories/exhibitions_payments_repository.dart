import 'package:taif_alamin/data/database/database_service.dart';
import 'package:taif_alamin/data/models/exhibition_payment_model.dart';

class ExhibitionsPaymentsRepository {
  static const _table = 'exhibitions_payments';

  /// Insert a payment (id is AUTOINCREMENT, so it's omitted).
  Future<int> insert(ExhibitionPayment p) async {
    return DatabaseService.execute(
      '''
      INSERT INTO $_table (date, payment, belongTo)
      VALUES (?, ?, ?)
      ''',
      [p.date.millisecondsSinceEpoch, p.payment, p.belongTo],
    );
  }

  /// Insert batch
  Future<void> insertBatch(List<ExhibitionPayment> payments) async {
    const sql =
        '''
      INSERT INTO $_table (date, payment, belongTo)
      VALUES (?, ?, ?)
    ''';
    final args = payments
        .map((p) => [p.date.millisecondsSinceEpoch, p.payment, p.belongTo])
        .toList();
    await DatabaseService.insertBatch(sql, args);
  }

  /// Update a payment
  Future<int> update(ExhibitionPayment p) async {
    return DatabaseService.execute(
      '''
      UPDATE $_table
      SET date = ?, payment = ?, belongTo = ?
      WHERE id = ?
      ''',
      [p.date.millisecondsSinceEpoch, p.payment, p.belongTo, p.id],
    );
  }

  /// Get all payments (newest first)
  Future<List<ExhibitionPayment>> getAll() async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table ORDER BY date DESC, id DESC',
    );
    return results.map(ExhibitionPayment.fromMap).toList();
  }

  /// Get payments for a specific exhibition (belongTo)
  Future<List<ExhibitionPayment>> getByBelongTo(String belongTo) async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table WHERE belongTo = ? ORDER BY date DESC, id DESC',
      [belongTo],
    );
    return results.map(ExhibitionPayment.fromMap).toList();
  }

  /// Total of all payments
  Future<int> getTotal() async {
    final results = await DatabaseService.query(
      'SELECT SUM(payment) AS total FROM $_table',
    );
    if (results.isEmpty || results.first['total'] == null) return 0;
    final total = results.first['total'];
    return total is int ? total : (total as num).toInt();
  }

  /// Total of payments for a specific exhibition
  Future<int> getTotalByBelongTo(String belongTo) async {
    final results = await DatabaseService.query(
      'SELECT SUM(payment) AS total FROM $_table WHERE belongTo = ?',
      [belongTo],
    );
    if (results.isEmpty || results.first['total'] == null) return 0;
    final total = results.first['total'];
    return total is int ? total : (total as num).toInt();
  }

  /// Delete by ID
  Future<int> deleteById(int id) async {
    return DatabaseService.execute('DELETE FROM $_table WHERE id = ?', [id]);
  }

  /// Delete all payments of an exhibition
  Future<int> deleteByBelongTo(String belongTo) async {
    return DatabaseService.execute('DELETE FROM $_table WHERE belongTo = ?', [
      belongTo,
    ]);
  }
}
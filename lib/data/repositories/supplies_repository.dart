import 'package:taif_alamin/data/constants/supply_type.dart';
import 'package:taif_alamin/data/database/database_service.dart';
import 'package:taif_alamin/data/models/supply_model.dart';

class SuppliesRepository {
  static const _table = 'Supplies';

  /// Insert a single supply
  Future<int> insert(Supply supply) async {
    return DatabaseService.execute(
      '''
      INSERT INTO $_table 
      (bill, date, tPrice, pPrice, notes, belongTo, type)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        supply.bill,
        supply.date.millisecondsSinceEpoch,
        supply.tPrice,
        supply.pPrice,
        supply.notes,
        supply.belongTo,
        supply.type.name,
      ],
    );
  }

  /// Insert batch
  Future<void> insertBatch(List<Supply> supplies) async {
    const sql =
        '''
      INSERT INTO $_table 
      (bill, date, tPrice, pPrice, notes, belongTo, type)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    ''';

    final args = supplies
        .map(
          (s) => [
            s.bill,
            s.date.millisecondsSinceEpoch,
            s.tPrice,
            s.pPrice,
            s.notes,
            s.belongTo,
            s.type.name,
          ],
        )
        .toList();

    await DatabaseService.insertBatch(sql, args);
  }

  /// Update a supply
  Future<int> update(Supply supply) async {
    return DatabaseService.execute(
      '''
      UPDATE $_table
      SET bill = ?, date = ?, tPrice = ?, pPrice = ?, notes = ?, 
          belongTo = ?, type = ?
      WHERE id = ?
      ''',
      [
        supply.bill,
        supply.date.millisecondsSinceEpoch,
        supply.tPrice,
        supply.pPrice,
        supply.notes,
        supply.belongTo,
        supply.type.name,
        supply.id,
      ],
    );
  }

  /// Get supplies by type AND belongTo (the third-screen data view)
  Future<List<Supply>> getByTypeAndBelongTo(
    SupplyType type,
    String belongTo,
  ) async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table WHERE type = ? AND belongTo = ? ORDER BY date DESC',
      [type.name, belongTo],
    );
    return results.map(Supply.fromMap).toList();
  }

  /// Get all supplies
  Future<List<Supply>> getAll() async {
    final results = await DatabaseService.query('SELECT * FROM $_table');
    return results.map(Supply.fromMap).toList();
  }

  /// Get all supplies by type (e.g., all woods, all paints)
  Future<List<Supply>> getByType(SupplyType type) async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table WHERE type = ? ORDER BY date DESC',
      [type.name],
    );
    return results.map(Supply.fromMap).toList();
  }

  /// Get all unpaid supplies
  Future<List<Supply>> getUnpaid() async {
    final results = await DatabaseService.query('''
      SELECT * FROM $_table 
      WHERE tPrice > pPrice
      ORDER BY date DESC
      ''');
    return results.map(Supply.fromMap).toList();
  }

  /// Get unpaid supplies by type
  Future<List<Supply>> getUnpaidByType(SupplyType type) async {
    final results = await DatabaseService.query(
      '''
      SELECT * FROM $_table 
      WHERE type = ? AND tPrice > pPrice
      ORDER BY date DESC
      ''',
      [type.name],
    );
    return results.map(Supply.fromMap).toList();
  }

  /// Calculate total unpaid by type
  Future<int> getTotalUnpaidByType(SupplyType type) async {
    final results = await DatabaseService.query(
      '''
      SELECT SUM(tPrice - pPrice) AS total 
      FROM $_table 
      WHERE type = ? AND tPrice > pPrice
      ''',
      [type.name],
    );
    if (results.isEmpty) return 0;
    final total = results.first['total'];
    return total is int ? total : (total as double).toInt();
  }

  /// Delete by ID
  Future<int> deleteById(int id) async {
    return DatabaseService.execute('DELETE FROM $_table WHERE id = ?', [id]);
  }

  /// Delete by type
  Future<int> deleteByType(SupplyType type) async {
    return DatabaseService.execute('DELETE FROM $_table WHERE type = ?', [
      type.name,
    ]);
  }

  /// Delete by belongTo
  Future<int> deleteByBelongTo(String belongTo) async {
    return DatabaseService.execute('DELETE FROM $_table WHERE belongTo = ?', [
      belongTo,
    ]);
  }
}

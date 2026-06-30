import 'package:taif_alamin/data/database/database_service.dart';
import 'package:taif_alamin/data/models/transport_model.dart';

class TransportRepository {
  static const _table = 'Transport';

  /// Insert a single transport record
  Future<int> insert(Transport transport) async {
    return DatabaseService.execute(
      '''
      INSERT INTO $_table 
      (price, date, notes)
      VALUES (?, ?, ?)
      ''',
      [transport.price, transport.date.millisecondsSinceEpoch, transport.notes],
    );
  }

  /// Insert batch
  Future<void> insertBatch(List<Transport> transports) async {
    const sql =
        '''
      INSERT INTO $_table 
      (price, date, notes)
      VALUES (?, ?, ?)
    ''';

    final args = transports
        .map((t) => [t.price, t.date.millisecondsSinceEpoch, t.notes])
        .toList();

    await DatabaseService.insertBatch(sql, args);
  }

  /// Update a transport record
  Future<int> update(Transport transport) async {
    return DatabaseService.execute(
      '''
      UPDATE $_table
      SET price = ?, date = ?, notes = ?
      WHERE id = ?
      ''',
      [
        transport.price,
        transport.date.millisecondsSinceEpoch,
        transport.notes,
        transport.id,
      ],
    );
  }

  /// Get all transport records
  Future<List<Transport>> getAll() async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table ORDER BY date DESC',
    );

    if (results.isNotEmpty) {
      return results.map(Transport.fromMap).toList();
    }

    return [];
  }

  /// Get single transport by ID
  Future<Transport?> getById(int id) async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table WHERE id = ?',
      [id],
    );
    return results.isEmpty ? null : Transport.fromMap(results.first);
  }

  /// Get transport records within date range
  Future<List<Transport>> getByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final results = await DatabaseService.query(
      '''
      SELECT * FROM $_table 
      WHERE date BETWEEN ? AND ?
      ORDER BY date DESC
      ''',
      [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
    );
    return results.map(Transport.fromMap).toList();
  }

  /// Get total transport cost (sum of all prices)
  Future<int> getTotalPrice() async {
    final results = await DatabaseService.query(
      'SELECT SUM(price) AS total FROM $_table',
    );
    if (results.isEmpty || results.first['total'] == null) return 0;
    final total = results.first['total'];
    return total is int ? total : (total as double).toInt();
  }

  /// Get total cost for a specific date range
  Future<int> getTotalPriceByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final results = await DatabaseService.query(
      '''
      SELECT SUM(price) AS total FROM $_table 
      WHERE date BETWEEN ? AND ?
      ''',
      [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
    );
    if (results.isEmpty || results.first['total'] == null) return 0;
    final total = results.first['total'];
    return total is int ? total : (total as double).toInt();
  }

  /// Get average transport cost
  Future<int> getAveragePrice() async {
    final results = await DatabaseService.query(
      'SELECT AVG(price) AS average FROM $_table',
    );
    if (results.isEmpty || results.first['total'] == null) return 0;
    final avg = results.first['average'];
    return avg is int ? avg : (avg as double).toInt();
  }

  /// Get count of transport records
  Future<int> getCount() async {
    final results = await DatabaseService.query(
      'SELECT COUNT(*) AS count FROM $_table',
    );
    if (results.isEmpty || results.first['total'] == null) return 0;
    return results.first['count'] as int;
  }

  /// Get latest transport record
  Future<Transport?> getLatest() async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table ORDER BY date DESC LIMIT 1',
    );
    return results.isEmpty ? null : Transport.fromMap(results.first);
  }

  /// Get transport records from last N days
  Future<List<Transport>> getFromLastDays(int days) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    return getByDateRange(startDate, DateTime.now());
  }

  /// Delete by ID
  Future<int> deleteById(int id) async {
    return DatabaseService.execute('DELETE FROM $_table WHERE id = ?', [id]);
  }

  /// Delete records within date range
  Future<int> deleteByDateRange(DateTime startDate, DateTime endDate) async {
    return DatabaseService.execute(
      '''
      DELETE FROM $_table 
      WHERE date BETWEEN ? AND ?
      ''',
      [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
    );
  }
}

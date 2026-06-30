import 'package:taif_alamin/data/database/database_service.dart';
import 'package:taif_alamin/data/models/item_model.dart';

class ItemsRepository {
  static const _table = 'Items';

  /// Insert a single item (id is AUTOINCREMENT, so it's omitted).
  Future<int> insert(Item item) async {
    return DatabaseService.execute(
      '''
      INSERT INTO $_table (item_name, count, price, date, belongTo)
      VALUES (?, ?, ?, ?, ?)
      ''',
      [item.itemName, item.count, item.price, item.date.millisecondsSinceEpoch, item.belongTo],
    );
  }

  /// Insert batch
  Future<void> insertBatch(List<Item> items) async {
    const sql =
        '''
      INSERT INTO $_table (item_name, count, price, date, belongTo)
      VALUES (?, ?, ?, ?, ?)
    ''';
    final args = items
        .map((i) => [i.itemName, i.count, i.price, i.date.millisecondsSinceEpoch, i.belongTo])
        .toList();
    await DatabaseService.insertBatch(sql, args);
  }

  /// Update an item
  Future<int> update(Item item) async {
    return DatabaseService.execute(
      '''
      UPDATE $_table
      SET item_name = ?, count = ?, price = ?, date = ?, belongTo = ?
      WHERE id = ?
      ''',
      [
        item.itemName,
        item.count,
        item.price,
        item.date.millisecondsSinceEpoch,
        item.belongTo,
        item.id,
      ],
    );
  }

  /// Get all items
  Future<List<Item>> getAll() async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table ORDER BY date DESC, id DESC',
    );
    return results.map(Item.fromMap).toList();
  }

  /// Get items for a specific category (belongTo) — the second-screen view.
  Future<List<Item>> getByBelongTo(String belongTo) async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table WHERE belongTo = ? ORDER BY date DESC, id DESC',
      [belongTo],
    );
    return results.map(Item.fromMap).toList();
  }

  /// Total purchase value for a category.
  Future<int> getTotalByBelongTo(String belongTo) async {
    final results = await DatabaseService.query(
      'SELECT SUM(count * price) AS total FROM $_table WHERE belongTo = ?',
      [belongTo],
    );
    if (results.isEmpty || results.first['total'] == null) return 0;
    final total = results.first['total'];
    return total is int ? total : (total as double).toInt();
  }

  /// Delete by ID
  Future<int> deleteById(int id) async {
    return DatabaseService.execute('DELETE FROM $_table WHERE id = ?', [id]);
  }

  /// Delete a whole category
  Future<int> deleteByBelongTo(String belongTo) async {
    return DatabaseService.execute('DELETE FROM $_table WHERE belongTo = ?', [
      belongTo,
    ]);
  }
}
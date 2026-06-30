import 'package:taif_alamin/data/database/database_service.dart';
import 'package:taif_alamin/data/models/exhibition_info_model.dart';

class ExhibitionsInfoRepository {
  static const _table = 'exhibitionsInfo';

  /// Get all exhibitions.
  Future<List<ExhibitionInfo>> getAll() async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table ORDER BY id DESC',
    );
    return results.map(ExhibitionInfo.fromMap).toList();
  }

  /// Get one exhibition by its (unique) belongTo key.
  Future<ExhibitionInfo?> getByBelongTo(String belongTo) async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table WHERE belongTo = ?',
      [belongTo],
    );
    return results.isEmpty ? null : ExhibitionInfo.fromMap(results.first);
  }

  /// Insert a new exhibition (id is AUTOINCREMENT, so it's omitted).
  Future<int> insert(ExhibitionInfo e) async {
    return DatabaseService.execute(
      '''
      INSERT INTO $_table (bill, name, phone, address, belongTo)
      VALUES (?, ?, ?, ?, ?)
      ''',
      [e.bill, e.name, e.phone, e.address, e.belongTo],
    );
  }

  /// Update an exhibition.
  Future<int> update(ExhibitionInfo e) async {
    return DatabaseService.execute(
      '''
      UPDATE $_table
      SET bill = ?, name = ?, phone = ?, address = ?, belongTo = ?
      WHERE id = ?
      ''',
      [e.bill, e.name, e.phone, e.address, e.belongTo, e.id],
    );
  }

  /// Delete by ID.
  Future<int> deleteById(int id) async {
    return DatabaseService.execute('DELETE FROM $_table WHERE id = ?', [id]);
  }
}
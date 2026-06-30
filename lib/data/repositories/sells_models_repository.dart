import 'package:taif_alamin/data/database/database_service.dart';
import 'package:taif_alamin/data/models/models_model.dart';

class SellsModelsRepository {
  static const _table = 'sellsModels';

  /// Insert a model
  Future<int> insert(SellsModel model) async {
    return DatabaseService.execute(
      '''
      INSERT INTO $_table
      (name, uuid, ten_chairs, eight_chairs, seven_chairs, three, two, chair, diwan, hidden)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        model.name,
        model.uuid,
        model.tenChairs,
        model.eightChairs,
        model.sevenChairs,
        model.three,
        model.two,
        model.chair,
        model.diwan,
        model.hidden,
      ],
    );
  }

  /// Get all non-hidden models, latest revision per UUID (append-only history).
  Future<List<SellsModel>> getAllActive() async {
    final results = await DatabaseService.query('''
      SELECT *
      FROM $_table em
      WHERE em.hidden = 0
        AND em.id = (
            SELECT MAX(id) FROM $_table WHERE uuid = em.uuid
        )
      ORDER BY em.name
    ''');
    return results.map(SellsModel.fromMap).toList();
  }

  /// Get all rows (including history / hidden).
  Future<List<SellsModel>> getAll() async {
    final results = await DatabaseService.query('SELECT * FROM $_table');
    return results.map(SellsModel.fromMap).toList();
  }

  /// Get by ID.
  Future<SellsModel?> getById(int id) async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table WHERE id = ?',
      [id],
    );
    return results.isEmpty ? null : SellsModel.fromMap(results.first);
  }

  /// Soft delete (hide every revision of the UUID).
  Future<int> deleteByUuid(String uuid) async {
    return DatabaseService.execute(
      'UPDATE $_table SET hidden = 1 WHERE uuid = ?',
      [uuid],
    );
  }

  /// Edit = append a new revision row sharing the same UUID.
  Future<int> insertRevision(SellsModel model) async {
    return insert(model);
  }
}

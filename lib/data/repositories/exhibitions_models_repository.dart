import 'package:taif_alamin/data/database/database_service.dart';
import 'package:taif_alamin/data/models/exhibitions_model_model.dart';

/// Append-only price book for exhibitions (mirrors sellsModels):
/// every edit inserts a new revision sharing the same [uuid]; the latest
/// revision per uuid is the active one. Deleting hides all revisions.
class ExhibitionsModelsRepository {
  static const _table = 'ExhibitionsModels';

  /// Insert a model / a new revision (id is AUTOINCREMENT).
  Future<int> insert(ExhibitionsModel model) async {
    return DatabaseService.execute(
      '''
      INSERT INTO $_table
      (name, uuid, ten_chairs, eight_chairs, seven_chairs, three, two, chair,
       diwan, belongTo, hidden)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
        model.belongTo,
        model.hidden,
      ],
    );
  }

  /// Edit = append a new revision with the same uuid.
  Future<int> insertRevision(ExhibitionsModel model) => insert(model);

  /// Active models (latest revision per uuid, not hidden).
  Future<List<ExhibitionsModel>> getAllActive() async {
    final results = await DatabaseService.query('''
      SELECT *
      FROM $_table em
      WHERE em.hidden = 0
        AND em.id = (SELECT MAX(id) FROM $_table WHERE uuid = em.uuid)
      ORDER BY em.name
    ''');
    return results.map(ExhibitionsModel.fromMap).toList();
  }

  /// Active models for one showroom (latest revision per uuid, not hidden).
  Future<List<ExhibitionsModel>> getActiveByBelongTo(String belongTo) async {
    final results = await DatabaseService.query(
      '''
      SELECT *
      FROM $_table em
      WHERE em.hidden = 0
        AND em.belongTo = ?
        AND em.id = (SELECT MAX(id) FROM $_table WHERE uuid = em.uuid)
      ORDER BY em.name
      ''',
      [belongTo],
    );
    return results.map(ExhibitionsModel.fromMap).toList();
  }

  Future<List<ExhibitionsModel>> getAll() async {
    final results = await DatabaseService.query('SELECT * FROM $_table');
    return results.map(ExhibitionsModel.fromMap).toList();
  }

  Future<ExhibitionsModel?> getById(int id) async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table WHERE id = ?',
      [id],
    );
    return results.isEmpty ? null : ExhibitionsModel.fromMap(results.first);
  }

  /// Soft delete every revision sharing the uuid.
  Future<int> deleteByUuid(String uuid) async {
    return DatabaseService.execute(
      'UPDATE $_table SET hidden = 1 WHERE uuid = ?',
      [uuid],
    );
  }
}
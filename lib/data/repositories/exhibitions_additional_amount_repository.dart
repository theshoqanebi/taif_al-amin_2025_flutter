import 'package:taif_alamin/data/database/database_service.dart';
import 'package:taif_alamin/data/models/exhibition_additional_amount_model.dart';

class ExhibitionsAdditionalAmountRepository {
  static const _table = 'ExhibitionsAdditionalAmount';

  /// Scope by bill AND belongTo — bill is not unique across showrooms.
  Future<List<ExhibitionAdditionalAmount>> getByBill(
    String bill,
    String belongTo,
  ) async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table WHERE bill = ? AND belongTo = ?',
      [bill, belongTo],
    );
    return results.map(ExhibitionAdditionalAmount.fromMap).toList();
  }

  Future<List<ExhibitionAdditionalAmount>> getByBelongTo(
    String belongTo,
  ) async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table WHERE belongTo = ?',
      [belongTo],
    );
    return results.map(ExhibitionAdditionalAmount.fromMap).toList();
  }

  Future<int> insert(ExhibitionAdditionalAmount a) async {
    return DatabaseService.execute(
      '''
      INSERT INTO $_table (bill, name, count, price, belongTo)
      VALUES (?, ?, ?, ?, ?)
      ''',
      [a.bill, a.name, a.count, a.price, a.belongTo],
    );
  }

  Future<int> update(ExhibitionAdditionalAmount a) async {
    return DatabaseService.execute(
      '''
      UPDATE $_table
      SET bill = ?, name = ?, count = ?, price = ?, belongTo = ?
      WHERE id = ?
      ''',
      [a.bill, a.name, a.count, a.price, a.belongTo, a.id],
    );
  }

  Future<int> deleteById(int id) async {
    return DatabaseService.execute('DELETE FROM $_table WHERE id = ?', [id]);
  }

  Future<int> deleteByBill(String bill, String belongTo) async {
    return DatabaseService.execute(
      'DELETE FROM $_table WHERE bill = ? AND belongTo = ?',
      [bill, belongTo],
    );
  }
}
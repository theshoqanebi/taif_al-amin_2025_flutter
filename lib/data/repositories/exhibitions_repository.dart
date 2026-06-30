import 'package:taif_alamin/data/database/database_service.dart';
import 'package:taif_alamin/data/models/exhibition_additional_amount_model.dart';
import 'package:taif_alamin/data/models/exhibition_model.dart';
import 'package:taif_alamin/data/models/exhibition_multi_sell_model.dart';

class ExhibitionsRepository {
  static const _table = 'Exhibitions';

  Future<List<Exhibition>> getAll() async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table ORDER BY date DESC, id DESC',
    );
    return results.map(Exhibition.fromMap).toList();
  }

  Future<List<Exhibition>> getByBelongTo(String belongTo) async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table WHERE belongTo = ? ORDER BY date DESC, id DESC',
      [belongTo],
    );
    return results.map(Exhibition.fromMap).toList();
  }

  Future<Exhibition?> getByBill(String bill, {String? belongTo}) async {
    final results = belongTo == null
        ? await DatabaseService.query(
            'SELECT * FROM $_table WHERE bill = ?',
            [bill],
          )
        : await DatabaseService.query(
            'SELECT * FROM $_table WHERE bill = ? AND belongTo = ?',
            [bill, belongTo],
          );
    return results.isEmpty ? null : Exhibition.fromMap(results.first);
  }

  /// A bill is only required to be unique **within its own showroom**
  /// (`belongTo`) — different showrooms legitimately reuse the same bill
  /// number, each keeping its own sequence (legacy behavior).
  Future<bool> billExists(
    String bill, {
    required String belongTo,
    int? excludeId,
  }) async {
    final results = await DatabaseService.query(
      'SELECT 1 FROM $_table WHERE bill = ? AND belongTo = ? AND id != ?',
      [bill, belongTo, excludeId ?? -1],
    );
    return results.isNotEmpty;
  }

  /// Highest numeric bill so far **for this showroom** (for auto-numbering
  /// the next invoice) — each showroom continues its own sequence.
  Future<int> maxBillNumber(String belongTo) async {
    final results = await DatabaseService.query(
      'SELECT MAX(CAST(bill AS INTEGER)) AS m FROM $_table WHERE belongTo = ?',
      [belongTo],
    );
    if (results.isEmpty) return 0;
    return (results.first['m'] as num?)?.toInt() ?? 0;
  }

  /// Create an exhibition + its children atomically.
  Future<int> createFull({
    required Exhibition exhibition,
    required List<ExhibitionMultiSell> multiSells,
    required List<ExhibitionAdditionalAmount> additionalAmounts,
  }) async {
    final db = await DatabaseService.db;
    return db.transaction<int>((txn) async {
      final id = await txn.insert(_table, exhibition.toMap()..remove('id'));
      for (final m in multiSells) {
        await txn.insert(
          'exhibitions_multisells',
          m.copyWith(bill: exhibition.bill, belongTo: exhibition.belongTo).toMap()..remove('id'),
        );
      }
      for (final a in additionalAmounts) {
        await txn.insert(
          'ExhibitionsAdditionalAmount',
          a.copyWith(bill: exhibition.bill, belongTo: exhibition.belongTo).toMap()..remove('id'),
        );
      }
      return id;
    });
  }

  /// Replace an exhibition's children wholesale + update the header.
  Future<void> updateFull({
    required Exhibition exhibition,
    required List<ExhibitionMultiSell> multiSells,
    required List<ExhibitionAdditionalAmount> additionalAmounts,
  }) async {
    final db = await DatabaseService.db;
    await db.transaction((txn) async {
      await txn.update(
        _table,
        exhibition.toMap(),
        where: 'id = ?',
        whereArgs: [exhibition.id],
      );
      await txn.delete(
        'exhibitions_multisells',
        where: 'bill = ? AND belongTo = ?',
        whereArgs: [exhibition.bill, exhibition.belongTo],
      );
      await txn.delete(
        'ExhibitionsAdditionalAmount',
        where: 'bill = ? AND belongTo = ?',
        whereArgs: [exhibition.bill, exhibition.belongTo],
      );
      for (final m in multiSells) {
        await txn.insert(
          'exhibitions_multisells',
          m.copyWith(bill: exhibition.bill, belongTo: exhibition.belongTo).toMap()..remove('id'),
        );
      }
      for (final a in additionalAmounts) {
        await txn.insert(
          'ExhibitionsAdditionalAmount',
          a.copyWith(bill: exhibition.bill, belongTo: exhibition.belongTo).toMap()..remove('id'),
        );
      }
    });
  }

  Future<void> deleteFull(Exhibition exhibition) async {
    final db = await DatabaseService.db;
    await db.transaction((txn) async {
      await txn.delete(
        'exhibitions_multisells',
        where: 'bill = ? AND belongTo = ?',
        whereArgs: [exhibition.bill, exhibition.belongTo],
      );
      await txn.delete(
        'ExhibitionsAdditionalAmount',
        where: 'bill = ? AND belongTo = ?',
        whereArgs: [exhibition.bill, exhibition.belongTo],
      );
      await txn.delete(_table, where: 'id = ?', whereArgs: [exhibition.id]);
    });
  }
}
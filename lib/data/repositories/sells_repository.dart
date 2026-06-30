import 'package:taif_alamin/data/database/database_service.dart';
import 'package:taif_alamin/data/models/additional_amount_model.dart';
import 'package:taif_alamin/data/models/customer_debt_model.dart';
import 'package:taif_alamin/data/models/multi_sells_model.dart';
import 'package:taif_alamin/data/models/sells_model.dart';

/// Sells aggregate: header + line items + extras + the linked financial debt.
///
/// Children link by [bill]. The financial side lives in CustomersDebts
/// (uuid == Sells.payment_uuid) with payments in CustomersPayments (debt_id).
/// Create/update/delete keep all of it consistent inside one transaction.
class SellsRepository {
  static const _table = 'Sells';

  Future<List<Sell>> getAll() async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table ORDER BY id DESC',
    );
    return results.map(Sell.fromMap).toList();
  }

  Future<Sell?> getById(int id) async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table WHERE id = ?',
      [id],
    );
    return results.isEmpty ? null : Sell.fromMap(results.first);
  }

  Future<Sell?> getByBill(String bill) async {
    final results = await DatabaseService.query(
      'SELECT * FROM $_table WHERE bill = ?',
      [bill],
    );
    return results.isEmpty ? null : Sell.fromMap(results.first);
  }

  Future<bool> billExists(String bill, {int? excludeId}) async {
    final results = await DatabaseService.query(
      'SELECT 1 FROM $_table WHERE bill = ? AND id != ?',
      [bill, excludeId ?? -1],
    );
    return results.isNotEmpty;
  }

  Future<int> maxBillNumber() async {
    final results = await DatabaseService.query(
      'SELECT MAX(CAST(bill AS INTEGER)) AS m FROM $_table',
    );
    if (results.isEmpty) return 0;
    return (results.first['m'] as num?)?.toInt() ?? 0;
  }

  /// Create a sale + children + linked debt + first payment, atomically.
  /// [sell.paymentUuid] must equal [debt.uuid].
  Future<int> createFull({
    required Sell sell,
    required List<MultiSell> multiSells,
    required List<AdditionalAmount> additionalAmounts,
    CustomerDebt? debt,
    int firstPayment = 0,
  }) async {
    final database = await DatabaseService.db;
    return database.transaction<int>((txn) async {
      final sellId = await txn.insert(_table, sell.toMap()..remove('id'));

      for (final ms in multiSells) {
        await txn.insert(
          'multiSells',
          ms.copyWith(bill: sell.bill).toMap()..remove('id'),
        );
      }
      for (final aa in additionalAmounts) {
        await txn.insert(
          'additionalAmount',
          aa.copyWith(belongTo: sell.bill).toMap()..remove('id'),
        );
      }

      if (debt != null) {
        final debtId = await txn.insert(
          'CustomersDebts',
          debt.toMap()..remove('id'),
        );
        if (firstPayment > 0) {
          await txn.insert('CustomersPayments', {
            'debt_id': debtId,
            'payment_amount': firstPayment,
            'payment_date': debt.toMap()['debt_date'],
            'notes': 'الدفعة الأولى',
          });
        }
      }
      return sellId;
    });
  }

  /// Update a sale + children + linked debt header. Payments are left intact
  /// (managed from the debts screen).
  Future<void> updateFull({
    required Sell sell,
    required List<MultiSell> multiSells,
    required List<AdditionalAmount> additionalAmounts,
    CustomerDebt? debt,
  }) async {
    final database = await DatabaseService.db;
    await database.transaction((txn) async {
      await txn.update(
        _table,
        sell.toMap(),
        where: 'id = ?',
        whereArgs: [sell.id],
      );
      await txn.delete('multiSells', where: 'bill = ?', whereArgs: [sell.bill]);
      await txn.delete(
        'additionalAmount',
        where: 'belongTo = ?',
        whereArgs: [sell.bill],
      );
      for (final ms in multiSells) {
        await txn.insert(
          'multiSells',
          ms.copyWith(bill: sell.bill).toMap()..remove('id'),
        );
      }
      for (final aa in additionalAmounts) {
        await txn.insert(
          'additionalAmount',
          aa.copyWith(belongTo: sell.bill).toMap()..remove('id'),
        );
      }

      if (debt != null && debt.uuid != null) {
        final existing = await txn.query(
          'CustomersDebts',
          where: 'uuid = ?',
          whereArgs: [debt.uuid],
        );
        final map = debt.toMap()..remove('id');
        if (existing.isEmpty) {
          await txn.insert('CustomersDebts', map);
        } else {
          // keep notes intact unless provided; update financial fields
          await txn.update(
            'CustomersDebts',
            {
              'debtor_name': map['debtor_name'],
              'debt_date': map['debt_date'],
              'bill_number': map['bill_number'],
              'total_price': map['total_price'],
              'discount': map['discount'],
              'currency': map['currency'],
            },
            where: 'uuid = ?',
            whereArgs: [debt.uuid],
          );
        }
      }
    });
  }

  /// Delete a sale + children + its debt + the debt's payments, atomically.
  Future<void> deleteFull(Sell sell) async {
    final database = await DatabaseService.db;
    await database.transaction((txn) async {
      await txn.delete('multiSells', where: 'bill = ?', whereArgs: [sell.bill]);
      await txn.delete(
        'additionalAmount',
        where: 'belongTo = ?',
        whereArgs: [sell.bill],
      );
      if (sell.paymentUuid != null) {
        final debtRows = await txn.query(
          'CustomersDebts',
          columns: ['id'],
          where: 'uuid = ?',
          whereArgs: [sell.paymentUuid],
        );
        for (final row in debtRows) {
          final debtId = row['id'];
          await txn.delete(
            'CustomersPayments',
            where: 'debt_id = ?',
            whereArgs: [debtId],
          );
        }
        await txn.delete(
          'CustomersDebts',
          where: 'uuid = ?',
          whereArgs: [sell.paymentUuid],
        );
      }
      await txn.delete(_table, where: 'id = ?', whereArgs: [sell.id]);
    });
  }
}

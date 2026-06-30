import 'package:taif_alamin/data/models/additional_amount_model.dart';
import 'package:taif_alamin/data/models/multi_sells_model.dart';
import 'package:taif_alamin/data/repositories/additional_amounts_repository.dart';
import 'package:taif_alamin/data/repositories/multi_sells_repository.dart';

/// A sale (invoice header).
///
/// Real schema (Sells):
///   id, bill, name, phone, address, date TEXT(ISO), payment_uuid,
///   discount_details
/// There is NO stored total / discount amount / paid; the financial side
/// lived in a separate payments table (via [paymentUuid]) in the old app.
/// The total is computed from the children (multiSells + additionalAmount).
class Sell {
  final int id;
  final String bill;
  final String? name;
  final String? phone;
  final String? address;
  final DateTime date; // stored as ISO 'yyyy-MM-dd' TEXT
  final String? paymentUuid;
  final String? discountDetails;

  Sell({
    required this.id,
    required this.bill,
    this.name,
    this.phone,
    this.address,
    required this.date,
    this.paymentUuid,
    this.discountDetails,
  });

  /// Fetch this sale's line items (by bill).
  Future<List<MultiSell>> getMultiSells() =>
      MultiSellsRepository().getByBill(bill);

  /// Fetch this sale's extra charges (by bill).
  Future<List<AdditionalAmount>> getAdditionalAmounts() =>
      AdditionalAmountsRepository().getByBill(bill);

  /// Total of all children (multiSells + additionalAmount).
  Future<int> computeTotal() async {
    final multi = await getMultiSells();
    final extras = await getAdditionalAmounts();
    final multiTotal = multi.fold<int>(0, (s, m) => s + m.totalPrice);
    final extrasTotal = extras.fold<int>(0, (s, a) => s + a.totalPrice);
    return multiTotal + extrasTotal;
  }

  Sell copyWith({
    int? id,
    String? bill,
    String? name,
    String? phone,
    String? address,
    DateTime? date,
    String? paymentUuid,
    String? discountDetails,
  }) => Sell(
    id: id ?? this.id,
    bill: bill ?? this.bill,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    date: date ?? this.date,
    paymentUuid: paymentUuid ?? this.paymentUuid,
    discountDetails: discountDetails ?? this.discountDetails,
  );

  static String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() => {
    'id': id,
    'bill': bill,
    'name': name,
    'phone': phone,
    'address': address,
    'date': _iso(date),
    'payment_uuid': paymentUuid,
    'discount_details': discountDetails,
  };

  factory Sell.fromMap(Map<String, dynamic> map) => Sell(
    id: _toInt(map['id']),
    bill: map['bill']?.toString() ?? '',
    name: map['name'] as String?,
    phone: map['phone'] as String?,
    address: map['address'] as String?,
    date: _toDate(map['date']),
    paymentUuid: map['payment_uuid'] as String?,
    discountDetails: map['discount_details'] as String?,
  );

  static int _toInt(Object? v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim()) ?? 0;
  }

  /// Tolerant: ISO string ('yyyy-MM-dd' / full ISO) or millis (int/num/string).
  static DateTime _toDate(Object? v) {
    if (v == null) return DateTime.now();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    final s = v.toString().trim();
    final parsed = DateTime.tryParse(s);
    if (parsed != null) return parsed;
    final ms = int.tryParse(s);
    if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    return DateTime.now();
  }

  @override
  String toString() => 'Sell(id: $id, bill: $bill, name: $name)';
}

import 'package:intl/intl.dart';
import 'package:taif_alamin/data/models/multi_sells_model.dart';
import 'package:taif_alamin/data/models/sells_model.dart';
import 'package:taif_alamin/utils/docx_utils.dart';
import 'package:taif_alamin/utils/price_utils.dart';

class MakeOderBill {
  final DocxUtils docx;
  const MakeOderBill({required this.docx});

  MakeOderBill fillBaseInfo({
    required String bill,
    required String name,
    required String phone,
    required String address,
    required DateTime date,
  }) {
    docx.setCell(table: 1, col: 2, row: 1, text: 'رقم الفاتورة: $bill');
    docx.setCell(table: 1, col: 2, row: 2, text: 'حضرة السيد: $name');
    docx.setCell(table: 1, col: 2, row: 3, text: 'رقم الهاتف: $phone');
    docx.setCell(table: 1, col: 2, row: 4, text: 'العنوان: $address');
    docx.setCell(
      table: 1,
      col: 2,
      row: 5,
      text: 'التاريخ: ${DateFormat('yyyy-MM-dd').format(date)}',
    );
    return this;
  }

  /// [discount] and [paid] come from the sale's linked debt (Sell itself
  /// stores neither) — pass 0 for an undiscounted/unpaid bill.
  ///
  /// Table 2 layout (per the actual template, right-to-left):
  ///   item rows:  col1=ت (index), col2=المجموع (line total),
  ///               col3=التفاصيل (details — for "سيت" lines, includes the
  ///               chair count per set), col4=العدد (count — number of sets
  ///               for "سيت" lines, quantity otherwise), col5=السعر (unit
  ///               price — per-set price for "سيت", price-per-unit
  ///               otherwise, or the stored price directly for extras).
  ///   totals: 4 separate rows right after the items, each with only 2
  ///           cells — col1 is the label (already baked into the
  ///           template), col2 is the value:
  ///             رow total+2 = المجموع, +3 = الخصم, +4 = الواصل, +5 = الباقي
  Future<MakeOderBill> fillSellData(
    Sell sell, {
    int discount = 0,
    int paid = 0,
  }) async {
    final multi = await sell.getMultiSells();
    final extras = await sell.getAdditionalAmounts();

    // One entry per row, multi-sells first then additional amounts — in
    // the same order they'll be printed.
    final lines =
        <({String details, String count, int total, int unitPrice})>[
          for (final m in multi)
            (
              details:
                  '${m.modelName} ${m.type.label}'
                  '${m.type == SellType.set ? ' (${m.count.round()} كرسي)' : ''}'
                  '${(m.color ?? '').isEmpty ? '' : ' - ${m.color}'}',
              // "سيت": count is chairs-per-set (7/8/10) — the *quantity* is
              // setNumber. Every other type: count is the quantity itself.
              count: m.type == SellType.set
                  ? '${m.setNumber}'
                  : _fmtNum(m.count),
              total: m.totalPrice,
              // Per-set price for "سيت" (totalPrice ÷ number of sets);
              // per-unit price otherwise (totalPrice ÷ quantity).
              unitPrice: m.type == SellType.set
                  ? (m.setNumber > 0
                        ? (m.totalPrice / m.setNumber).round()
                        : m.totalPrice)
                  : (m.count > 0
                        ? (m.totalPrice / m.count).round()
                        : m.totalPrice),
            ),
          for (final a in extras)
            (
              details: a.name ?? 'مبلغ إضافي',
              count: _fmtNum(a.count),
              total: a.totalPrice,
              unitPrice: a.price, // already the per-unit price
            ),
        ];

    final total = lines.length;
    for (int i = 0; i < total; i++) {
      if ((i + 1) < total) {
        docx.appendRow(table: 2, templateRow: i + 2);
      }
      final line = lines[i];
      // ت (index)
      docx.setCell(table: 2, col: 1, row: i + 2, text: "${i + 1}");
      // المجموع (line total)
      docx.setCell(
        table: 2,
        col: 2,
        row: i + 2,
        text: PriceUtils.addCommas(line.total),
      );
      // التفاصيل
      docx.setCell(table: 2, col: 3, row: i + 2, text: line.details);
      // العدد
      docx.setCell(table: 2, col: 4, row: i + 2, text: line.count);
      // السعر (سعر المفرد)
      docx.setCell(
        table: 2,
        col: 5,
        row: i + 2,
        text: PriceUtils.addCommas(line.unitPrice),
      );
    }

    final grandTotal = lines.fold<int>(0, (s, l) => s + l.total);
    final finalPrice = grandTotal - discount;
    final remaining = finalPrice - paid;

    // No items at all means no insertions happened, so the totals never
    // moved off their original template rows (3,4,5,6) — guard the edge
    // case instead of computing row 2 (the still-blank item row) for المجموع.
    final totalsBaseRow = (total == 0 ? 1 : total) + 2;

    // المجموع
    docx.setCell(
      table: 2,
      col: 2,
      row: totalsBaseRow,
      text: PriceUtils.addCommas(grandTotal),
    );

    // الخصم
    docx.setCell(
      table: 2,
      col: 2,
      row: totalsBaseRow + 1,
      text: PriceUtils.addCommas(discount),
    );

    // الواصل
    docx.setCell(
      table: 2,
      col: 2,
      row: totalsBaseRow + 2,
      text: PriceUtils.addCommas(paid),
    );

    // الباقي
    docx.setCell(
      table: 2,
      col: 2,
      row: totalsBaseRow + 3,
      text: PriceUtils.addCommas(remaining),
    );

    return this;
  }

  String _fmtNum(double n) =>
      n == n.roundToDouble() ? n.toInt().toString() : n.toString();

  @Deprecated(
    'Never call selfSave() — it overwrites the loaded template in place. '
    'Always save the filled document to a fresh temp-folder copy instead '
    '(see PrintUtils / the print path workflow) and use save(path: ...) '
    'with that path.',
  )
  void selfSave() {
    throw UnsupportedError(
      'selfSave() is disabled: it would overwrite the original .docx '
      'template. Save to a temp-folder path with save(path: ...) instead.',
    );
  }

  void save({required String path}) {
    docx.save(path);
  }
}

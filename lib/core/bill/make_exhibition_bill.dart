import 'package:intl/intl.dart';
import 'package:taif_alamin/data/constants/currency.dart';
import 'package:taif_alamin/data/models/exhibition_model.dart';
import 'package:taif_alamin/data/models/multi_sells_model.dart' show SellType;
import 'package:taif_alamin/utils/docx_utils.dart';
import 'package:taif_alamin/utils/price_utils.dart';

/// Same routine as [MakeOderBill], just sourced from an [Exhibition] —
/// showroom info goes where a sale would have customer name/phone/address.
class MakeExhibitionBill {
  final DocxUtils docx;
  const MakeExhibitionBill({required this.docx});

  MakeExhibitionBill fillBaseInfo({
    required String bill,
    required String showroomTitle,
    required Currency currency,
    double? exchangeRate,
    String? notes,
    required DateTime date,
  }) {
    docx.setCell(table: 1, col: 2, row: 1, text: 'رقم الفاتورة: $bill');
    docx.setCell(table: 1, col: 2, row: 2, text: 'المعرض: $showroomTitle');
    docx.setCell(
      table: 1,
      col: 2,
      row: 3,
      text:
          'العملة: ${currency.toDisplayString()}'
          '${currency == Currency.usd && (exchangeRate ?? 0) > 0 ? ' (سعر الصرف: ${PriceUtils.addCommas(exchangeRate!.round())})' : ''}',
    );
    docx.setCell(
      table: 1,
      col: 2,
      row: 4,
      text: (notes == null || notes.isEmpty) ? '' : 'ملاحظات: $notes',
    );
    docx.setCell(
      table: 1,
      col: 2,
      row: 5,
      text: 'التاريخ: ${DateFormat('yyyy-MM-dd').format(date)}',
    );
    return this;
  }

  /// [paid] isn't tracked on [Exhibition] yet (no payed_amount field) —
  /// pass 0 (the default) until that's added; الواصل/الباقي will reflect
  /// nothing paid in the meantime.
  ///
  /// Table 2 layout — identical to [MakeOderBill.fillSellData]: see that
  /// method's doc comment for the column/row breakdown.
  Future<MakeExhibitionBill> fillExhibitionData(
    Exhibition exhibition, {
    int paid = 0,
  }) async {
    final multi = await exhibition.getMultiSells();
    final extras = await exhibition.getAdditionalAmounts();

    final lines =
        <({String details, String count, int total, int unitPrice})>[
          for (final m in multi)
            (
              details:
                  '${m.modelName} ${m.type.label}'
                  '${m.type == SellType.set ? ' (${m.count.round()} كرسي)' : ''}'
                  '${(m.color ?? '').isEmpty ? '' : ' - ${m.color}'}',
              count: m.type == SellType.set
                  ? '${m.setNumber}'
                  : _fmtNum(m.count),
              total: m.totalPrice,
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
              unitPrice: a.price,
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
    final discount = exhibition.discount;
    final finalPrice = grandTotal - discount;
    final remaining = finalPrice - paid;

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

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taif_alamin/data/constants/currency.dart';
import 'package:taif_alamin/data/constants/supply_type.dart';
import 'package:taif_alamin/data/models/customer_debt_model.dart';
import 'package:taif_alamin/data/models/exhibition_model.dart';
import 'package:taif_alamin/data/models/multi_sells_model.dart';
import 'package:taif_alamin/data/models/on_us_debt_model.dart';
import 'package:taif_alamin/data/models/sells_model.dart';
import 'package:taif_alamin/data/models/supply_model.dart';
import 'package:taif_alamin/data/repositories/exhibitions_info_repository.dart';
import 'package:taif_alamin/data/repositories/exhibitions_multi_sells_repository.dart';
import 'package:taif_alamin/data/repositories/exhibitions_repository.dart';
import 'package:taif_alamin/data/repositories/multi_sells_repository.dart';
import 'package:taif_alamin/data/repositories/transport_repository.dart';
import 'package:taif_alamin/presentation/cubits/debts_cubit/debts_cubit.dart';
import 'package:taif_alamin/presentation/cubits/on_us_debts_cubit/on_us_debts_cubit.dart';
import 'package:taif_alamin/presentation/cubits/sells_cubit/sells_cubit.dart';
import 'package:taif_alamin/presentation/cubits/supplies_cubit/supplies_cubit.dart';
import 'package:taif_alamin/utils/price_utils.dart';
import 'package:taif_alamin/utils/snack_bar_util.dart';

const _kAccent = Color(0xFF003763);

// ---------------------------------------------------------------------------
// Report data model
//
// A report is a list of blocks. A block has an optional heading and may carry
// a KPI table (label/value rows) and/or a per-model table. This is flexible
// enough for: a flat KPI summary, a per-showroom (معرض) breakdown, and a
// per-model (grouped by uuid) breakdown — all rendered + exported uniformly.
// ---------------------------------------------------------------------------

class _StatRow {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);
}

/// One aggregated model line: grouped by the model's uuid (same uuid = one
/// model), with how many times it sold and the amounts (split by currency).
class _ModelRow {
  final String model;
  final int salesCount; // عدد المبيعات (number of sale lines)
  final double quantity; // الكمية (sets for "سيت", else the count)
  final int amountIqd;
  final int amountUsd;
  const _ModelRow({
    required this.model,
    required this.salesCount,
    required this.quantity,
    required this.amountIqd,
    required this.amountUsd,
  });
}

/// A generic detail table (free-form columns) — used for the debts listing.
class _DetailTable {
  final List<String> headers;
  final List<List<String>> rows;
  const _DetailTable({required this.headers, required this.rows});
}

class _Block {
  final String? heading;
  final List<_StatRow> kpis;
  final List<_ModelRow> models;
  final _DetailTable? detail;
  const _Block({
    this.heading,
    this.kpis = const [],
    this.models = const [],
    this.detail,
  });
}

class _Report {
  final List<_Block> blocks;
  const _Report(this.blocks);
}

/// Mutable accumulator used while grouping line items by model uuid.
class _ModelAgg {
  String name;
  int salesCount = 0;
  double quantity = 0;
  int amountIqd = 0;
  int amountUsd = 0;
  _ModelAgg(this.name);
}

/// The categories shown in the top dropdown.
enum _Category {
  sells('المبيعات'),
  exhibitions('المعارض'),
  supplies('المواد الأولية'),
  debts('الديون (لنا على الزبائن)'),
  onUsDebts('ديون علينا'),
  transport('النقل');

  final String label;
  const _Category(this.label);
}

// ---------------------------------------------------------------------------
// helpers
// ---------------------------------------------------------------------------

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _fmtQty(double q) =>
    q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(1);

/// Inclusive date-range check. Either bound may be null (open-ended).
bool _inRange(DateTime date, DateTime? from, DateTime? to) {
  final d = DateTime(date.year, date.month, date.day);
  if (from != null && d.isBefore(DateTime(from.year, from.month, from.day))) {
    return false;
  }
  if (to != null && d.isAfter(DateTime(to.year, to.month, to.day))) {
    return false;
  }
  return true;
}

/// Sort aggregated models by total amount (desc) and shape into rows.
List<_ModelRow> _shapeModels(Map<String, _ModelAgg> map) {
  final rows =
      map.values
          .map(
            (a) => _ModelRow(
              model: a.name,
              salesCount: a.salesCount,
              quantity: a.quantity,
              amountIqd: a.amountIqd,
              amountUsd: a.amountUsd,
            ),
          )
          .toList()
        ..sort(
          (a, b) =>
              (b.amountIqd + b.amountUsd).compareTo(a.amountIqd + a.amountUsd),
        );
  return rows;
}

String _esc(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

String _buildHtmlReport({
  required String title,
  required DateTime? from,
  required DateTime? to,
  required _Report report,
}) {
  final rangeText = (from == null && to == null)
      ? 'كل الفترات'
      : '${from != null ? _fmtDate(from) : '...'} إلى ${to != null ? _fmtDate(to) : '...'}';

  final buf = StringBuffer();
  for (final block in report.blocks) {
    if (block.heading != null) {
      buf.writeln('<h2>${_esc(block.heading!)}</h2>');
    }
    if (block.kpis.isNotEmpty) {
      buf.writeln(
        '<table><thead><tr><th>البيان</th><th>القيمة</th></tr>'
        '</thead><tbody>',
      );
      for (final r in block.kpis) {
        buf.writeln(
          '<tr><td>${_esc(r.label)}</td><td>${_esc(r.value)}</td></tr>',
        );
      }
      buf.writeln('</tbody></table>');
    }
    if (block.models.isNotEmpty) {
      final showIqd = block.models.any((m) => m.amountIqd != 0);
      final showUsd = block.models.any((m) => m.amountUsd != 0);
      buf.writeln(
        '<table><thead><tr><th>الموديل</th>'
        '<th>عدد المبيعات</th><th>الكمية</th>'
        '${showIqd ? '<th>المبلغ (دينار)</th>' : ''}'
        '${showUsd ? '<th>المبلغ (دولار)</th>' : ''}'
        '</tr></thead><tbody>',
      );
      for (final m in block.models) {
        buf.writeln(
          '<tr><td>${_esc(m.model)}</td>'
          '<td>${m.salesCount}</td>'
          '<td>${_fmtQty(m.quantity)}</td>'
          '${showIqd ? '<td>${PriceUtils.addCommas(m.amountIqd)}</td>' : ''}'
          '${showUsd ? '<td>${PriceUtils.addCommas(m.amountUsd)}</td>' : ''}'
          '</tr>',
        );
      }
      buf.writeln('</tbody></table>');
    }
    if (block.detail != null && block.detail!.rows.isNotEmpty) {
      final d = block.detail!;
      buf.writeln('<table><thead><tr>');
      for (final h in d.headers) {
        buf.writeln('<th>${_esc(h)}</th>');
      }
      buf.writeln('</tr></thead><tbody>');
      for (final row in d.rows) {
        buf.writeln('<tr>');
        for (final c in row) {
          buf.writeln('<td>${_esc(c)}</td>');
        }
        buf.writeln('</tr>');
      }
      buf.writeln('</tbody></table>');
    }
  }

  return '''
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<title>${_esc(title)}</title>
<style>
  body { font-family: Tahoma, Arial, sans-serif; padding: 24px; color:#1a1a1a; background:#fff; }
  h1 { color:#003763; margin-bottom: 4px; }
  h2 { color:#003763; margin:24px 0 8px; font-size:18px; border-bottom:2px solid #003763; padding-bottom:4px; }
  .range { color:#555; margin-bottom: 20px; font-size: 14px; }
  table { width:100%; border-collapse: collapse; margin-bottom:8px; }
  th, td { border:1px solid #ddd; padding:10px 14px; text-align:right; font-size:15px; }
  th { background:#003763; color:#fff; }
  tr:nth-child(even) td { background:#f7f9fb; }
  .footer { margin-top:28px; color:#999; font-size:12px; }
</style>
</head>
<body>
  <h1>${_esc(title)}</h1>
  <div class="range">الفترة: $rangeText</div>
$buf
  <div class="footer">تم إنشاء هذا التقرير بواسطة تايف الأمين بتاريخ ${_fmtDate(DateTime.now())}</div>
</body>
</html>
''';
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SellsCubit()),
        BlocProvider(create: (_) => DebtsCubit()),
        BlocProvider(create: (_) => SuppliesCubit()),
        BlocProvider(create: (_) => OnUsDebtsCubit()),
      ],
      child: const _AnalyticsBody(),
    );
  }
}

class _AnalyticsBody extends StatefulWidget {
  const _AnalyticsBody();

  @override
  State<_AnalyticsBody> createState() => _AnalyticsBodyState();
}

class _AnalyticsBodyState extends State<_AnalyticsBody> {
  bool _ready = false;
  String? _loadError;

  _Category _category = _Category.sells;
  DateTime? _from;
  DateTime? _to;
  bool _unpaidOnly = false;
  Future<_Report>? _future;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      await Future.wait([
        context.read<SellsCubit>().loadSells(),
        context.read<DebtsCubit>().loadAll(),
        context.read<SuppliesCubit>().loadAll(),
        context.read<OnUsDebtsCubit>().loadAll(),
      ]);
      if (mounted) {
        setState(() {
          _ready = true;
          _future = _compute();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    }
  }

  Future<_Report> _compute() {
    switch (_category) {
      case _Category.sells:
        return _computeSells(_from, _to);
      case _Category.exhibitions:
        return _computeExhibitions(_from, _to);
      case _Category.supplies:
        return _computeSupplies(_from, _to);
      case _Category.debts:
        return _computeDebts(_from, _to);
      case _Category.onUsDebts:
        return _computeOnUsDebts(_from, _to);
      case _Category.transport:
        return _computeTransport(_from, _to);
    }
  }

  void _recompute() {
    setState(() {
      _future = _compute();
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _from : _to) ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
    _recompute();
  }

  void _clearRange() {
    setState(() {
      _from = null;
      _to = null;
    });
    _recompute();
  }

  Future<void> _exportHtml() async {
    try {
      final report = await (_future ?? _compute());
      final html = _buildHtmlReport(
        title: 'إحصائات ${_category.label}',
        from: _from,
        to: _to,
        report: report,
      );
      final result = await getSaveLocation(
        suggestedName:
            '${_category.label}_${DateTime.now().millisecondsSinceEpoch}.html',
        acceptedTypeGroups: [
          const XTypeGroup(label: 'HTML', extensions: ['html']),
        ],
      );
      if (result == null || !mounted) return;
      await File(
        result.path,
      ).writeAsBytes(Uint8List.fromList(utf8.encode(html)));
      if (mounted) {
        SnackBarUtil.showSuccess(context, 'تم التصدير إلى ${result.path}');
      }
    } catch (e) {
      if (mounted) SnackBarUtil.showError(context, 'خطأ بالتصدير: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: !_ready
            ? Center(
                child: _loadError != null
                    ? Text('خطأ بتحميل البيانات: $_loadError')
                    : const CircularProgressIndicator(),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الإحصائات',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _kAccent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildControls(),
                    const SizedBox(height: 12),
                    Expanded(
                      child: FutureBuilder<_Report>(
                        future: _future,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('خطأ: ${snapshot.error}'),
                            );
                          }
                          final report = snapshot.data ?? const _Report([]);
                          if (report.blocks.isEmpty) {
                            return const Center(
                              child: Text('لا توجد بيانات ضمن هذه الفترة'),
                            );
                          }
                          return ListView(
                            children: [
                              for (final block in report.blocks)
                                _BlockCard(block: block),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
        persistentFooterButtons: [
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('رجوع'),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Category dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<_Category>(
              value: _category,
              icon: const Icon(Icons.arrow_drop_down, color: _kAccent),
              items: [
                for (final c in _Category.values)
                  DropdownMenuItem(value: c, child: Text(c.label)),
              ],
              onChanged: (c) {
                if (c == null) return;
                setState(() {
                  _category = c;
                  _future = _compute();
                });
              },
            ),
          ),
        ),
        OutlinedButton(
          onPressed: () => _pickDate(isFrom: true),
          child: Text(_from == null ? 'من تاريخ' : 'من: ${_fmtDate(_from!)}'),
        ),
        OutlinedButton(
          onPressed: () => _pickDate(isFrom: false),
          child: Text(_to == null ? 'إلى تاريخ' : 'إلى: ${_fmtDate(_to!)}'),
        ),
        if (_from != null || _to != null)
          TextButton(
            onPressed: _clearRange,
            child: const Text('الكل (إزالة الفلتر)'),
          ),
        if (_category == _Category.debts || _category == _Category.onUsDebts)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: _unpaidOnly,
                onChanged: (v) {
                  setState(() {
                    _unpaidOnly = v ?? false;
                    _future = _compute();
                  });
                },
              ),
              const Text('غير المسددين فقط'),
            ],
          ),
        OutlinedButton.icon(
          onPressed: _exportHtml,
          icon: const Icon(Icons.file_download, size: 18),
          label: const Text('تصدير HTML'),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // Per-category computation
  // -------------------------------------------------------------------

  Future<_Report> _computeSells(DateTime? from, DateTime? to) async {
    final state = context.read<SellsCubit>().state;
    final sells = state.sells.where((s) => _inRange(s.date, from, to)).toList();
    final iqd = sells.where((s) => state.currencyOf(s) != Currency.usd);
    final usd = sells.where((s) => state.currencyOf(s) == Currency.usd);

    int sum(Iterable<Sell> l, int Function(Sell) f) =>
        l.fold<int>(0, (acc, x) => acc + f(x));

    final summary = _Block(
      heading: 'ملخص المبيعات',
      kpis: [
        _StatRow('عدد الوصولات', '${sells.length}'),
        _StatRow(
          'إجمالي المبيعات (دينار)',
          PriceUtils.addCommas(sum(iqd, (s) => state.totalOf(s))),
        ),
        _StatRow(
          'الخصم (دينار)',
          PriceUtils.addCommas(sum(iqd, (s) => state.discountOf(s))),
        ),
        _StatRow(
          'الطلب بعد الخصم (دينار)',
          PriceUtils.addCommas(sum(iqd, (s) => state.finalOf(s))),
        ),
        _StatRow(
          'المدفوع (دينار)',
          PriceUtils.addCommas(sum(iqd, (s) => state.paidOf(s))),
        ),
        _StatRow(
          'المتبقي (دينار)',
          PriceUtils.addCommas(sum(iqd, (s) => state.remainingOf(s))),
        ),
        _StatRow(
          'إجمالي المبيعات (دولار)',
          PriceUtils.addCommas(sum(usd, (s) => state.totalOf(s))),
        ),
        _StatRow(
          'الخصم (دولار)',
          PriceUtils.addCommas(sum(usd, (s) => state.discountOf(s))),
        ),
        _StatRow(
          'الطلب بعد الخصم (دولار)',
          PriceUtils.addCommas(sum(usd, (s) => state.finalOf(s))),
        ),
        _StatRow(
          'المدفوع (دولار)',
          PriceUtils.addCommas(sum(usd, (s) => state.paidOf(s))),
        ),
        _StatRow(
          'المتبقي (دولار)',
          PriceUtils.addCommas(sum(usd, (s) => state.remainingOf(s))),
        ),
      ],
    );

    // Per-model breakdown (grouped by uuid).
    final billToSell = {for (final s in sells) s.bill: s};
    final lines = await MultiSellsRepository().getAll();
    final map = <String, _ModelAgg>{};
    for (final m in lines) {
      final s = billToSell[m.bill];
      if (s == null) continue; // line's invoice is out of range / unknown
      final uuid = m.model?.uuid ?? '';
      final key = uuid.isNotEmpty ? 'u:$uuid' : 'id:${m.modelId}';
      final name = m.modelName.isNotEmpty ? m.modelName : 'موديل #${m.modelId}';
      final agg = map.putIfAbsent(key, () => _ModelAgg(name));
      if (agg.name.startsWith('موديل #') && m.modelName.isNotEmpty) {
        agg.name = m.modelName;
      }
      agg.salesCount++;
      agg.quantity += m.type == SellType.set ? m.setNumber.toDouble() : m.count;
      if (state.currencyOf(s) == Currency.usd) {
        agg.amountUsd += m.totalPrice;
      } else {
        agg.amountIqd += m.totalPrice;
      }
    }

    return _Report([
      summary,
      _Block(heading: 'حسب الموديل', models: _shapeModels(map)),
    ]);
  }

  Future<_Report> _computeExhibitions(DateTime? from, DateTime? to) async {
    final all = await ExhibitionsRepository().getAll();
    final filtered = all.where((e) => _inRange(e.date, from, to)).toList();

    // Resolve the human-readable showroom name from exhibitionsInfo,
    // keyed by belongTo (its UNIQUE key). Falls back to belongTo / bill.
    final infos = await ExhibitionsInfoRepository().getAll();
    final nameByBelong = <String, String>{};
    for (final i in infos) {
      final key = i.belongTo;
      if (key != null && key.isNotEmpty) nameByBelong[key] = i.label;
    }
    String showLabel(String belongTo) {
      if (nameByBelong.containsKey(belongTo)) return nameByBelong[belongTo]!;
      return belongTo.isEmpty ? 'بدون معرض' : belongTo;
    }

    // Group exhibitions by showroom (belongTo — the real key).
    final byShow = <String, List<Exhibition>>{};
    for (final e in filtered) {
      byShow.putIfAbsent(e.belongTo ?? '', () => []).add(e);
    }

    final msRepo = ExhibitionsMultiSellsRepository();
    final blocks = <_Block>[];

    int oIqdTotal = 0, oIqdDisc = 0, oUsdTotal = 0, oUsdDisc = 0;

    final belongKeys = byShow.keys.toList()
      ..sort((a, b) => showLabel(a).compareTo(showLabel(b)));
    for (final belongTo in belongKeys) {
      final list = byShow[belongTo]!;

      int iqdTotal = 0, iqdDisc = 0, usdTotal = 0, usdDisc = 0;
      for (final e in list) {
        final t = await e.computeTotal();
        if (e.currency == Currency.usd) {
          usdTotal += t;
          usdDisc += e.discount;
        } else {
          iqdTotal += t;
          iqdDisc += e.discount;
        }
      }
      oIqdTotal += iqdTotal;
      oIqdDisc += iqdDisc;
      oUsdTotal += usdTotal;
      oUsdDisc += usdDisc;

      final kpis = <_StatRow>[_StatRow('عدد الوصولات', '${list.length}')];
      if (iqdTotal != 0 || usdTotal == 0) {
        kpis.addAll([
          _StatRow('الطلب (دينار)', PriceUtils.addCommas(iqdTotal)),
          _StatRow('الخصم (دينار)', PriceUtils.addCommas(iqdDisc)),
          _StatRow(
            'بعد الخصم (دينار)',
            PriceUtils.addCommas(iqdTotal - iqdDisc),
          ),
        ]);
      }
      if (usdTotal != 0) {
        kpis.addAll([
          _StatRow('الطلب (دولار)', PriceUtils.addCommas(usdTotal)),
          _StatRow('الخصم (دولار)', PriceUtils.addCommas(usdDisc)),
          _StatRow(
            'بعد الخصم (دولار)',
            PriceUtils.addCommas(usdTotal - usdDisc),
          ),
        ]);
      }

      // Per-model breakdown within this showroom.
      final validBills = {for (final e in list) e.bill};
      final billCurrency = {for (final e in list) e.bill: e.currency};
      final lines = await msRepo.getByBelongTo(belongTo);
      final map = <String, _ModelAgg>{};
      for (final m in lines) {
        if (!validBills.contains(m.bill)) continue;
        final uuid = m.model?.uuid ?? '';
        final key = uuid.isNotEmpty ? 'u:$uuid' : 'id:${m.modelId}';
        final name = m.modelName.isNotEmpty
            ? m.modelName
            : 'موديل #${m.modelId}';
        final agg = map.putIfAbsent(key, () => _ModelAgg(name));
        if (agg.name.startsWith('موديل #') && m.modelName.isNotEmpty) {
          agg.name = m.modelName;
        }
        agg.salesCount++;
        agg.quantity += m.type == SellType.set
            ? m.setNumber.toDouble()
            : m.count;
        if (billCurrency[m.bill] == Currency.usd) {
          agg.amountUsd += m.totalPrice;
        } else {
          agg.amountIqd += m.totalPrice;
        }
      }

      blocks.add(
        _Block(
          heading: 'معرض: ${showLabel(belongTo)}',
          kpis: kpis,
          models: _shapeModels(map),
        ),
      );
    }

    // Overall summary on top.
    final overall = _Block(
      heading: 'إجمالي كل المعارض',
      kpis: [
        _StatRow('عدد الوصولات', '${filtered.length}'),
        _StatRow('الطلب (دينار)', PriceUtils.addCommas(oIqdTotal)),
        _StatRow('الخصم (دينار)', PriceUtils.addCommas(oIqdDisc)),
        _StatRow(
          'بعد الخصم (دينار)',
          PriceUtils.addCommas(oIqdTotal - oIqdDisc),
        ),
        _StatRow('الطلب (دولار)', PriceUtils.addCommas(oUsdTotal)),
        _StatRow('الخصم (دولار)', PriceUtils.addCommas(oUsdDisc)),
        _StatRow(
          'بعد الخصم (دولار)',
          PriceUtils.addCommas(oUsdTotal - oUsdDisc),
        ),
      ],
    );

    return _Report([overall, ...blocks]);
  }

  Future<_Report> _computeSupplies(DateTime? from, DateTime? to) async {
    final state = context.read<SuppliesCubit>().state;
    final filtered = state.supplies
        .where((s) => _inRange(s.date, from, to))
        .toList();

    int sumT(Iterable<Supply> l) => l.fold<int>(0, (a, s) => a + s.tPrice);
    int sumP(Iterable<Supply> l) => l.fold<int>(0, (a, s) => a + s.pPrice);
    int sumR(Iterable<Supply> l) => l.fold<int>(0, (a, s) => a + s.remaining);

    List<_StatRow> kpisFor(Iterable<Supply> l, {bool withCount = true}) {
      return [
        if (withCount) _StatRow('عدد السجلات', '${l.length}'),
        _StatRow('الطلب', PriceUtils.addCommas(sumT(l))),
        _StatRow('المدفوع', PriceUtils.addCommas(sumP(l))),
        _StatRow('المتبقي', PriceUtils.addCommas(sumR(l))),
      ];
    }

    final blocks = <_Block>[
      _Block(heading: 'ملخص المواد الأولية', kpis: kpisFor(filtered)),
    ];

    // Per-type breakdown.
    for (final type in SupplyType.values) {
      final ofType = filtered.where((s) => s.type == type).toList();
      if (ofType.isEmpty) continue;
      blocks.add(
        _Block(
          heading: type.toDisplayString(),
          kpis: [
            _StatRow('عدد السجلات', '${ofType.length}'),
            ...kpisFor(ofType, withCount: false),
          ],
        ),
      );
    }

    return _Report(blocks);
  }

  Future<_Report> _computeDebts(DateTime? from, DateTime? to) async {
    final state = context.read<DebtsCubit>().state;
    final filtered = state.debts
        .where((d) => _inRange(d.debtDate, from, to))
        .toList();
    final iqd = filtered.where((d) => d.currency != Currency.usd);
    final usd = filtered.where((d) => d.currency == Currency.usd);

    int sum(Iterable<CustomerDebt> l, int Function(CustomerDebt) f) =>
        l.fold<int>(0, (a, d) => a + f(d));

    // Detail listing (respects the "غير المسددين فقط" toggle), sorted by the
    // largest remaining first.
    final listed =
        (_unpaidOnly
                ? filtered.where((d) => state.remainingOf(d) > 0)
                : filtered)
            .toList()
          ..sort(
            (a, b) => state.remainingOf(b).compareTo(state.remainingOf(a)),
          );

    final detail = _DetailTable(
      headers: const [
        'الاسم',
        'الطلب',
        'المدفوع',
        'المتبقي',
        'العملة',
        'التاريخ',
      ],
      rows: [
        for (final d in listed)
          [
            d.debtorName,
            PriceUtils.addCommas(d.finalPrice),
            PriceUtils.addCommas(state.paidOf(d)),
            PriceUtils.addCommas(state.remainingOf(d)),
            d.currency == Currency.usd ? 'دولار' : 'دينار',
            _fmtDate(d.debtDate),
          ],
      ],
    );

    return _Report([
      _Block(
        heading: 'الديون (لنا على الزبائن)',
        kpis: [
          _StatRow('عدد الديون', '${filtered.length}'),
          _StatRow(
            'إجمالي الديون (دينار)',
            PriceUtils.addCommas(sum(iqd, (d) => d.finalPrice)),
          ),
          _StatRow(
            'المدفوع (دينار)',
            PriceUtils.addCommas(sum(iqd, (d) => state.paidOf(d))),
          ),
          _StatRow(
            'المتبقي (دينار)',
            PriceUtils.addCommas(sum(iqd, (d) => state.remainingOf(d))),
          ),
          _StatRow(
            'إجمالي الديون (دولار)',
            PriceUtils.addCommas(sum(usd, (d) => d.finalPrice)),
          ),
          _StatRow(
            'المدفوع (دولار)',
            PriceUtils.addCommas(sum(usd, (d) => state.paidOf(d))),
          ),
          _StatRow(
            'المتبقي (دولار)',
            PriceUtils.addCommas(sum(usd, (d) => state.remainingOf(d))),
          ),
        ],
      ),
      _Block(
        heading: _unpaidOnly ? 'قائمة غير المسددين' : 'قائمة الديون',
        kpis: [_StatRow('عدد المعروضين', '${listed.length}')],
        detail: detail,
      ),
    ]);
  }

  Future<_Report> _computeOnUsDebts(DateTime? from, DateTime? to) async {
    final state = context.read<OnUsDebtsCubit>().state;
    final filtered = state.debts
        .where((d) => _inRange(d.date, from, to))
        .toList();
    final iqd = filtered.where((d) => d.currency != Currency.usd);
    final usd = filtered.where((d) => d.currency == Currency.usd);

    int sum(Iterable<OnUsDebt> l, int Function(OnUsDebt) f) =>
        l.fold<int>(0, (a, d) => a + f(d));

    final listed =
        (_unpaidOnly
                ? filtered.where((d) => state.remainingOf(d) > 0)
                : filtered)
            .toList()
          ..sort(
            (a, b) => state.remainingOf(b).compareTo(state.remainingOf(a)),
          );

    final detail = _DetailTable(
      headers: const [
        'الاسم',
        'الطلب',
        'المدفوع',
        'المتبقي',
        'العملة',
        'التاريخ',
      ],
      rows: [
        for (final d in listed)
          [
            d.name,
            PriceUtils.addCommas(state.totalOf(d)),
            PriceUtils.addCommas(state.paidOf(d)),
            PriceUtils.addCommas(state.remainingOf(d)),
            d.currency == Currency.usd ? 'دولار' : 'دينار',
            _fmtDate(d.date),
          ],
      ],
    );

    return _Report([
      _Block(
        heading: 'ديون علينا',
        kpis: [
          _StatRow('عدد الديون', '${filtered.length}'),
          _StatRow(
            'إجمالي الديون (دينار)',
            PriceUtils.addCommas(sum(iqd, (d) => state.totalOf(d))),
          ),
          _StatRow(
            'المدفوع (دينار)',
            PriceUtils.addCommas(sum(iqd, (d) => state.paidOf(d))),
          ),
          _StatRow(
            'المتبقي (دينار)',
            PriceUtils.addCommas(sum(iqd, (d) => state.remainingOf(d))),
          ),
          _StatRow(
            'إجمالي الديون (دولار)',
            PriceUtils.addCommas(sum(usd, (d) => state.totalOf(d))),
          ),
          _StatRow(
            'المدفوع (دولار)',
            PriceUtils.addCommas(sum(usd, (d) => state.paidOf(d))),
          ),
          _StatRow(
            'المتبقي (دولار)',
            PriceUtils.addCommas(sum(usd, (d) => state.remainingOf(d))),
          ),
        ],
      ),
      _Block(
        heading: _unpaidOnly ? 'قائمة غير المسددين' : 'قائمة الديون',
        kpis: [_StatRow('عدد المعروضين', '${listed.length}')],
        detail: detail,
      ),
    ]);
  }

  Future<_Report> _computeTransport(DateTime? from, DateTime? to) async {
    final all = await TransportRepository().getAll();
    final filtered = all.where((t) => _inRange(t.date, from, to)).toList();
    final total = filtered.fold<int>(0, (a, t) => a + t.price);

    return _Report([
      _Block(
        heading: 'النقل',
        kpis: [
          _StatRow('عدد السجلات', '${filtered.length}'),
          _StatRow('إجمالي تكاليف النقل', PriceUtils.addCommas(total)),
        ],
      ),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Rendering
// ---------------------------------------------------------------------------

class _BlockCard extends StatelessWidget {
  final _Block block;
  const _BlockCard({required this.block});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (block.heading != null) ...[
              Text(
                block.heading!,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _kAccent,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (block.kpis.isNotEmpty) _kpiTable(block.kpis),
            if (block.kpis.isNotEmpty && block.models.isNotEmpty)
              const SizedBox(height: 12),
            if (block.models.isNotEmpty) _modelTable(block.models),
            if (block.detail != null) ...[
              if (block.kpis.isNotEmpty || block.models.isNotEmpty)
                const SizedBox(height: 12),
              block.detail!.rows.isEmpty
                  ? const Text('لا توجد سجلات')
                  : _detailTable(block.detail!),
            ],
            if (block.kpis.isEmpty &&
                block.models.isEmpty &&
                block.detail == null)
              const Text('لا توجد بيانات'),
          ],
        ),
      ),
    );
  }

  Widget _kpiTable(List<_StatRow> rows) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
      children: [
        for (final r in rows)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Text(r.label),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Text(
                  r.value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _modelTable(List<_ModelRow> rows) {
    final showIqd = rows.any((m) => m.amountIqd != 0);
    final showUsd = rows.any((m) => m.amountUsd != 0);

    TableCell cell(String text, {bool header = false, bool bold = false}) =>
        TableCell(
          child: Container(
            color: header ? _kAccent : null,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              text,
              style: TextStyle(
                color: header ? Colors.white : null,
                fontWeight: (header || bold)
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        );

    final columnWidths = <int, TableColumnWidth>{
      0: const FlexColumnWidth(2.2),
      1: const FlexColumnWidth(1.1),
      2: const FlexColumnWidth(1),
    };
    var idx = 3;
    if (showIqd) columnWidths[idx++] = const FlexColumnWidth(1.4);
    if (showUsd) columnWidths[idx++] = const FlexColumnWidth(1.4);

    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: columnWidths,
      children: [
        TableRow(
          children: [
            cell('الموديل', header: true),
            cell('عدد المبيعات', header: true),
            cell('الكمية', header: true),
            if (showIqd) cell('المبلغ (دينار)', header: true),
            if (showUsd) cell('المبلغ (دولار)', header: true),
          ],
        ),
        for (final m in rows)
          TableRow(
            children: [
              cell(m.model, bold: true),
              cell('${m.salesCount}'),
              cell(_fmtQty(m.quantity)),
              if (showIqd) cell(PriceUtils.addCommas(m.amountIqd)),
              if (showUsd) cell(PriceUtils.addCommas(m.amountUsd)),
            ],
          ),
      ],
    );
  }

  Widget _detailTable(_DetailTable table) {
    TableCell cell(String text, {bool header = false}) => TableCell(
      child: Container(
        color: header ? _kAccent : null,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Text(
          text,
          style: TextStyle(
            color: header ? Colors.white : null,
            fontWeight: header ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );

    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: {
        for (var i = 0; i < table.headers.length; i++)
          i: i == 0 ? const FlexColumnWidth(2) : const FlexColumnWidth(1),
      },
      children: [
        TableRow(
          children: [for (final h in table.headers) cell(h, header: true)],
        ),
        for (final row in table.rows)
          TableRow(children: [for (final c in row) cell(c)]),
      ],
    );
  }
}

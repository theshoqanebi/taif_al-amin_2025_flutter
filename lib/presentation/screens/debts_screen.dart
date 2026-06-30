import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xlsx;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shtable/shtable.dart';
import 'package:taif_alamin/app_window.dart';
import 'package:taif_alamin/data/models/customer_debt_model.dart';
import 'package:taif_alamin/presentation/cubits/debts_cubit/debts_cubit.dart';
import 'package:taif_alamin/presentation/dialogs/debt_payments_dialog.dart';
import 'package:taif_alamin/utils/price_utils.dart';
import 'package:taif_alamin/utils/snack_bar_util.dart';
import 'package:taif_alamin/widgets/general/app_input.dart';

const _kAccent = Color(0xFF003763);

/// Customer debts list. Each row opens its payments dialog.
class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  final searchController = TextEditingController();
  final SHTableController tableController = SHTableController();

  /// 0 = all, 1 = unpaid only, 2 = paid only
  int filter = 0;

  @override
  void initState() {
    super.initState();
    context.read<DebtsCubit>().loadAll();
  }

  @override
  void dispose() {
    searchController.dispose();
    tableController.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  final List<SHColumn> _columns = [
    SHColumn(id: 'id', title: 'id', weight: 1, hidden: true),
    SHColumn(id: 'name', title: 'الاسم', weight: 3),
    SHColumn(id: 'bill', title: 'الوصل', weight: 2),
    SHColumn(id: 'date', title: 'التاريخ', weight: 2),
    SHColumn(id: 'total', title: 'الكلي', weight: 2, isNumeric: true, priceFormat: true),
    SHColumn(id: 'discount', title: 'الخصم', weight: 2, isNumeric: true, priceFormat: true),
    SHColumn(id: 'final', title: 'النهائي', weight: 2, isNumeric: true, priceFormat: true),
    SHColumn(id: 'paid', title: 'المدفوع', weight: 2, isNumeric: true, priceFormat: true),
    SHColumn(id: 'remaining', title: 'المتبقي', weight: 2, isNumeric: true, priceFormat: true),
    SHColumn(id: 'currency', title: 'العملة', weight: 1),
  ];

  List<CustomerDebt> _visible(DebtsState state) {
    final q = searchController.text.trim();
    return state.debts.where((d) {
      if (q.isNotEmpty &&
          !d.debtorName.contains(q) &&
          !(d.bill ?? '').contains(q)) {
        return false;
      }
      final remaining = state.remainingOf(d);
      if (filter == 1 && remaining <= 0) return false; // unpaid only
      if (filter == 2 && remaining > 0) return false; // paid only
      return true;
    }).toList();
  }

  List<Map<String, String>> _rows(DebtsState state, List<CustomerDebt> ds) =>
      ds
          .map(
            (d) => {
              'id': d.id.toString(),
              'name': d.debtorName,
              'bill': d.bill ?? '',
              'date': _fmt(d.debtDate),
              'total': state.totalOf(d).toString(),
              'discount': d.discount.toString(),
              'final': state.finalOf(d).toString(),
              'paid': state.paidOf(d).toString(),
              'remaining': state.remainingOf(d).toString(),
              'currency': d.currency.toDisplayString(),
            },
          )
          .toList();

  void _openSelected(DebtsState state) {
    final sel = tableController.selectedIndexes;
    if (sel.isEmpty || sel.length > 1) {
      SnackBarUtil.showError(context, 'اختر ديناً واحداً لإدارة دفعاته');
      return;
    }
    final visible = _visible(state);
    final idx = sel.first;
    if (idx < visible.length) _openPayments(visible[idx]);
  }

  void _openPayments(CustomerDebt debt) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<DebtsCubit>(),
        child: DebtPaymentsDialog(debt: debt),
      ),
    );
  }

  Future<void> _exportToExcel() async {
    final result = await getSaveLocation(
      suggestedName: 'debts_${DateTime.now().year}-${DateTime.now().month}.xlsx',
      acceptedTypeGroups: [
        const XTypeGroup(label: 'Excel', extensions: ['xlsx']),
      ],
    );
    if (result == null || !mounted) return;
    try {
      final state = context.read<DebtsCubit>().state;
      final rows = _rows(state, _visible(state));
      final excel = xlsx.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow([
        xlsx.TextCellValue('الاسم'),
        xlsx.TextCellValue('الوصل'),
        xlsx.TextCellValue('التاريخ'),
        xlsx.TextCellValue('الكلي'),
        xlsx.TextCellValue('الخصم'),
        xlsx.TextCellValue('النهائي'),
        xlsx.TextCellValue('المدفوع'),
        xlsx.TextCellValue('المتبقي'),
        xlsx.TextCellValue('العملة'),
      ]);
      for (final r in rows) {
        sheet.appendRow([
          xlsx.TextCellValue(r['name'] ?? ''),
          xlsx.TextCellValue(r['bill'] ?? ''),
          xlsx.TextCellValue(r['date'] ?? ''),
          xlsx.TextCellValue(r['total'] ?? ''),
          xlsx.TextCellValue(r['discount'] ?? ''),
          xlsx.TextCellValue(r['final'] ?? ''),
          xlsx.TextCellValue(r['paid'] ?? ''),
          xlsx.TextCellValue(r['remaining'] ?? ''),
          xlsx.TextCellValue(r['currency'] ?? ''),
        ]);
      }
      final bytes = excel.encode();
      if (bytes == null) throw Exception('encode failed');
      await File(result.path).writeAsBytes(Uint8List.fromList(bytes));
      if (mounted) {
        SnackBarUtil.showSuccess(context, 'تم التصدير إلى ${result.path}');
      }
    } catch (e) {
      if (mounted) SnackBarUtil.showError(context, 'خطأ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppWindow(
      showBack: true,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: BlocConsumer<DebtsCubit, DebtsState>(
            listener: (context, state) {
              if (state.hasError) {
                SnackBarUtil.showError(context, state.error ?? 'حدث خطأ');
              }
            },
            builder: (context, state) {
              final visible = _visible(state);
              final remIqd = visible
                  .where((d) => d.currency.name != 'usd')
                  .fold<int>(0, (s, d) => s + state.remainingOf(d));
              final remUsd = visible
                  .where((d) => d.currency.name == 'usd')
                  .fold<int>(0, (s, d) => s + state.remainingOf(d));

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Column(
                  spacing: 12,
                  children: [
                    Row(
                      children: const [
                        Text(
                          'الديون',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _kAccent,
                          ),
                        ),
                      ],
                    ),

                    Row(
                      spacing: 12,
                      children: [
                        Expanded(
                          child: AppInput(
                            title: 'بحث بالاسم أو الوصل',
                            controller: searchController,
                            onChanged: (_) {
                              if (mounted) setState(() {});
                            },
                            suffixIcon: const Icon(Icons.search, color: _kAccent),
                          ),
                        ),
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 0, label: Text('الكل')),
                            ButtonSegment(value: 1, label: Text('غير مسدد')),
                            ButtonSegment(value: 2, label: Text('مسدد')),
                          ],
                          selected: {filter},
                          onSelectionChanged: (s) =>
                              setState(() => filter = s.first),
                        ),
                      ],
                    ),

                    if (state.isLoading)
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      Expanded(
                        child: SHTable(
                          controller: tableController,
                          direction: TextDirection.rtl,
                          hasIndex: true,
                          indexLabel: 'ت',
                          pagination: true,
                          columns: _columns,
                          rows: _rows(state, visible),
                        ),
                      ),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(label: 'عدد الديون', value: '${visible.length}'),
                          _StatItem(
                            label: 'المتبقي (دينار)',
                            value: PriceUtils.addCommas(remIqd),
                          ),
                          _StatItem(
                            label: 'المتبقي (دولار)',
                            value: '\$${PriceUtils.addCommas(remUsd)}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          persistentFooterButtons: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('رجوع'),
                ),
                Row(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _exportToExcel,
                      icon: const Icon(Icons.file_download),
                      label: const Text('تصدير Excel'),
                    ),
                    Builder(
                      builder: (ctx) => FilledButton.icon(
                        onPressed: () =>
                            _openSelected(ctx.read<DebtsCubit>().state),
                        icon: const Icon(Icons.payments),
                        label: const Text('إدارة الدفعات'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

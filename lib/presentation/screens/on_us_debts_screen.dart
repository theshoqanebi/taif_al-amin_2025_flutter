import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xlsx;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shtable/shtable.dart';
import 'package:taif_alamin/app_window.dart';
import 'package:taif_alamin/data/constants/currency.dart';
import 'package:taif_alamin/data/models/on_us_debt_model.dart';
import 'package:taif_alamin/presentation/cubits/on_us_debts_cubit/on_us_debts_cubit.dart';
import 'package:taif_alamin/presentation/dialogs/on_us_payments_dialog.dart';
import 'package:taif_alamin/utils/price_utils.dart';
import 'package:taif_alamin/utils/snack_bar_util.dart';
import 'package:taif_alamin/widgets/app_primary_button.dart';
import 'package:taif_alamin/widgets/general/app_input.dart';

const _kAccent = Color(0xFF003763);

/// "ديون علينا" — debts the business itself owes to someone else.
/// Completely separate from [DebtsScreen] (money customers owe the
/// business): there's no Sell/Exhibition to auto-create these, so this
/// screen owns full create/edit/delete on the debt header itself, plus
/// payments management via [OnUsPaymentsDialog].
class OnUsDebtsScreen extends StatefulWidget {
  const OnUsDebtsScreen({super.key});

  @override
  State<OnUsDebtsScreen> createState() => _OnUsDebtsScreenState();
}

class _OnUsDebtsScreenState extends State<OnUsDebtsScreen> {
  final nameController = TextEditingController();
  final billController = TextEditingController();
  final dateController = TextEditingController();
  final priceController = TextEditingController();
  final notesController = TextEditingController();
  final searchController = TextEditingController();
  final SHTableController tableController = SHTableController();

  DateTime selectedDate = DateTime.now();
  Currency currency = Currency.iqd;
  int? editingId;

  /// 0 = all, 1 = unpaid only, 2 = paid only
  int filter = 0;

  @override
  void initState() {
    super.initState();
    dateController.text = _fmt(selectedDate);
    context.read<OnUsDebtsCubit>().loadAll();
  }

  @override
  void dispose() {
    nameController.dispose();
    billController.dispose();
    dateController.dispose();
    priceController.dispose();
    notesController.dispose();
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
    SHColumn(
      id: 'total',
      title: 'الكلي',
      weight: 2,
      isNumeric: true,
      priceFormat: true,
    ),
    SHColumn(
      id: 'paid',
      title: 'المدفوع',
      weight: 2,
      isNumeric: true,
      priceFormat: true,
    ),
    SHColumn(
      id: 'remaining',
      title: 'المتبقي',
      weight: 2,
      isNumeric: true,
      priceFormat: true,
    ),
    SHColumn(id: 'currency', title: 'العملة', weight: 1),
    SHColumn(id: 'notes', title: 'الملاحظات', weight: 3),
  ];

  List<OnUsDebt> _visible(OnUsDebtsState state) {
    final q = searchController.text.trim();
    return state.debts.where((d) {
      if (q.isNotEmpty && !d.name.contains(q) && !(d.bill ?? '').contains(q)) {
        return false;
      }
      final remaining = state.remainingOf(d);
      if (filter == 1 && remaining <= 0) return false; // unpaid only
      if (filter == 2 && remaining > 0) return false; // paid only
      return true;
    }).toList();
  }

  List<Map<String, String>> _rows(OnUsDebtsState state, List<OnUsDebt> ds) =>
      ds
          .map(
            (d) => {
              'id': d.id.toString(),
              'name': d.name,
              'bill': d.bill ?? '',
              'date': _fmt(d.date),
              'total': state.totalOf(d).toString(),
              'paid': state.paidOf(d).toString(),
              'remaining': state.remainingOf(d).toString(),
              'currency': d.currency.toDisplayString(),
              'notes': d.notes ?? '',
            },
          )
          .toList();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateController.text = _fmt(picked);
      });
    }
  }

  void _save() {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      SnackBarUtil.showError(context, 'أدخل الاسم');
      return;
    }
    final price =
        int.tryParse(priceController.text.replaceAll(',', '').trim()) ?? 0;
    if (price <= 0) {
      SnackBarUtil.showError(context, 'أدخل المبلغ');
      return;
    }
    final debt = OnUsDebt(
      id: editingId ?? 0,
      name: name,
      date: selectedDate,
      bill: billController.text.trim().isEmpty
          ? null
          : billController.text.trim(),
      tPrice: price,
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      currency: currency,
    );
    final cubit = context.read<OnUsDebtsCubit>();
    if (editingId != null) {
      cubit.update(debt);
    } else {
      cubit.add(debt);
    }
    _clearForm();
  }

  void _clearForm() {
    nameController.clear();
    billController.clear();
    priceController.clear();
    notesController.clear();
    selectedDate = DateTime.now();
    dateController.text = _fmt(selectedDate);
    currency = Currency.iqd;
    editingId = null;
    if (mounted) setState(() {});
  }

  void _handleEdit(OnUsDebtsState state) {
    final selected = tableController.selectedIndexes;
    if (selected.isEmpty) {
      SnackBarUtil.showError(context, 'اختر ديناً واحداً للتعديل');
      return;
    }
    if (selected.length > 1) {
      SnackBarUtil.showError(context, 'حدد ديناً واحداً فقط');
      return;
    }
    final visible = _visible(state);
    final idx = selected.first;
    if (idx >= visible.length) return;
    final d = visible[idx];
    setState(() {
      editingId = d.id;
      nameController.text = d.name;
      billController.text = d.bill ?? '';
      selectedDate = d.date;
      dateController.text = _fmt(d.date);
      priceController.text = d.tPrice.toString();
      notesController.text = d.notes ?? '';
      currency = d.currency;
    });
  }

  void _handleDelete(OnUsDebtsState state) {
    final selected = tableController.selectedIndexes;
    if (selected.isEmpty) {
      SnackBarUtil.showError(context, 'اختر ديناً واحداً على الأقل');
      return;
    }
    final cubit = context.read<OnUsDebtsCubit>();
    final visible = _visible(state);
    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text(
            'سيتم حذف ${selected.length} دين وما يرتبط به من دفعات، تأكيد؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                for (final idx in selected) {
                  if (idx < visible.length) cubit.delete(visible[idx].id);
                }
                tableController.clearSelection();
              },
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }

  void _openSelected(OnUsDebtsState state) {
    final sel = tableController.selectedIndexes;
    if (sel.isEmpty || sel.length > 1) {
      SnackBarUtil.showError(context, 'اختر ديناً واحداً لإدارة دفعاته');
      return;
    }
    final visible = _visible(state);
    final idx = sel.first;
    if (idx < visible.length) _openPayments(visible[idx]);
  }

  void _openPayments(OnUsDebt debt) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<OnUsDebtsCubit>(),
        child: OnUsPaymentsDialog(debt: debt),
      ),
    );
  }

  Future<void> _exportToExcel(OnUsDebtsState state) async {
    final result = await getSaveLocation(
      suggestedName:
          'on_us_debts_${DateTime.now().year}-${DateTime.now().month}.xlsx',
      acceptedTypeGroups: [
        const XTypeGroup(label: 'Excel', extensions: ['xlsx']),
      ],
    );
    if (result == null || !mounted) return;
    try {
      final rows = _rows(state, _visible(state));
      final excel = xlsx.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow([
        xlsx.TextCellValue('الاسم'),
        xlsx.TextCellValue('الوصل'),
        xlsx.TextCellValue('التاريخ'),
        xlsx.TextCellValue('الكلي'),
        xlsx.TextCellValue('المدفوع'),
        xlsx.TextCellValue('المتبقي'),
        xlsx.TextCellValue('العملة'),
        xlsx.TextCellValue('الملاحظات'),
      ]);
      for (final r in rows) {
        sheet.appendRow([
          xlsx.TextCellValue(r['name'] ?? ''),
          xlsx.TextCellValue(r['bill'] ?? ''),
          xlsx.TextCellValue(r['date'] ?? ''),
          xlsx.TextCellValue(r['total'] ?? ''),
          xlsx.TextCellValue(r['paid'] ?? ''),
          xlsx.TextCellValue(r['remaining'] ?? ''),
          xlsx.TextCellValue(r['currency'] ?? ''),
          xlsx.TextCellValue(r['notes'] ?? ''),
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
          body: BlocConsumer<OnUsDebtsCubit, OnUsDebtsState>(
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
                          'ديون علينا',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _kAccent,
                          ),
                        ),
                      ],
                    ),

                    // ---- Create / edit form ----
                    Row(
                      spacing: 12,
                      children: [
                        Expanded(
                          flex: 2,
                          child: AppInput(
                            title: 'الاسم',
                            controller: nameController,
                          ),
                        ),
                        Expanded(
                          child: AppInput(
                            title: 'الوصل',
                            controller: billController,
                          ),
                        ),
                        Expanded(
                          child: AppInput(
                            title: 'التاريخ',
                            controller: dateController,
                            isDatePicker: true,
                            isDate: true,
                            onTap: _pickDate,
                            direction: TextDirection.ltr,
                          ),
                        ),
                        Expanded(
                          child: AppInput(
                            title: 'المبلغ',
                            controller: priceController,
                            isPrice: true,
                            inputType: TextInputType.number,
                            direction: TextDirection.ltr,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 12,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<Currency>(
                            initialValue: currency,
                            decoration: const InputDecoration(
                              labelText: 'العملة',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: Currency.iqd,
                                child: Text('دينار'),
                              ),
                              DropdownMenuItem(
                                value: Currency.usd,
                                child: Text('دولار'),
                              ),
                            ],
                            onChanged: (c) =>
                                setState(() => currency = c ?? Currency.iqd),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: AppInput(
                            title: 'ملاحظات',
                            controller: notesController,
                          ),
                        ),
                        AppPrimaryButton(
                          text: editingId != null ? 'تعديل' : 'إضافة',
                          onPressed: _save,
                        ),
                        if (editingId != null)
                          OutlinedButton(
                            onPressed: _clearForm,
                            child: const Text('إلغاء'),
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
                            suffixIcon: const Icon(
                              Icons.search,
                              color: _kAccent,
                            ),
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
                          _StatItem(
                            label: 'عدد الديون',
                            value: '${visible.length}',
                          ),
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
            Builder(
              builder: (ctx) {
                final state = ctx.watch<OnUsDebtsCubit>().state;
                return Row(
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
                          onPressed: () => _handleEdit(state),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('تعديل'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _handleDelete(state),
                          icon: const Icon(
                            Icons.delete,
                            size: 18,
                            color: Colors.red,
                          ),
                          label: const Text('حذف'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _exportToExcel(state),
                          icon: const Icon(Icons.file_download),
                          label: const Text('تصدير Excel'),
                        ),
                        FilledButton.icon(
                          onPressed: () => _openSelected(state),
                          icon: const Icon(Icons.payments),
                          label: const Text('إدارة الدفعات'),
                        ),
                      ],
                    ),
                  ],
                );
              },
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

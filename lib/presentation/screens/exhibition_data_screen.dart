import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:excel/excel.dart' as xlsx;
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shtable/shtable.dart';
import 'package:taif_alamin/app_window.dart';
import 'package:taif_alamin/core/bill/make_exhibition_bill.dart';
import 'package:taif_alamin/data/constants/currency.dart';
import 'package:taif_alamin/data/constants/edit_messages.dart';
import 'package:taif_alamin/data/constants/templates.dart';
import 'package:taif_alamin/data/models/exhibition_model.dart';
import 'package:taif_alamin/data/repositories/exhibitions_payments_repository.dart';
import 'package:taif_alamin/presentation/cubits/exhibitions_cubit/exhibitions_cubit.dart';
import 'package:taif_alamin/presentation/cubits/exhibitions_cubit/exhibitions_state.dart';
import 'package:taif_alamin/presentation/cubits/exhibitions_models_cubit/exhibitions_models_cubit.dart';
import 'package:taif_alamin/presentation/cubits/exhibitions_payments/exhibitions_payments_cubit.dart';
import 'package:taif_alamin/presentation/dialogs/exhibition_additional_amounts_dialog.dart';
import 'package:taif_alamin/presentation/dialogs/exhibition_multi_sells_dialog.dart';
import 'package:taif_alamin/presentation/screens/exhibitions_models_screen.dart';
import 'package:taif_alamin/presentation/screens/exhibitions_payments_screen.dart';
import 'package:taif_alamin/utils/docx_utils.dart';
import 'package:taif_alamin/utils/price_utils.dart';
import 'package:taif_alamin/utils/print_server.dart';
import 'package:taif_alamin/utils/snack_bar_util.dart';
import 'package:taif_alamin/utils/uuid_utils.dart';
import 'package:taif_alamin/widgets/app_primary_button.dart';
import 'package:taif_alamin/widgets/general/app_action_buttons.dart';
import 'package:taif_alamin/widgets/general/app_input.dart';

const _kAccent = Color(0xFF003763);

/// Invoices of one exhibition/showroom ([belongTo]). Mirrors the sales screen.
class ExhibitionDataScreen extends StatefulWidget {
  final String belongTo;
  final String title;

  const ExhibitionDataScreen({
    super.key,
    required this.belongTo,
    required this.title,
  });

  @override
  State<ExhibitionDataScreen> createState() => _ExhibitionDataScreenState();
}

class _ExhibitionDataScreenState extends State<ExhibitionDataScreen> {
  final billController = TextEditingController();
  final dateController = TextEditingController();
  final discountController = TextEditingController();
  final discountDetailsController = TextEditingController();
  final notesController = TextEditingController();
  final searchController = TextEditingController();
  final exchangeRateController = TextEditingController();
  final SHTableController tableController = SHTableController();
  final ExhibitionsPaymentsRepository _paymentsRepo =
      ExhibitionsPaymentsRepository();

  int? editingId;
  DateTime selectedDate = DateTime.now();
  Currency currency = Currency.iqd;
  // مجموع الدفعات لهذا المعرض (belongTo) — يُحدّث بعد كل تغيير على الدفعات.
  int totalPaid = 0;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<ExhibitionsCubit>();
    cubit.loadByBelongTo(widget.belongTo);
    cubit.clearDraft();
    context.read<ExhibitionsModelsCubit>().loadModels(
      belongTo: widget.belongTo,
    );
    dateController.text = _formatDate(selectedDate);
    _prefillBillNumber();
    _loadTotalPaid();
  }

  Future<void> _loadTotalPaid() async {
    final total = await _paymentsRepo.getTotalByBelongTo(widget.belongTo);
    if (mounted) setState(() => totalPaid = total);
  }

  @override
  void dispose() {
    billController.dispose();
    dateController.dispose();
    discountController.dispose();
    discountDetailsController.dispose();
    notesController.dispose();
    searchController.dispose();
    exchangeRateController.dispose();
    tableController.dispose();
    super.dispose();
  }

  Future<void> _prefillBillNumber() async {
    final next = await context.read<ExhibitionsCubit>().nextBillNumber();
    if (mounted) billController.text = next.toString();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------------------
  // Columns — base set always shown; the IQD/rate column is added dynamically
  // when any visible exhibition is IQD with an exchange rate.
  // ---------------------------------------------------------------------------

  static const _baseColumns = [
    SHColumn(id: 'id', title: 'id', weight: 1, hidden: true),
    SHColumn(id: 'bill', title: 'الوصل', weight: 2, isNumeric: true),
    SHColumn(id: 'date', title: 'التاريخ', weight: 2),
    SHColumn(
      id: 'total',
      title: 'الكلي',
      weight: 2,
      isNumeric: true,
      priceFormat: true,
    ),
    SHColumn(
      id: 'discount',
      title: 'الخصم',
      weight: 2,
      isNumeric: true,
      priceFormat: true,
    ),
    SHColumn(
      id: 'final',
      title: 'النهائي',
      weight: 2,
      isNumeric: true,
      priceFormat: true,
    ),
    SHColumn(id: 'currency', title: 'العملة', weight: 1),
    SHColumn(
      id: 'rate',
      title: 'سعر الصرف',
      weight: 2,
      isNumeric: true,
      priceFormat: true,
    ),
    SHColumn(id: 'notes', title: 'الملاحظات', weight: 3),
  ];

  static const _iqdRateColumn = SHColumn(
    id: 'iqd_as_usd',
    title: 'النهائي \$ (بالصرف)',
    weight: 2,
    isNumeric: true,
    priceFormat: true,
  );

  /// Returns true if any exhibition in [items] is IQD with exchange rate.
  bool _hasIqdWithRate(List<Exhibition> items) =>
      items.any((e) => e.currency == Currency.iqd && (e.exchangeRate ?? 0) > 0);

  List<SHColumn> _buildColumns(List<Exhibition> items) {
    if (!_hasIqdWithRate(items)) return _baseColumns;
    // Insert the extra column right after 'النهائي' (index 5), before 'العملة'.
    final cols = List<SHColumn>.from(_baseColumns);
    cols.insert(6, _iqdRateColumn);
    return cols;
  }

  // ---------------------------------------------------------------------------
  // Row builders
  // ---------------------------------------------------------------------------

  List<Map<String, String>> _toRows(
    List<Exhibition> items,
    ExhibitionsState state,
  ) {
    return items.map((e) {
      final asUsd = state.iqdAsUsd(e);
      return {
        'id': e.id.toString(),
        'bill': e.bill,
        'date': _formatDate(e.date),
        'total': state.totalOf(e).toString(),
        'discount': e.discount.toString(),
        'final': state.finalOf(e).toString(),
        'currency': e.currency.toDisplayString(),
        'rate': e.exchangeRate != null ? e.exchangeRate!.toString() : '',
        'iqd_as_usd': asUsd != null ? asUsd.toStringAsFixed(2) : '',
        'notes': e.notes ?? '',
      };
    }).toList();
  }

  List<Map<String, String>> _filteredRows(
    List<Exhibition> items,
    ExhibitionsState state,
  ) {
    final q = searchController.text.trim();
    if (q.isEmpty) return _toRows(items, state);
    final filtered = items.where(
      (e) => e.bill.contains(q) || (e.notes ?? '').contains(q),
    );
    return _toRows(filtered.toList(), state);
  }

  // ---------------------------------------------------------------------------
  // Date picker
  // ---------------------------------------------------------------------------

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateController.text = _formatDate(picked);
      });
    }
  }

  // ---------------------------------------------------------------------------
  // CRUD helpers
  // ---------------------------------------------------------------------------

  Exhibition _buildExhibition() {
    final discount =
        int.tryParse(discountController.text.replaceAll(',', '').trim()) ?? 0;
    final rate = double.tryParse(
      exchangeRateController.text.replaceAll(',', '').trim(),
    );
    return Exhibition(
      id: editingId ?? 0,
      bill: billController.text.trim(),
      date: selectedDate,
      discount: discount,
      discountDetails: discountDetailsController.text.trim().isEmpty
          ? null
          : discountDetailsController.text.trim(),
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      currency: currency,
      exchangeRate: rate,
      belongTo: widget.belongTo,
    );
  }

  Future<void> _save() async {
    if (billController.text.trim().isEmpty) {
      SnackBarUtil.showError(context, 'أدخل رقم الوصل');
      return;
    }
    if (currency == Currency.usd) {
      final rate = double.tryParse(
        exchangeRateController.text.replaceAll(',', '').trim(),
      );
      if (rate == null || rate <= 0) {
        SnackBarUtil.showError(context, 'أدخل سعر الصرف لهذا الوصل الدولاري');
        return;
      }
    }
    final cubit = context.read<ExhibitionsCubit>();
    if (cubit.state.draftMultiSells.isEmpty) {
      SnackBarUtil.showError(context, 'أضف عناصر المعرض أولاً');
      return;
    }
    final exhibition = _buildExhibition();
    if (editingId != null) {
      await cubit.updateExhibition(exhibition);
    } else {
      await cubit.createExhibition(exhibition);
    }
    if (!mounted) return;
    if (!cubit.state.hasError) {
      await _clearForm();
    }
  }

  Future<void> _clearForm() async {
    discountController.clear();
    discountDetailsController.clear();
    notesController.clear();
    exchangeRateController.clear();
    selectedDate = DateTime.now();
    dateController.text = _formatDate(selectedDate);
    currency = Currency.iqd;
    editingId = null;
    context.read<ExhibitionsCubit>().clearDraft();
    await _prefillBillNumber();
    if (mounted) setState(() {});
  }

  Future<void> _handleEdit() async {
    final selected = tableController.selectedIndexes;
    if (selected.isEmpty) {
      SnackBarUtil.showError(context, EditMessages.emptySelection);
      return;
    }
    if (selected.length > 1) {
      SnackBarUtil.showError(context, EditMessages.multipleSelection);
      return;
    }
    final cubit = context.read<ExhibitionsCubit>();
    final list = cubit.state.exhibitions;
    final idx = selected.first;
    if (idx >= list.length) return;
    final e = list[idx];
    setState(() {
      editingId = e.id;
      billController.text = e.bill;
      selectedDate = e.date;
      dateController.text = _formatDate(e.date);
      discountController.text = e.discount > 0 ? e.discount.toString() : '';
      discountDetailsController.text = e.discountDetails ?? '';
      notesController.text = e.notes ?? '';
      currency = e.currency;
      exchangeRateController.text = e.exchangeRate != null
          ? e.exchangeRate!.toString()
          : '';
    });
    await cubit.loadDraftFor(e.bill);
  }

  void _handleDelete() {
    final selected = tableController.selectedIndexes;
    if (selected.isEmpty) {
      SnackBarUtil.showError(context, 'اختر عنصراً واحداً على الأقل');
      return;
    }
    final cubit = context.read<ExhibitionsCubit>();
    final list = cubit.state.exhibitions;
    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('سيتم حذف ${selected.length} وصل، تأكيد؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                for (final idx in selected) {
                  if (idx < list.length) cubit.deleteExhibition(list[idx]);
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

  void _handleDuplicate() {
    SnackBarUtil.showError(context, 'النسخ غير مدعوم للمعارض');
  }

  void _openMultiSells() {
    final a = context.read<ExhibitionsCubit>();
    final b = context.read<ExhibitionsModelsCubit>();
    showDialog(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: a),
          BlocProvider.value(value: b),
        ],
        child: ExhibitionMultiSellsDialog(bill: billController.text.trim()),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _openModels() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<ExhibitionsModelsCubit>(),
              child: ExhibitionsModelsScreen(
                belongTo: widget.belongTo,
                title: widget.title,
              ),
            ),
          ),
        )
        .then((_) {
          if (!mounted) return;
          context.read<ExhibitionsModelsCubit>().loadModels(
            belongTo: widget.belongTo,
          );
        });
  }

  void _openPayments() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => ExhibitionsPaymentsCubit(),
              child: ExhibitionsPaymentScreen(
                belongTo: widget.belongTo,
                title: 'دفعات: ${widget.title}',
              ),
            ),
          ),
        )
        .then((_) {
          if (mounted) _loadTotalPaid();
        });
  }

  void _openAdditional() {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ExhibitionsCubit>(),
        child: ExhibitionAdditionalAmountsDialog(
          bill: billController.text.trim(),
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _exportToExcel() async {
    final result = await getSaveLocation(
      suggestedName:
          'exhibitions_${widget.belongTo}_${DateTime.now().year}-${DateTime.now().month}.xlsx',
      acceptedTypeGroups: [
        const XTypeGroup(label: 'Excel', extensions: ['xlsx']),
      ],
    );
    if (result == null || !mounted) return;
    try {
      final state = context.read<ExhibitionsCubit>().state;
      final rows = _toRows(state.exhibitions, state);
      final excel = xlsx.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow([
        xlsx.TextCellValue('الوصل'),
        xlsx.TextCellValue('التاريخ'),
        xlsx.TextCellValue('الكلي'),
        xlsx.TextCellValue('الخصم'),
        xlsx.TextCellValue('النهائي'),
        xlsx.TextCellValue('النهائي \$ (بالصرف)'),
        xlsx.TextCellValue('العملة'),
        xlsx.TextCellValue('سعر الصرف'),
        xlsx.TextCellValue('الملاحظات'),
      ]);
      for (final r in rows) {
        sheet.appendRow([
          xlsx.TextCellValue(r['bill'] ?? ''),
          xlsx.TextCellValue(r['date'] ?? ''),
          xlsx.TextCellValue(r['total'] ?? ''),
          xlsx.TextCellValue(r['discount'] ?? ''),
          xlsx.TextCellValue(r['final'] ?? ''),
          xlsx.TextCellValue(r['iqd_as_usd'] ?? ''),
          xlsx.TextCellValue(r['currency'] ?? ''),
          xlsx.TextCellValue(r['rate'] ?? ''),
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

  Future<void> _handlePrint() async {
    final selected = tableController.selectedIndexes;
    if (selected.isEmpty) {
      SnackBarUtil.showError(context, 'اختر وصلاً واحداً للطباعة');
      return;
    }
    if (selected.length > 1) {
      SnackBarUtil.showError(context, EditMessages.multipleSelection);
      return;
    }
    final cubit = context.read<ExhibitionsCubit>();
    final list = cubit.state.exhibitions;
    final idx = selected.first;
    if (idx >= list.length) return;
    final exhibition = list[idx];

    try {
      final docx = DocxUtils();
      docx.load(templatePath);

      final maker = MakeExhibitionBill(docx: docx);
      maker.fillBaseInfo(
        bill: exhibition.bill,
        showroomTitle: widget.title,
        currency: exhibition.currency,
        exchangeRate: exhibition.exchangeRate,
        notes: exhibition.notes,
        date: exhibition.date,
      );
      await maker.fillExhibitionData(exhibition);

      final tempDir = await getTemporaryDirectory();
      final printPath = p.join(
        tempDir.path,
        'print_bill_${UuidUtils.v4()}.docx',
      );
      maker.save(path: printPath);

      final pdfBytes = await PrintServer.convertToPdf(printPath);

      final result = await getSaveLocation(
        suggestedName: 'وصل_${exhibition.bill}.pdf',
        acceptedTypeGroups: [
          const XTypeGroup(label: 'PDF', extensions: ['pdf']),
        ],
      );
      if (result == null || !mounted) return;
      await File(result.path).writeAsBytes(pdfBytes);

      if (mounted) {
        SnackBarUtil.showSuccess(context, 'تم حفظ الوصل: ${result.path}');
      }
    } catch (e) {
      if (mounted) SnackBarUtil.showError(context, 'خطأ بالطباعة: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AppWindow(
      showBack: true,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: BlocConsumer<ExhibitionsCubit, ExhibitionsState>(
            listener: (context, state) {
              if (state.hasError) {
                SnackBarUtil.showError(context, state.error ?? 'حدث خطأ');
              }
            },
            builder: (context, state) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Column(
                  spacing: 12,
                  children: [
                    // title
                    Row(
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _kAccent,
                          ),
                        ),
                      ],
                    ),

                    // header row
                    Row(
                      spacing: 12,
                      children: [
                        Expanded(
                          child: AppInput(
                            title: 'الوصل',
                            controller: billController,
                            inputType: TextInputType.number,
                            direction: TextDirection.ltr,
                            readOnly: true,
                          ),
                        ),
                        Expanded(
                          child: AppInput(
                            title: 'التاريخ',
                            controller: dateController,
                            isDatePicker: true,
                            isDate: true,
                            onTap: _selectDate,
                            direction: TextDirection.ltr,
                          ),
                        ),
                        Expanded(
                          child: AppInput(
                            title: 'الخصم',
                            controller: discountController,
                            isPrice: true,
                            inputType: TextInputType.number,
                            direction: TextDirection.ltr,
                          ),
                        ),
                        Expanded(child: _currencyDropdown()),
                        Expanded(
                          child: AppInput(
                            title: 'سعر الصرف (دينار لكل دولار)',
                            controller: exchangeRateController,
                            isPrice: true,
                            inputType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            direction: TextDirection.ltr,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: AppInput(
                            title: 'تفاصيل الخصم',
                            controller: discountDetailsController,
                          ),
                        ),
                      ],
                    ),

                    Row(
                      spacing: 12,
                      children: [
                        Expanded(
                          flex: 2,
                          child: AppInput(
                            title: 'الملاحظات',
                            controller: notesController,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _openMultiSells,
                          icon: const Icon(Icons.chair),
                          label: Text(
                            'عناصر المعرض (${state.draftMultiSells.length})',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _openAdditional,
                          icon: const Icon(Icons.add_box),
                          label: Text(
                            'مبالغ إضافية (${state.draftAdditional.length})',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _openModels,
                          icon: const Icon(Icons.style),
                          label: const Text('الموديلات'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _openPayments,
                          icon: const Icon(Icons.payments),
                          label: const Text('الدفعات'),
                        ),
                        const Spacer(),
                        _miniStat('الإجمالي', state.draftTotal, bold: true),
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

                    AppInput(
                      title: 'بحث بالوصل أو الملاحظات',
                      controller: searchController,
                      onChanged: (_) {
                        if (mounted) setState(() {});
                      },
                      suffixIcon: const Icon(Icons.search, color: _kAccent),
                    ),

                    if (state.isLoading)
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      SHTable(
                        controller: tableController,
                        direction: TextDirection.rtl,
                        hasIndex: true,
                        indexLabel: 'ت',
                        pagination: true,
                        columns: _buildColumns(state.exhibitions),
                        rows: _filteredRows(state.exhibitions, state),
                      ),

                    _footer(state),
                  ],
                ),
              );
            },
          ),
          persistentFooterButtons: [
            AppActionButtons(
              onBack: () => context.pop(),
              onDelete: _handleDelete,
              onEdit: _handleEdit,
              onDuplicate: _handleDuplicate,
              onExport: _exportToExcel,
              onPrint: _handlePrint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _currencyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'العملة',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<Currency>(
          initialValue: currency,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kAccent),
            ),
          ),
          items: const [
            DropdownMenuItem(value: Currency.iqd, child: Text('دينار')),
            DropdownMenuItem(value: Currency.usd, child: Text('دولار')),
          ],
          onChanged: (c) => setState(() {
            currency = c ?? Currency.iqd;
          }),
        ),
      ],
    );
  }

  Widget _miniStat(String label, int value, {bool bold = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(
          PriceUtils.addCommas(value),
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: bold ? _kAccent : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _footer(ExhibitionsState state) {
    final totalUsd = state.totalUsd;
    final grandFinalTotal = state.grandFinalTotal;
    final remaining = grandFinalTotal - totalPaid;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'عدد الوصولات', value: '${state.count}'),
          _StatItem(
            label: 'الإجمالي (دينار)',
            value: PriceUtils.addCommas(state.totalIqdOnly),
          ),
          _StatItem(
            label: 'الإجمالي (دولار)',
            value: '\$${totalUsd.toStringAsFixed(2)}',
          ),
          _StatItem(
            label: 'مجموع الدفعات',
            value: PriceUtils.addCommas(totalPaid),
          ),
          _StatItem(
            label: 'الدين (المتبقي)',
            value: PriceUtils.addCommas(remaining),
          ),
        ],
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

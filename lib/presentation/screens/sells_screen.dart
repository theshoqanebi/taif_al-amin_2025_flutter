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
import 'package:taif_alamin/core/bill/make_oder_bill.dart';
import 'package:taif_alamin/data/constants/currency.dart';
import 'package:taif_alamin/data/constants/edit_messages.dart';
import 'package:taif_alamin/data/constants/templates.dart';
import 'package:taif_alamin/data/models/customer_debt_model.dart';
import 'package:taif_alamin/data/models/sells_model.dart';
import 'package:taif_alamin/presentation/cubits/sells_cubit/sells_cubit.dart';
import 'package:taif_alamin/presentation/cubits/sells_cubit/sells_state.dart';
import 'package:taif_alamin/presentation/cubits/sells_models_cubit.dart';
import 'package:taif_alamin/presentation/dialogs/additional_amounts_dialog.dart';
import 'package:taif_alamin/presentation/dialogs/multi_sells_dialog.dart';
import 'package:taif_alamin/presentation/screens/sells_models_screen.dart';
import 'package:taif_alamin/utils/docx_utils.dart';
import 'package:taif_alamin/utils/price_utils.dart';
import 'package:taif_alamin/utils/print_server.dart';
import 'package:taif_alamin/utils/snack_bar_util.dart';
import 'package:taif_alamin/utils/uuid_utils.dart';
import 'package:taif_alamin/widgets/app_primary_button.dart';
import 'package:taif_alamin/widgets/general/app_action_buttons.dart';
import 'package:taif_alamin/widgets/general/app_input.dart';

const _kAccent = Color(0xFF003763);

class SellsScreen extends StatefulWidget {
  const SellsScreen({super.key});

  @override
  State<SellsScreen> createState() => _SellsScreenState();
}

class _SellsScreenState extends State<SellsScreen> {
  final billController = TextEditingController();
  final dateController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final discountController = TextEditingController();
  final paymentController = TextEditingController(); // first payment
  final discountDetailsController = TextEditingController();
  final searchController = TextEditingController();
  final SHTableController tableController = SHTableController();

  int? editingId;
  String? editingPaymentUuid;
  DateTime selectedDate = DateTime.now();
  Currency currency = Currency.iqd;

  @override
  void initState() {
    super.initState();
    context.read<SellsCubit>().loadSells();
    context.read<SellsCubit>().clearDraft();
    context.read<SellsModelsCubit>().loadModels();
    dateController.text = _formatDate(selectedDate);
    _prefillBill();
  }

  @override
  void dispose() {
    billController.dispose();
    dateController.dispose();
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    discountController.dispose();
    paymentController.dispose();
    discountDetailsController.dispose();
    searchController.dispose();
    tableController.dispose();
    super.dispose();
  }

  Future<void> _prefillBill() async {
    final next = await context.read<SellsCubit>().nextBillNumber();
    if (mounted) billController.text = next.toString();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int _money(TextEditingController c) =>
      int.tryParse(c.text.replaceAll(',', '').trim()) ?? 0;

  final List<SHColumn> _columns = [
    SHColumn(id: 'id', title: 'id', weight: 1, hidden: true),
    SHColumn(id: 'bill', title: 'الوصل', weight: 2, isNumeric: true),
    SHColumn(id: 'date', title: 'التاريخ', weight: 2),
    SHColumn(id: 'name', title: 'الاسم', weight: 3),
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
  ];

  List<Sell> _visible(SellsState state) {
    final q = searchController.text.trim();
    if (q.isEmpty) return state.sells;
    return state.sells
        .where(
          (s) =>
              s.bill.contains(q) ||
              (s.name ?? '').contains(q) ||
              (s.phone ?? '').contains(q),
        )
        .toList();
  }

  List<Map<String, String>> _rows(SellsState state) {
    return _visible(state)
        .map(
          (s) => {
            'id': s.id.toString(),
            'bill': s.bill,
            'date': _formatDate(s.date),
            'name': s.name ?? '',
            'total': state.totalOf(s).toString(),
            'discount': state.discountOf(s).toString(),
            'paid': state.paidOf(s).toString(),
            'remaining': state.remainingOf(s).toString(),
            'currency': state.currencyOf(s).toDisplayString(),
          },
        )
        .toList();
  }

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

  Sell _buildSell(String paymentUuid) => Sell(
    id: editingId ?? 0,
    bill: billController.text.trim(),
    name: nameController.text.trim().isEmpty
        ? null
        : nameController.text.trim(),
    phone: phoneController.text.trim().isEmpty
        ? null
        : phoneController.text.trim(),
    address: addressController.text.trim().isEmpty
        ? null
        : addressController.text.trim(),
    date: selectedDate,
    paymentUuid: paymentUuid,
    discountDetails: discountDetailsController.text.trim().isEmpty
        ? null
        : discountDetailsController.text.trim(),
  );

  CustomerDebt _buildDebt(String uuid, int total) => CustomerDebt(
    id: 0,
    debtorName: nameController.text.trim(),
    debtDate: selectedDate,
    bill: billController.text.trim(),
    totalPrice: total,
    discount: _money(discountController),
    currency: currency,
    notes: discountDetailsController.text.trim().isEmpty
        ? null
        : discountDetailsController.text.trim(),
    uuid: uuid,
  );

  void _save() {
    if (billController.text.trim().isEmpty) {
      SnackBarUtil.showError(context, 'أدخل رقم الوصل');
      return;
    }
    final cubit = context.read<SellsCubit>();
    if (cubit.state.draftMultiSells.isEmpty &&
        cubit.state.draftAdditional.isEmpty) {
      SnackBarUtil.showError(context, 'أضف عناصر البيع أولاً');
      return;
    }

    final total = cubit.state.draftTotal;
    final discount = _money(discountController);
    if (discount > total) {
      SnackBarUtil.showError(context, 'الخصم أكبر من الكلي');
      return;
    }

    final uuid = editingPaymentUuid ?? UuidUtils.v4();
    final sell = _buildSell(uuid);
    final debt = _buildDebt(uuid, total);

    if (editingId != null) {
      cubit.updateSell(sell, debt: debt);
    } else {
      final firstPayment = _money(paymentController);
      if (firstPayment > (total - discount)) {
        SnackBarUtil.showError(context, 'الدفعة الأولى أكبر من المتبقي');
        return;
      }
      cubit.createSell(sell, debt: debt, firstPayment: firstPayment);
    }
  }

  Future<void> _clearForm() async {
    nameController.clear();
    phoneController.clear();
    addressController.clear();
    discountController.clear();
    paymentController.clear();
    discountDetailsController.clear();
    selectedDate = DateTime.now();
    dateController.text = _formatDate(selectedDate);
    currency = Currency.iqd;
    editingId = null;
    editingPaymentUuid = null;
    context.read<SellsCubit>().clearDraft();
    await _prefillBill();
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
    final cubit = context.read<SellsCubit>();
    final visible = _visible(cubit.state);
    final idx = selected.first;
    if (idx >= visible.length) return;
    final s = visible[idx];
    final debt = cubit.state.debtOf(s);
    setState(() {
      editingId = s.id;
      editingPaymentUuid = s.paymentUuid;
      billController.text = s.bill;
      selectedDate = s.date;
      dateController.text = _formatDate(s.date);
      nameController.text = s.name ?? '';
      phoneController.text = s.phone ?? '';
      addressController.text = s.address ?? '';
      discountController.text = (debt?.discount ?? 0) > 0
          ? debt!.discount.toString()
          : '';
      paymentController.clear(); // payments are managed in the debts screen
      discountDetailsController.text = s.discountDetails ?? '';
      currency = debt?.currency ?? Currency.iqd;
    });
    await cubit.loadDraftFor(s.bill);
  }

  void _handleDelete() {
    final selected = tableController.selectedIndexes;
    if (selected.isEmpty) {
      SnackBarUtil.showError(context, 'اختر عنصراً واحداً على الأقل');
      return;
    }
    final cubit = context.read<SellsCubit>();
    final visible = _visible(cubit.state);
    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text(
            'سيتم حذف ${selected.length} وصل وما يرتبط به من دين ودفعات، تأكيد؟',
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
                  if (idx < visible.length) cubit.deleteSell(visible[idx]);
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

  void _handleDuplicate() => SnackBarUtil.showError(context, 'النسخ غير مدعوم');

  void _openMultiSells() {
    final a = context.read<SellsCubit>();
    final b = context.read<SellsModelsCubit>();
    showDialog(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: a),
          BlocProvider.value(value: b),
        ],
        child: MultiSellsDialog(bill: billController.text.trim()),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _openAdditional() {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<SellsCubit>(),
        child: AdditionalAmountsDialog(bill: billController.text.trim()),
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
              value: context.read<SellsModelsCubit>(),
              child: const SellsModelsScreen(),
            ),
          ),
        )
        .then((_) {
          if (!mounted) return;
          context.read<SellsModelsCubit>().loadModels();
        });
  }

  Future<void> _exportToExcel() async {
    final result = await getSaveLocation(
      suggestedName:
          'sells_${DateTime.now().year}-${DateTime.now().month}.xlsx',
      acceptedTypeGroups: [
        const XTypeGroup(label: 'Excel', extensions: ['xlsx']),
      ],
    );
    if (result == null || !mounted) return;
    try {
      final state = context.read<SellsCubit>().state;
      final excel = xlsx.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow([
        xlsx.TextCellValue('الوصل'),
        xlsx.TextCellValue('التاريخ'),
        xlsx.TextCellValue('الاسم'),
        xlsx.TextCellValue('الكلي'),
        xlsx.TextCellValue('الخصم'),
        xlsx.TextCellValue('المدفوع'),
        xlsx.TextCellValue('المتبقي'),
        xlsx.TextCellValue('العملة'),
      ]);
      for (final s in state.sells) {
        sheet.appendRow([
          xlsx.TextCellValue(s.bill),
          xlsx.TextCellValue(_formatDate(s.date)),
          xlsx.TextCellValue(s.name ?? ''),
          xlsx.TextCellValue(state.totalOf(s).toString()),
          xlsx.TextCellValue(state.discountOf(s).toString()),
          xlsx.TextCellValue(state.paidOf(s).toString()),
          xlsx.TextCellValue(state.remainingOf(s).toString()),
          xlsx.TextCellValue(state.currencyOf(s).toDisplayString()),
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

  // طباعة: يبني الوصل docx، يحوّله PDF عبر خادم التحويل المحلي
  // (assets/server/server.py)، ثم يدع المستخدم يحدد مسار الحفظ.
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
    final cubit = context.read<SellsCubit>();
    final visible = _visible(cubit.state);
    final idx = selected.first;
    if (idx >= visible.length) return;
    final sell = visible[idx];

    try {
      // Always load a fresh DocxUtils from the template — never reuse one
      // that's already been saved/modified.
      final docx = DocxUtils();
      docx.load(templatePath);

      final maker = MakeOderBill(docx: docx);
      maker.fillBaseInfo(
        bill: sell.bill,
        name: sell.name ?? '',
        phone: sell.phone ?? '',
        address: sell.address ?? '',
        date: sell.date,
      );
      await maker.fillSellData(
        sell,
        discount: cubit.state.discountOf(sell),
        paid: cubit.state.paidOf(sell),
      );

      // Never selfSave() onto the template — save the filled copy into a
      // disposable temp folder under a fresh name every time (so repeated
      // prints of the same bill never collide with or get served stale by
      // a cached copy); that path is the only thing used from here on.
      final tempDir = await getTemporaryDirectory();
      final printPath = p.join(
        tempDir.path,
        'print_bill_${UuidUtils.v4()}.docx',
      );
      maker.save(path: printPath);

      final pdfBytes = await PrintServer.convertToPdf(printPath);

      final result = await getSaveLocation(
        suggestedName: 'وصل_${sell.bill}.pdf',
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

  @override
  Widget build(BuildContext context) {
    return AppWindow(
      showBack: true,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: BlocConsumer<SellsCubit, SellsState>(
            listener: (context, state) {
              if (state.hasError) {
                SnackBarUtil.showError(context, state.error ?? 'حدث خطأ');
              }
            },
            builder: (context, state) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  spacing: 10,
                  children: [
                    // row 1: bill / date / name / phone
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
                          flex: 2,
                          child: AppInput(
                            title: 'الاسم',
                            controller: nameController,
                          ),
                        ),
                        Expanded(
                          child: AppInput(
                            title: 'الهاتف',
                            controller: phoneController,
                            direction: TextDirection.ltr,
                          ),
                        ),
                      ],
                    ),

                    // row 2: discount / first payment / currency / address
                    Row(
                      spacing: 12,
                      children: [
                        Expanded(
                          child: AppInput(
                            title: 'الخصم',
                            controller: discountController,
                            isPrice: true,
                            inputType: TextInputType.number,
                            direction: TextDirection.ltr,
                          ),
                        ),
                        Expanded(
                          child: AppInput(
                            title: editingId != null
                                ? 'الدفعة الأولى (للجديد فقط)'
                                : 'الدفعة الأولى',
                            controller: paymentController,
                            isPrice: true,
                            inputType: TextInputType.number,
                            direction: TextDirection.ltr,
                          ),
                        ),
                        Expanded(child: _currencyDropdown()),
                        Expanded(
                          flex: 2,
                          child: AppInput(
                            title: 'العنوان',
                            controller: addressController,
                          ),
                        ),
                      ],
                    ),

                    // row 3: discount details + buttons
                    Row(
                      spacing: 12,
                      children: [
                        Expanded(
                          flex: 2,
                          child: AppInput(
                            title: 'تفاصيل الخصم',
                            controller: discountDetailsController,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _openMultiSells,
                          icon: const Icon(Icons.chair),
                          label: Text(
                            'العناصر (${state.draftMultiSells.length})',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _openAdditional,
                          icon: const Icon(Icons.add_box),
                          label: Text(
                            'إضافي (${state.draftAdditional.length})',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _openModels,
                          icon: const Icon(Icons.style),
                          label: const Text('الموديلات'),
                        ),
                        _miniStat('الكلي', state.draftTotal, bold: true),
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
                      title: 'بحث بالوصل أو الاسم أو الهاتف',
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
                        columns: _columns,
                        rows: _rows(state),
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
          onChanged: (c) => setState(() => currency = c ?? Currency.iqd),
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

  Widget _footer(SellsState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'العدد', value: '${state.count}'),
          _StatItem(
            label: 'المتبقي (دينار)',
            value: PriceUtils.addCommas(state.remainingByCurrency(false)),
          ),
          _StatItem(
            label: 'المتبقي (دولار)',
            value: '\$${PriceUtils.addCommas(state.remainingByCurrency(true))}',
          ),
          _StatItem(
            label: 'المدفوع (دينار)',
            value: PriceUtils.addCommas(state.paidByCurrency(false)),
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

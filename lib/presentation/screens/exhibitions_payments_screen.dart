import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:excel/excel.dart' as xlsx;
import 'package:file_selector/file_selector.dart';
import 'package:shtable/shtable.dart';
import 'package:taif_alamin/app_window.dart';
import 'package:taif_alamin/data/constants/edit_messages.dart';
import 'package:taif_alamin/data/models/exhibition_payment_model.dart';
import 'package:taif_alamin/presentation/cubits/exhibitions_payments/exhibitions_payments_cubit.dart';
import 'package:taif_alamin/presentation/cubits/exhibitions_payments/exhibitions_payments_state.dart';
import 'package:taif_alamin/utils/price_utils.dart';
import 'package:taif_alamin/utils/snack_bar_util.dart';
import 'package:taif_alamin/widgets/app_primary_button.dart';
import 'package:taif_alamin/widgets/general/app_action_buttons.dart';
import 'package:taif_alamin/widgets/general/app_input.dart';

const _kAccent = Color(0xFF003763);

/// Payments for exhibitions.
///
/// If [belongTo] is provided, the screen is locked to that exhibition
/// (form auto-fills belongTo, no filter). Otherwise it shows all payments
/// with a belongTo filter + search.
class ExhibitionsPaymentScreen extends StatefulWidget {
  final String? belongTo;
  final String? title;

  const ExhibitionsPaymentScreen({super.key, this.belongTo, this.title});

  @override
  State<ExhibitionsPaymentScreen> createState() =>
      _ExhibitionsPaymentScreenState();
}

class _ExhibitionsPaymentScreenState extends State<ExhibitionsPaymentScreen> {
  final TextEditingController paymentController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController belongToController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final SHTableController tableController = SHTableController();

  int? editingId;
  DateTime? selectedDate;
  String? filterBelongTo;

  bool get _locked => widget.belongTo != null;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<ExhibitionsPaymentsCubit>();
    if (_locked) {
      cubit.loadByBelongTo(widget.belongTo!);
    } else {
      cubit.loadAll();
    }
  }

  @override
  void dispose() {
    paymentController.dispose();
    dateController.dispose();
    belongToController.dispose();
    searchController.dispose();
    tableController.dispose();
    super.dispose();
  }

  List<SHColumn> get _columns => [
    SHColumn(
      id: 'id',
      title: 'الرقم',
      weight: 1,
      isNumeric: true,
      hidden: true,
    ),
    SHColumn(
      id: 'payment',
      title: 'الدفعة',
      weight: 3,
      isNumeric: true,
      priceFormat: true,
    ),
    if (!_locked) SHColumn(id: 'belongTo', title: 'الجهة', weight: 3),
    SHColumn(id: 'date', title: 'التاريخ', weight: 3),
  ];

  // ---- filtering ----
  List<ExhibitionPayment> _applyFilters(List<ExhibitionPayment> all) {
    final q = searchController.text.trim().toLowerCase();
    return all.where((p) {
      if (!_locked && filterBelongTo != null && p.belongTo != filterBelongTo) {
        return false;
      }
      if (q.isNotEmpty) {
        final hay = '${p.belongTo ?? ''} ${p.payment}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  List<String> _belongToOptions(List<ExhibitionPayment> all) {
    final set = <String>{};
    for (final p in all) {
      final b = p.belongTo?.trim();
      if (b != null && b.isNotEmpty) set.add(b);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<Map<String, String>> _toRows(List<ExhibitionPayment> payments) {
    return payments.map((p) {
      return {
        'id': p.id.toString(),
        'payment': p.payment.toString(),
        'belongTo': p.belongTo ?? '',
        'date': _formatDate(p.date),
      };
    }).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
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

  void _save() {
    final payment = int.tryParse(
      paymentController.text.replaceAll(',', '').trim(),
    );

    if (payment == null || payment <= 0) {
      SnackBarUtil.showError(context, 'أدخل مبلغ الدفعة');
      return;
    }
    if (selectedDate == null) {
      SnackBarUtil.showError(context, 'اختر تاريخاً');
      return;
    }

    final belongTo = _locked
        ? widget.belongTo
        : (belongToController.text.trim().isEmpty
              ? null
              : belongToController.text.trim());

    if (!_locked && belongTo == null) {
      SnackBarUtil.showError(context, 'أدخل الجهة');
      return;
    }

    final p = ExhibitionPayment(
      id: editingId ?? 0,
      date: selectedDate!,
      payment: payment,
      belongTo: belongTo,
    );

    final cubit = context.read<ExhibitionsPaymentsCubit>();
    if (editingId != null) {
      cubit.update(p);
    } else {
      cubit.add(p);
    }
    _clearForm();
  }

  void _clearForm() {
    paymentController.clear();
    dateController.clear();
    belongToController.clear();
    selectedDate = null;
    editingId = null;
    if (mounted) setState(() {});
  }

  void _editPayment(ExhibitionPayment p) {
    paymentController.text = p.payment.toString();
    dateController.text = _formatDate(p.date);
    belongToController.text = p.belongTo ?? '';
    selectedDate = p.date;
    editingId = p.id;
    if (mounted) setState(() {});
  }

  void _deleteSelected() {
    final selected = tableController.selectedIndexes;
    if (selected.isEmpty) {
      SnackBarUtil.showError(context, 'اختر عنصراً واحداً على الأقل');
      return;
    }

    final cubit = context.read<ExhibitionsPaymentsCubit>();
    final visible = _applyFilters(cubit.state.payments);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف ${selected.length} عنصر؟'),
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
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _handleEdit() {
    final selected = tableController.selectedIndexes;
    if (selected.isEmpty) {
      SnackBarUtil.showError(context, EditMessages.emptySelection);
      return;
    }
    if (selected.length > 1) {
      SnackBarUtil.showError(context, EditMessages.multipleSelection);
      return;
    }

    final visible = _applyFilters(
      context.read<ExhibitionsPaymentsCubit>().state.payments,
    );
    final idx = selected.first;
    if (idx < visible.length) _editPayment(visible[idx]);
  }

  void _handleDuplicate() {
    final selected = tableController.selectedIndexes;
    if (selected.isEmpty) {
      SnackBarUtil.showError(context, 'اختر عنصراً للنسخ');
      return;
    }

    final cubit = context.read<ExhibitionsPaymentsCubit>();
    final visible = _applyFilters(cubit.state.payments);

    for (final idx in selected) {
      if (idx < visible.length) {
        cubit.add(visible[idx].copyWith(id: 0, date: DateTime.now()));
      }
    }
  }

  void _exportToExcel() async {
    final tag = widget.belongTo ?? 'all';
    final result = await getSaveLocation(
      suggestedName:
          'exhibitions_payments_${tag}_${DateTime.now().year}-${DateTime.now().month}.xlsx',
      acceptedTypeGroups: [
        const XTypeGroup(label: 'Excel', extensions: ['xlsx']),
      ],
    );
    if (result == null || !mounted) return;

    try {
      final rows = _toRows(
        _applyFilters(context.read<ExhibitionsPaymentsCubit>().state.payments),
      );

      final excel = xlsx.Excel.createExcel();
      final sheet = excel['Sheet1'];

      sheet.appendRow([
        xlsx.TextCellValue('الرقم'),
        xlsx.TextCellValue('الدفعة'),
        xlsx.TextCellValue('الجهة'),
        xlsx.TextCellValue('التاريخ'),
      ]);

      for (final row in rows) {
        sheet.appendRow([
          xlsx.TextCellValue(row['id'] ?? ''),
          xlsx.TextCellValue(row['payment'] ?? ''),
          xlsx.TextCellValue(row['belongTo'] ?? ''),
          xlsx.TextCellValue(row['date'] ?? ''),
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) throw Exception('Failed to encode');
      await File(result.path).writeAsBytes(Uint8List.fromList(bytes));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم التصدير إلى ${result.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppWindow(
      showBack: true,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body:
              BlocListener<ExhibitionsPaymentsCubit, ExhibitionsPaymentsState>(
                listener: (context, state) {
                  if (state.isSuccess && editingId == null) {
                    SnackBarUtil.showSuccess(context, 'تم العملية بنجاح');
                  }
                  if (state.hasError) {
                    SnackBarUtil.showError(context, state.error ?? 'حدث خطأ');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Column(
                    spacing: 16,
                    children: [
                      // ---- Title ----
                      Row(
                        children: [
                          Text(
                            widget.title ??
                                (_locked
                                    ? 'دفعات: ${widget.belongTo}'
                                    : 'دفعات المعارض'),
                            style: const TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _kAccent,
                            ),
                          ),
                        ],
                      ),

                      // ---- Form row ----
                      Row(
                        spacing: 16,
                        children: [
                          Expanded(
                            child: AppInput(
                              title: 'مبلغ الدفعة',
                              controller: paymentController,
                              isPrice: true,
                              inputType: TextInputType.number,
                              direction: TextDirection.ltr,
                            ),
                          ),
                          if (!_locked)
                            Expanded(
                              child: AppInput(
                                title: 'الجهة',
                                controller: belongToController,
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
                          AppPrimaryButton(
                            text: editingId != null ? 'تعديل' : 'إضافة',
                            onPressed: _save,
                          ),
                          if (editingId != null)
                            InkWell(
                              onTap: _clearForm,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 32,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'إلغاء',
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      // ---- Filter row (only in the "all" view) ----
                      if (!_locked)
                        BlocBuilder<
                          ExhibitionsPaymentsCubit,
                          ExhibitionsPaymentsState
                        >(
                          builder: (context, state) {
                            final belongTos = _belongToOptions(state.payments);
                            if (filterBelongTo != null &&
                                !belongTos.contains(filterBelongTo)) {
                              filterBelongTo = null;
                            }
                            return Row(
                              spacing: 8,
                              children: [
                                SizedBox(
                                  width: 240,
                                  child: _Dropdown<String?>(
                                    title: 'تصفية الجهة',
                                    value: filterBelongTo,
                                    items: [null, ...belongTos],
                                    labelOf: (b) => b ?? 'الكل',
                                    onChanged: (v) =>
                                        setState(() => filterBelongTo = v),
                                  ),
                                ),
                                Expanded(
                                  child: AppInput(
                                    title: 'بحث',
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
                                if (filterBelongTo != null ||
                                    searchController.text.isNotEmpty)
                                  InkWell(
                                    onTap: () => setState(() {
                                      filterBelongTo = null;
                                      searchController.clear();
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.grey[300],
                                      ),
                                      child: const Icon(
                                        Icons.clear,
                                        color: _kAccent,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),

                      // ---- Table ----
                      BlocBuilder<
                        ExhibitionsPaymentsCubit,
                        ExhibitionsPaymentsState
                      >(
                        builder: (context, state) {
                          if (state.isLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return SHTable(
                            controller: tableController,
                            direction: TextDirection.rtl,
                            hasIndex: true,
                            indexLabel: 'ت',
                            pagination: true,
                            columns: _columns,
                            rows: _toRows(_applyFilters(state.payments)),
                          );
                        },
                      ),

                      // ---- Stats footer ----
                      BlocBuilder<
                        ExhibitionsPaymentsCubit,
                        ExhibitionsPaymentsState
                      >(
                        builder: (context, state) {
                          final visible = _applyFilters(state.payments);
                          final total = visible.fold<int>(
                            0,
                            (s, p) => s + p.payment,
                          );
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _StatItem(
                                  label: 'إجمالي الدفعات',
                                  value: PriceUtils.addCommas(total),
                                ),
                                _StatItem(
                                  label: 'العدد',
                                  value: '${visible.length}',
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
          persistentFooterButtons: [
            AppActionButtons(
              onBack: () => context.pop(),
              onDelete: _deleteSelected,
              onEdit: _handleEdit,
              onDuplicate: _handleDuplicate,
              onExport: _exportToExcel,
            ),
          ],
        ),
      ),
    );
  }
}

/// Styled dropdown matching [AppInput].
class _Dropdown<T> extends StatelessWidget {
  final String title;
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.title,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kAccent,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              value: value,
              items: items
                  .map(
                    (e) => DropdownMenuItem<T>(
                      value: e,
                      child: Text(
                        labelOf(e),
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 15,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
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

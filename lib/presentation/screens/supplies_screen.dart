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
import 'package:taif_alamin/data/constants/supply_type.dart';
import 'package:taif_alamin/data/models/supply_model.dart';
import 'package:taif_alamin/presentation/cubits/supplies_cubit/supplies_state.dart';
import 'package:taif_alamin/presentation/cubits/supplies_cubit/supplies_cubit.dart';
import 'package:taif_alamin/utils/price_utils.dart';
import 'package:taif_alamin/utils/snack_bar_util.dart';
import 'package:taif_alamin/widgets/app_primary_button.dart';
import 'package:taif_alamin/widgets/general/app_action_buttons.dart';
import 'package:taif_alamin/widgets/general/app_input.dart';

const _kAccent = Color(0xFF003763);

class SuppliesScreen extends StatefulWidget {
  const SuppliesScreen({super.key});

  @override
  State<SuppliesScreen> createState() => _SuppliesScreenState();
}

class _SuppliesScreenState extends State<SuppliesScreen> {
  // ---- form controllers ----
  final TextEditingController billController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController tPriceController = TextEditingController();
  final TextEditingController pPriceController = TextEditingController();
  final TextEditingController belongToController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final SHTableController tableController = SHTableController();

  int? editingId;
  DateTime? selectedDate;
  SupplyType formType = SupplyType.paint;

  // ---- filters ----
  SupplyType? filterType;
  String? filterBelongTo;

  @override
  void initState() {
    super.initState();
    context.read<SuppliesCubit>().loadAll();
  }

  @override
  void dispose() {
    billController.dispose();
    dateController.dispose();
    tPriceController.dispose();
    pPriceController.dispose();
    belongToController.dispose();
    notesController.dispose();
    searchController.dispose();
    tableController.dispose();
    super.dispose();
  }

  final List<SHColumn> _columns = [
    SHColumn(
      id: 'id',
      title: 'الرقم',
      weight: 1,
      isNumeric: true,
      hidden: true,
    ),
    SHColumn(id: 'bill', title: 'الوصل', weight: 2),
    SHColumn(id: 'type', title: 'النوع', weight: 2),
    SHColumn(id: 'belongTo', title: 'الجهة', weight: 3),
    SHColumn(
      id: 'tPrice',
      title: 'الكلي',
      weight: 3,
      isNumeric: true,
      priceFormat: true,
    ),
    SHColumn(
      id: 'pPrice',
      title: 'المدفوع',
      weight: 3,
      isNumeric: true,
      priceFormat: true,
    ),
    SHColumn(
      id: 'remaining',
      title: 'المتبقي',
      weight: 3,
      isNumeric: true,
      priceFormat: true,
    ),
    SHColumn(id: 'date', title: 'التاريخ', weight: 3),
    SHColumn(id: 'notes', title: 'الملاحظات', weight: 4),
  ];

  List<Supply> _applyFilters(List<Supply> all) {
    final q = searchController.text.trim();
    return all.where((s) {
      if (filterType != null && s.type != filterType) return false;
      if (filterBelongTo != null && s.belongTo != filterBelongTo) return false;
      if (q.isNotEmpty) {
        final haystack =
            '${s.bill ?? ''} ${s.belongTo ?? ''} ${s.notes ?? ''} '
                    '${s.type.toDisplayString()}'
                .toLowerCase();
        if (!haystack.contains(q.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }

  List<String> _belongToOptions(List<Supply> all) {
    final set = <String>{};
    for (final s in all) {
      final b = s.belongTo?.trim();
      if (b != null && b.isNotEmpty) set.add(b);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<Map<String, String>> _suppliesToRows(List<Supply> supplies) {
    return supplies.map((s) {
      return {
        'id': s.id.toString(),
        'bill': s.bill ?? '',
        'type': s.type.toDisplayString(),
        'belongTo': s.belongTo ?? '',
        'tPrice': s.tPrice.toString(),
        'pPrice': s.pPrice.toString(),
        'remaining': s.remaining.toString(),
        'date': _formatDate(s.date),
        'notes': s.notes ?? '',
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
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateController.text = _formatDate(picked);
      });
    }
  }

  int _parsePrice(TextEditingController c) =>
      int.tryParse(c.text.replaceAll(',', '').trim()) ?? 0;

  void _save() {
    final tPrice = _parsePrice(tPriceController);
    final pPrice = _parsePrice(pPriceController);

    if (tPrice <= 0) {
      SnackBarUtil.showError(context, 'أدخل السعر الكلي');
      return;
    }
    if (pPrice > tPrice) {
      SnackBarUtil.showError(context, 'المدفوع أكبر من السعر الكلي');
      return;
    }
    if (selectedDate == null) {
      SnackBarUtil.showError(context, 'اختر تاريخاً');
      return;
    }

    final supply = Supply(
      id: editingId ?? 0,
      bill: billController.text.trim().isEmpty
          ? null
          : billController.text.trim(),
      date: selectedDate!,
      tPrice: tPrice,
      pPrice: pPrice,
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      belongTo: belongToController.text.trim().isEmpty
          ? null
          : belongToController.text.trim(),
      type: formType,
    );

    final cubit = context.read<SuppliesCubit>();
    if (editingId != null) {
      cubit.update(supply);
    } else {
      cubit.add(supply);
    }
    cubit.loadAll();
    _clearForm();
  }

  void _clearForm() {
    billController.clear();
    dateController.clear();
    tPriceController.clear();
    pPriceController.clear();
    belongToController.clear();
    notesController.clear();
    selectedDate = null;
    editingId = null;
    formType = SupplyType.paint;
    if (mounted) setState(() {});
  }

  void _editSupply(Supply s) {
    billController.text = s.bill ?? '';
    dateController.text = _formatDate(s.date);
    tPriceController.text = s.tPrice.toString();
    pPriceController.text = s.pPrice.toString();
    belongToController.text = s.belongTo ?? '';
    notesController.text = s.notes ?? '';
    selectedDate = s.date;
    editingId = s.id;
    formType = s.type;
    if (mounted) setState(() {});
  }

  void _deleteSelected() {
    final selected = tableController.selectedIndexes;
    if (selected.isEmpty) {
      SnackBarUtil.showError(context, 'اختر عنصراً واحداً على الأقل');
      return;
    }

    final cubit = context.read<SuppliesCubit>();
    final visible = _applyFilters(cubit.state.supplies);

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
              cubit.loadAll();
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

    final visible = _applyFilters(context.read<SuppliesCubit>().state.supplies);
    final idx = selected.first;
    if (idx < visible.length) _editSupply(visible[idx]);
  }

  void _handleDuplicate() {
    final selected = tableController.selectedIndexes;
    if (selected.isEmpty) {
      SnackBarUtil.showError(context, 'اختر عنصراً للنسخ');
      return;
    }

    final cubit = context.read<SuppliesCubit>();
    final visible = _applyFilters(cubit.state.supplies);

    for (final idx in selected) {
      if (idx < visible.length) {
        final o = visible[idx];
        cubit.add(o.copyWith(id: 0, date: DateTime.now()));
      }
    }
    cubit.loadAll();
  }

  void _exportToExcel() async {
    final result = await getSaveLocation(
      suggestedName:
          'supplies_${DateTime.now().year}-${DateTime.now().month}.xlsx',
      acceptedTypeGroups: [
        const XTypeGroup(label: 'Excel', extensions: ['xlsx']),
      ],
    );
    if (result == null || !mounted) return;

    try {
      final cubit = context.read<SuppliesCubit>();
      final rows = _suppliesToRows(_applyFilters(cubit.state.supplies));

      final excel = xlsx.Excel.createExcel();
      final sheet = excel['Sheet1'];

      sheet.appendRow([
        xlsx.TextCellValue('الرقم'),
        xlsx.TextCellValue('الوصل'),
        xlsx.TextCellValue('النوع'),
        xlsx.TextCellValue('الجهة'),
        xlsx.TextCellValue('الكلي'),
        xlsx.TextCellValue('المدفوع'),
        xlsx.TextCellValue('المتبقي'),
        xlsx.TextCellValue('التاريخ'),
        xlsx.TextCellValue('الملاحظات'),
      ]);

      for (final row in rows) {
        sheet.appendRow([
          xlsx.TextCellValue(row['id'] ?? ''),
          xlsx.TextCellValue(row['bill'] ?? ''),
          xlsx.TextCellValue(row['type'] ?? ''),
          xlsx.TextCellValue(row['belongTo'] ?? ''),
          xlsx.TextCellValue(row['tPrice'] ?? ''),
          xlsx.TextCellValue(row['pPrice'] ?? ''),
          xlsx.TextCellValue(row['remaining'] ?? ''),
          xlsx.TextCellValue(row['date'] ?? ''),
          xlsx.TextCellValue(row['notes'] ?? ''),
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
          body: BlocListener<SuppliesCubit, SuppliesState>(
            listener: (context, state) {
              if (state.isSuccess && editingId == null) {
                SnackBarUtil.showSuccess(context, 'تم العملية بنجاح');
              }
              if (state.hasError) {
                SnackBarUtil.showError(context, state.error ?? 'حدث خطأ');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                spacing: 16,
                children: [
                  // ---- Input Row 1: bill / type / belongTo ----
                  Row(
                    spacing: 16,
                    children: [
                      Expanded(
                        child: AppInput(
                          title: 'رقم الوصل',
                          controller: billController,
                          direction: TextDirection.ltr,
                        ),
                      ),
                      Expanded(
                        child: _Dropdown<SupplyType>(
                          title: 'النوع',
                          value: formType,
                          items: SupplyType.values,
                          labelOf: (t) => t.toDisplayString(),
                          onChanged: (v) => setState(() => formType = v!),
                        ),
                      ),
                      Expanded(
                        child: AppInput(
                          title: 'الجهة',
                          controller: belongToController,
                        ),
                      ),
                    ],
                  ),

                  // ---- Input Row 2: tPrice / pPrice / date / notes / actions
                  Row(
                    spacing: 16,
                    children: [
                      Expanded(
                        child: AppInput(
                          title: 'السعر الكلي',
                          controller: tPriceController,
                          isPrice: true,
                          inputType: TextInputType.number,
                          direction: TextDirection.ltr,
                        ),
                      ),
                      Expanded(
                        child: AppInput(
                          title: 'المدفوع',
                          controller: pPriceController,
                          isPrice: true,
                          inputType: TextInputType.number,
                          direction: TextDirection.ltr,
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
                          title: 'الملاحظات',
                          controller: notesController,
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

                  // ---- Filter Row: type / belongTo / search ----
                  BlocBuilder<SuppliesCubit, SuppliesState>(
                    builder: (context, state) {
                      final belongTos = _belongToOptions(state.supplies);
                      if (filterBelongTo != null &&
                          !belongTos.contains(filterBelongTo)) {
                        filterBelongTo = null;
                      }
                      return Row(
                        spacing: 8,
                        children: [
                          SizedBox(
                            width: 180,
                            child: _Dropdown<SupplyType?>(
                              title: 'تصفية النوع',
                              value: filterType,
                              items: [null, ...SupplyType.values],
                              labelOf: (t) =>
                                  t == null ? 'الكل' : t.toDisplayString(),
                              onChanged: (v) => setState(() => filterType = v),
                            ),
                          ),
                          SizedBox(
                            width: 220,
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
                          if (filterType != null ||
                              filterBelongTo != null ||
                              searchController.text.isNotEmpty)
                            InkWell(
                              onTap: () => setState(() {
                                filterType = null;
                                filterBelongTo = null;
                                searchController.clear();
                              }),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[300],
                                ),
                                child: const Icon(Icons.clear, color: _kAccent),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  // ---- Table ----
                  BlocBuilder<SuppliesCubit, SuppliesState>(
                    builder: (context, state) {
                      if (state.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final rows = _suppliesToRows(
                        _applyFilters(state.supplies),
                      );
                      return SHTable(
                        controller: tableController,
                        direction: TextDirection.rtl,
                        hasIndex: true,
                        indexLabel: 'ت',
                        pagination: true,
                        columns: _columns,
                        rows: rows,
                      );
                    },
                  ),

                  // ---- Stats Footer ----
                  BlocBuilder<SuppliesCubit, SuppliesState>(
                    builder: (context, state) {
                      final visible = _applyFilters(state.supplies);
                      final total = visible.fold<int>(
                        0,
                        (sum, s) => sum + s.tPrice,
                      );
                      final paid = visible.fold<int>(
                        0,
                        (sum, s) => sum + s.pPrice,
                      );
                      final remaining = visible.fold<int>(
                        0,
                        (sum, s) => sum + s.remaining,
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
                              label: 'الإجمالي',
                              value: PriceUtils.addCommas(total),
                            ),
                            _StatItem(
                              label: 'المدفوع',
                              value: PriceUtils.addCommas(paid),
                            ),
                            _StatItem(
                              label: 'المتبقي',
                              value: PriceUtils.addCommas(remaining),
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

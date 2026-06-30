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
import 'package:taif_alamin/data/models/item_model.dart';
import 'package:taif_alamin/presentation/cubits/items_cubit/item_cubit.dart';
import 'package:taif_alamin/presentation/cubits/items_cubit/item_state.dart';
import 'package:taif_alamin/utils/price_utils.dart';
import 'package:taif_alamin/utils/snack_bar_util.dart';
import 'package:taif_alamin/widgets/app_primary_button.dart';
import 'package:taif_alamin/widgets/general/app_action_buttons.dart';
import 'package:taif_alamin/widgets/general/app_input.dart';

const _kAccent = Color(0xFF003763);

/// Second screen: shows only the items of a fixed category ([belongTo]).
class ItemsDataScreen extends StatefulWidget {
  final String belongTo;
  final String title;

  const ItemsDataScreen({
    super.key,
    required this.belongTo,
    required this.title,
  });

  @override
  State<ItemsDataScreen> createState() => _ItemsDataScreenState();
}

class _ItemsDataScreenState extends State<ItemsDataScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController countController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final SHTableController tableController = SHTableController();

  int? editingId;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    context.read<ItemsCubit>().loadByBelongTo(widget.belongTo);
  }

  @override
  void dispose() {
    nameController.dispose();
    countController.dispose();
    priceController.dispose();
    dateController.dispose();
    tableController.dispose();
    super.dispose();
  }

  final List<SHColumn> _columns = [
    SHColumn(id: 'id', title: 'الرقم', weight: 1, isNumeric: true, hidden: true),
    SHColumn(id: 'item_name', title: 'الصنف', weight: 4),
    SHColumn(id: 'count', title: 'العدد', weight: 2, isNumeric: true),
    SHColumn(
      id: 'price',
      title: 'السعر',
      weight: 3,
      isNumeric: true,
      priceFormat: true,
    ),
    SHColumn(
      id: 'total',
      title: 'الإجمالي',
      weight: 3,
      isNumeric: true,
      priceFormat: true,
    ),
    SHColumn(id: 'date', title: 'التاريخ', weight: 3),
  ];

  /// Display a count without a trailing `.0` for whole numbers.
  String _fmtCount(double c) =>
      c == c.roundToDouble() ? c.toInt().toString() : c.toString();

  List<Map<String, String>> _toRows(List<Item> items) {
    return items.map((i) {
      return {
        'id': i.id.toString(),
        'item_name': i.itemName ?? '',
        'count': _fmtCount(i.count),
        'price': i.price.toString(),
        'total': i.total.toString(),
        'date': _formatDate(i.date),
      };
    }).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          selectedDate ?? DateTime.tryParse(dateController.text) ?? DateTime.now(),
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
    final name = nameController.text.trim();
    final count = double.tryParse(countController.text.replaceAll(',', '').trim());
    final price = int.tryParse(priceController.text.replaceAll(',', '').trim());

    if (name.isEmpty) {
      SnackBarUtil.showError(context, 'أدخل اسم الصنف');
      return;
    }
    if (count == null || count <= 0) {
      SnackBarUtil.showError(context, 'أدخل عدداً صحيحاً');
      return;
    }
    if (price == null || price <= 0) {
      SnackBarUtil.showError(context, 'أدخل سعراً صحيحاً');
      return;
    }
    if (selectedDate == null) {
      SnackBarUtil.showError(context, 'اختر تاريخاً');
      return;
    }

    final item = Item(
      id: editingId ?? 0,
      itemName: name,
      count: count,
      price: price,
      date: selectedDate!,
      belongTo: widget.belongTo, // locked
    );

    final cubit = context.read<ItemsCubit>();
    if (editingId != null) {
      cubit.update(item);
    } else {
      cubit.add(item);
    }
    _clearForm();
  }

  void _clearForm() {
    nameController.clear();
    countController.clear();
    priceController.clear();
    dateController.clear();
    selectedDate = null;
    editingId = null;
    if (mounted) setState(() {});
  }

  void _editItem(Item i) {
    nameController.text = i.itemName ?? '';
    countController.text = _fmtCount(i.count);
    priceController.text = i.price.toString();
    dateController.text = _formatDate(i.date);
    selectedDate = i.date;
    editingId = i.id;
    if (mounted) setState(() {});
  }

  void _deleteSelected() {
    final selected = tableController.selectedIndexes;
    if (selected.isEmpty) {
      SnackBarUtil.showError(context, 'اختر عنصراً واحداً على الأقل');
      return;
    }

    final cubit = context.read<ItemsCubit>();
    final list = cubit.state.items;

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
                if (idx < list.length) cubit.delete(list[idx].id);
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

    final list = context.read<ItemsCubit>().state.items;
    final idx = selected.first;
    if (idx < list.length) _editItem(list[idx]);
  }

  void _handleDuplicate() {
    final selected = tableController.selectedIndexes;
    if (selected.isEmpty) {
      SnackBarUtil.showError(context, 'اختر عنصراً للنسخ');
      return;
    }

    final cubit = context.read<ItemsCubit>();
    final list = cubit.state.items;

    for (final idx in selected) {
      if (idx < list.length) {
        cubit.add(list[idx].copyWith(id: 0, date: DateTime.now()));
      }
    }
  }

  void _exportToExcel() async {
    final result = await getSaveLocation(
      suggestedName:
          'items_${widget.belongTo}_${DateTime.now().year}-${DateTime.now().month}.xlsx',
      acceptedTypeGroups: [
        const XTypeGroup(label: 'Excel', extensions: ['xlsx']),
      ],
    );
    if (result == null || !mounted) return;

    try {
      final rows = _toRows(context.read<ItemsCubit>().state.items);

      final excel = xlsx.Excel.createExcel();
      final sheet = excel['Sheet1'];

      sheet.appendRow([
        xlsx.TextCellValue('الرقم'),
        xlsx.TextCellValue('الصنف'),
        xlsx.TextCellValue('العدد'),
        xlsx.TextCellValue('السعر'),
        xlsx.TextCellValue('الإجمالي'),
        xlsx.TextCellValue('التاريخ'),
      ]);

      for (final row in rows) {
        sheet.appendRow([
          xlsx.TextCellValue(row['id'] ?? ''),
          xlsx.TextCellValue(row['item_name'] ?? ''),
          xlsx.TextCellValue(row['count'] ?? ''),
          xlsx.TextCellValue(row['price'] ?? ''),
          xlsx.TextCellValue(row['total'] ?? ''),
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
          body: BlocListener<ItemsCubit, ItemsState>(
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
                  // ---- Title (category) ----
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

                  // ---- Form row ----
                  Row(
                    spacing: 16,
                    children: [
                      Expanded(
                        flex: 2,
                        child: AppInput(
                          title: 'اسم الصنف',
                          controller: nameController,
                        ),
                      ),
                      Expanded(
                        child: AppInput(
                          title: 'العدد',
                          controller: countController,
                          inputType: TextInputType.number,
                          direction: TextDirection.ltr,
                        ),
                      ),
                      Expanded(
                        child: AppInput(
                          title: 'السعر',
                          controller: priceController,
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

                  // ---- Table ----
                  BlocBuilder<ItemsCubit, ItemsState>(
                    builder: (context, state) {
                      if (state.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return SHTable(
                        controller: tableController,
                        direction: TextDirection.rtl,
                        hasIndex: true,
                        indexLabel: 'ت',
                        pagination: true,
                        columns: _columns,
                        rows: _toRows(state.items),
                      );
                    },
                  ),

                  // ---- Stats footer ----
                  BlocBuilder<ItemsCubit, ItemsState>(
                    builder: (context, state) {
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
                              label: 'إجمالي القيمة',
                              value: PriceUtils.addCommas(state.totalValue),
                            ),
                            _StatItem(
                              label: 'إجمالي العدد',
                              value: _fmtCount(state.totalCount),
                            ),
                            _StatItem(label: 'الأصناف', value: '${state.count}'),
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
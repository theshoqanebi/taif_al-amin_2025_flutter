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
import 'package:taif_alamin/data/models/transport_model.dart';
import 'package:taif_alamin/presentation/cubits/transport_cubit/transport_cubit.dart';
import 'package:taif_alamin/presentation/cubits/transport_cubit/transport_state.dart';
import 'package:taif_alamin/utils/price_utils.dart';
import 'package:taif_alamin/utils/snack_bar_util.dart';
import 'package:taif_alamin/widgets/app_primary_button.dart';
import 'package:taif_alamin/widgets/general/app_action_buttons.dart';
import 'package:taif_alamin/widgets/general/app_input.dart';

class TransportScreen extends StatefulWidget {
  const TransportScreen({super.key});

  @override
  State<TransportScreen> createState() => _TransportScreenState();
}

class _TransportScreenState extends State<TransportScreen> {
  final TextEditingController priceController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final SHTableController tableController = SHTableController();

  int? editingId;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    context.read<TransportCubit>().loadAll();
  }

  @override
  void dispose() {
    priceController.dispose();
    dateController.dispose();
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
    SHColumn(
      id: 'price',
      title: 'السعر',
      weight: 3,
      isNumeric: true,
      priceFormat: true,
    ),
    SHColumn(id: 'date', title: 'التاريخ', weight: 3, isNumeric: false),
    SHColumn(id: 'notes', title: 'الملاحظات', weight: 4, isNumeric: false),
  ];

  /// Convert Transport list to table rows
  List<Map<String, String>> _transportToRows(List<Transport> transports) {
    return transports.map((t) {
      return {
        'id': t.id.toString(),
        'price': t.price.toString(),
        'date': _formatDate(t.date),
        'notes': t.notes ?? '',
      };
    }).toList();
  }

  /// Format DateTime to display
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Pick date from user
  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
        dateController.text = _formatDate(pickedDate);
      });
    }
  }

  /// Save or update transport
  void _saveTransport() {
    final priceText = priceController.text.replaceAll(',', '').trim();
    final price = int.tryParse(priceText);

    if (price == null || price <= 0) {
      SnackBarUtil.showError(context, 'أدخل سعراً صحيحاً');
      return;
    }

    if (selectedDate == null) {
      SnackBarUtil.showError(context, 'اختر تاريخاً');
      return;
    }

    final transport = Transport(
      id: editingId ?? 0,
      price: price,
      date: selectedDate!,
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
    );

    if (editingId != null) {
      context.read<TransportCubit>().update(transport);
    } else {
      context.read<TransportCubit>().add(transport);
    }

    _clearForm();
  }

  /// Clear form and reset edit mode
  void _clearForm() {
    priceController.clear();
    dateController.clear();
    notesController.clear();
    searchController.clear();
    selectedDate = null;
    editingId = null;
    if (mounted) setState(() {});
  }

  /// Fill form with selected transport for editing
  void _editTransport(Transport transport) {
    priceController.text = transport.price.toString();
    dateController.text = _formatDate(transport.date);
    notesController.text = transport.notes ?? '';
    selectedDate = transport.date;
    editingId = transport.id;
    if (mounted) setState(() {});
  }

  /// Delete selected transports
  void _deleteSelected() {
    final selectedIndexes = tableController.selectedIndexes;
    if (selectedIndexes.isEmpty) {
      SnackBarUtil.showError(context, 'اختر عنصراً واحداً على الأقل');
      return;
    }

    final cubit = context.read<TransportCubit>();
    final state = cubit.state;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف ${selectedIndexes.length} عنصر؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              for (final idx in selectedIndexes) {
                if (idx < state.transports.length) {
                  cubit.delete(state.transports[idx].id);
                }
              }
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  /// Handle edit button
  void _handleEdit() {
    final selectedIndexes = tableController.selectedIndexes;

    if (selectedIndexes.isEmpty) {
      SnackBarUtil.showError(context, EditMessages.emptySelection);
      return;
    }

    if (selectedIndexes.length > 1) {
      SnackBarUtil.showError(context, EditMessages.multipleSelection);
      return;
    }

    // ✅ FIX: Capture state BEFORE using it
    final state = context.read<TransportCubit>().state;
    final selectedIndex = selectedIndexes.first;

    if (selectedIndex < state.transports.length) {
      _editTransport(state.transports[selectedIndex]);
    }
  }

  /// Handle duplicate
  void _handleDuplicate() {
    final selectedIndexes = tableController.selectedIndexes;
    if (selectedIndexes.isEmpty) {
      SnackBarUtil.showError(context, 'اختر عنصراً للنسخ');
      return;
    }

    // ✅ FIX: Capture cubit BEFORE loop
    final cubit = context.read<TransportCubit>();
    final state = cubit.state;

    for (final idx in selectedIndexes) {
      if (idx < state.transports.length) {
        final original = state.transports[idx];
        final duplicate = Transport(
          id: 0,
          price: original.price,
          date: DateTime.now(),
          notes: original.notes,
        );
        cubit.add(duplicate);
      }
    }
  }

  /// Export to Excel
  void _exportToExcel() async {
    final FileSaveLocation? result = await getSaveLocation(
      suggestedName:
          'transport_${DateTime.now().year}-${DateTime.now().month}.xlsx',
      acceptedTypeGroups: [
        const XTypeGroup(label: 'Excel', extensions: ['xlsx']),
      ],
    );

    if (result == null) return;
    if (!mounted) return;

    try {
      final cubit = context.read<TransportCubit>();
      final state = cubit.state;
      final rows = _transportToRows(state.transports);

      final excel = xlsx.Excel.createExcel();
      final sheet = excel['Sheet1'];

      sheet.appendRow([
        xlsx.TextCellValue('الرقم'),
        xlsx.TextCellValue('السعر'),
        xlsx.TextCellValue('التاريخ'),
        xlsx.TextCellValue('الملاحظات'),
      ]);

      for (final row in rows) {
        sheet.appendRow([
          xlsx.TextCellValue(row['id'] ?? ''),
          xlsx.TextCellValue(row['price'] ?? ''),
          xlsx.TextCellValue(row['date'] ?? ''),
          xlsx.TextCellValue(row['notes'] ?? ''),
        ]);
      }

      final fileBytes = excel.encode();
      if (fileBytes == null) throw Exception('Failed to encode');
      final bytes = Uint8List.fromList(fileBytes);
      await File(result.path).writeAsBytes(bytes);

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
          body: BlocListener<TransportCubit, TransportState>(
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
                  // Input Row
                  Row(
                    spacing: 16,
                    children: [
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
                      Expanded(
                        child: AppInput(
                          title: 'الملاحظات',
                          controller: notesController,
                          inputType: TextInputType.text,
                        ),
                      ),
                      // Save/Update Button
                      AppPrimaryButton(
                        text: editingId != null ? 'تعديل' : 'إضافة',
                        onPressed: _saveTransport,
                      ),
                      // Cancel Button (show only in edit mode)
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

                  // Search & Settings Row
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: AppInput(
                          title: 'بحث',
                          controller: searchController,
                          onChanged: (value) {
                            if (mounted) setState(() {});
                          },
                          suffixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF003763),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _showStatsDialog(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFF003763),
                          ),
                          child: const Icon(Icons.info, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  BlocBuilder<TransportCubit, TransportState>(
                    builder: (context, state) {
                      if (state.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final rows = _transportToRows(state.transports);

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

                  // Stats Footer
                  BlocBuilder<TransportCubit, TransportState>(
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
                              label: 'الإجمالي',
                              value:
                                  'IQD ${PriceUtils.addCommas(state.totalPrice)}',
                            ),
                            _StatItem(
                              label: 'المتوسط',
                              value:
                                  'IQD ${PriceUtils.addCommas(state.averagePrice)}',
                            ),
                            _StatItem(label: 'العدد', value: '${state.count}'),
                            _StatItem(
                              label: 'الأعلى',
                              value:
                                  'IQD ${PriceUtils.addCommas(state.mostExpensive?.price ?? 0)}',
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

  /// Show statistics dialog
  void _showStatsDialog() {
    final state = context.read<TransportCubit>().state;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إحصائيات النقل'),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('عدد الشحنات: ${state.count}'),
              const SizedBox(height: 8),
              Text(
                'إجمالي التكلفة: IQD ${PriceUtils.addCommas(state.totalPrice)}',
              ),
              const SizedBox(height: 8),
              Text(
                'متوسط التكلفة: IQD ${PriceUtils.addCommas(state.averagePrice)}',
              ),
              const SizedBox(height: 8),
              Text(
                'أعلى تكلفة: IQD ${PriceUtils.addCommas(state.mostExpensive?.price ?? 0)}',
              ),
              const SizedBox(height: 8),
              Text(
                'أقل تكلفة: IQD ${PriceUtils.addCommas(state.leastExpensive?.price ?? 0)}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
}

/// Helper widget for stats display
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

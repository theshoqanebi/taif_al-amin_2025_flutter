import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xlsx;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shtable/shtable.dart';
import 'package:taif_alamin/app_window.dart';
import 'package:taif_alamin/data/constants/edit_messages.dart';
import 'package:taif_alamin/data/models/models_model.dart';
import 'package:taif_alamin/presentation/cubits/sells_models_cubit.dart';
import 'package:taif_alamin/utils/snack_bar_util.dart';
import 'package:taif_alamin/utils/uuid_utils.dart';
import 'package:taif_alamin/widgets/app_primary_button.dart';
import 'package:taif_alamin/widgets/general/app_action_buttons.dart';
import 'package:taif_alamin/widgets/general/app_input.dart';

class SellsModelsScreen extends StatefulWidget {
  const SellsModelsScreen({super.key});

  @override
  State<SellsModelsScreen> createState() => _SellsModelsScreenState();
}

class _SellsModelsScreenState extends State<SellsModelsScreen> {
  final nameController = TextEditingController();
  final tenController = TextEditingController();
  final eightController = TextEditingController();
  final sevenController = TextEditingController();
  final threeController = TextEditingController();
  final twoController = TextEditingController();
  final chairController = TextEditingController();
  final diwanController = TextEditingController();
  final searchController = TextEditingController();

  final SHTableController tableController = SHTableController();

  String? editingUuid;

  @override
  void initState() {
    super.initState();
    context.read<SellsModelsCubit>().loadModels();
  }

  @override
  void dispose() {
    nameController.dispose();
    tenController.dispose();
    eightController.dispose();
    sevenController.dispose();
    threeController.dispose();
    twoController.dispose();
    chairController.dispose();
    diwanController.dispose();
    searchController.dispose();
    tableController.dispose();
    super.dispose();
  }

  final List<SHColumn> _columns = [
    SHColumn(id: 'name', title: 'الموديل', weight: 4),
    SHColumn(id: 'ten', title: '10 مقاعد', weight: 2, isNumeric: true, priceFormat: true),
    SHColumn(id: 'eight', title: '8 مقاعد', weight: 2, isNumeric: true, priceFormat: true),
    SHColumn(id: 'seven', title: '7 مقاعد', weight: 2, isNumeric: true, priceFormat: true),
    SHColumn(id: 'three', title: 'ثلاثية', weight: 2, isNumeric: true, priceFormat: true),
    SHColumn(id: 'two', title: 'ثنائية', weight: 2, isNumeric: true, priceFormat: true),
    SHColumn(id: 'chair', title: 'كرسي', weight: 2, isNumeric: true, priceFormat: true),
    SHColumn(id: 'diwan', title: 'ديوان', weight: 2, isNumeric: true, priceFormat: true),
  ];

  List<Map<String, String>> _toRows(List<SellsModel> models) {
    final q = searchController.text.trim();
    final list = q.isEmpty
        ? models
        : models.where((m) => m.name.contains(q)).toList();
    return list
        .map(
          (m) => {
            'uuid': m.uuid,
            'name': m.name,
            'ten': m.tenChairs.toString(),
            'eight': m.eightChairs.toString(),
            'seven': m.sevenChairs.toString(),
            'three': m.three.toString(),
            'two': m.two.toString(),
            'chair': m.chair.toString(),
            'diwan': m.diwan.toString(),
          },
        )
        .toList();
  }

  int _parse(TextEditingController c) =>
      int.tryParse(c.text.replaceAll(',', '').trim()) ?? 0;

  void _save() {
    if (nameController.text.trim().isEmpty) {
      SnackBarUtil.showError(context, 'أدخل اسم الموديل');
      return;
    }

    final model = SellsModel(
      id: 0,
      name: nameController.text.trim(),
      uuid: editingUuid ?? UuidUtils.v4(),
      tenChairs: _parse(tenController),
      eightChairs: _parse(eightController),
      sevenChairs: _parse(sevenController),
      three: _parse(threeController),
      two: _parse(twoController),
      chair: _parse(chairController),
      diwan: _parse(diwanController),
    );

    final cubit = context.read<SellsModelsCubit>();
    if (editingUuid != null) {
      cubit.edit(model); // append revision
    } else {
      cubit.add(model);
    }
    _clearForm();
  }

  void _clearForm() {
    nameController.clear();
    tenController.clear();
    eightController.clear();
    sevenController.clear();
    threeController.clear();
    twoController.clear();
    chairController.clear();
    diwanController.clear();
    editingUuid = null;
    if (mounted) setState(() {});
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

    final models = context.read<SellsModelsCubit>().state.models;
    final rows = _toRows(models);
    final idx = selected.first;
    if (idx >= rows.length) return;

    final uuid = rows[idx]['uuid'];
    final m = models.firstWhere((e) => e.uuid == uuid);

    setState(() {
      editingUuid = m.uuid;
      nameController.text = m.name;
      tenController.text = m.tenChairs.toString();
      eightController.text = m.eightChairs.toString();
      sevenController.text = m.sevenChairs.toString();
      threeController.text = m.three.toString();
      twoController.text = m.two.toString();
      chairController.text = m.chair.toString();
      diwanController.text = m.diwan.toString();
    });
  }

  void _handleDelete() {
    final selected = tableController.selectedIndexes;
    if (selected.isEmpty) {
      SnackBarUtil.showError(context, 'اختر عنصراً للحذف');
      return;
    }

    final cubit = context.read<SellsModelsCubit>();
    final models = cubit.state.models;
    final rows = _toRows(models);

    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('سيتم حذف ${selected.length} موديل، تأكيد؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                for (final idx in selected) {
                  if (idx < rows.length) {
                    cubit.remove(rows[idx]['uuid']!);
                  }
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

  Future<void> _exportToExcel() async {
    final result = await getSaveLocation(
      suggestedName:
          'sells_models_${DateTime.now().year}-${DateTime.now().month}.xlsx',
      acceptedTypeGroups: [
        const XTypeGroup(label: 'Excel', extensions: ['xlsx']),
      ],
    );
    if (result == null || !mounted) return;
    try {
      final state = context.read<SellsModelsCubit>().state;
      final rows = _toRows(state.models);
      final excel = xlsx.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow([
        xlsx.TextCellValue('الموديل'),
        xlsx.TextCellValue('10 مقاعد'),
        xlsx.TextCellValue('8 مقاعد'),
        xlsx.TextCellValue('7 مقاعد'),
        xlsx.TextCellValue('ثلاثية'),
        xlsx.TextCellValue('ثنائية'),
        xlsx.TextCellValue('كرسي'),
        xlsx.TextCellValue('ديوان'),
      ]);
      for (final r in rows) {
        sheet.appendRow([
          xlsx.TextCellValue(r['name'] ?? ''),
          xlsx.TextCellValue(r['ten'] ?? ''),
          xlsx.TextCellValue(r['eight'] ?? ''),
          xlsx.TextCellValue(r['seven'] ?? ''),
          xlsx.TextCellValue(r['three'] ?? ''),
          xlsx.TextCellValue(r['two'] ?? ''),
          xlsx.TextCellValue(r['chair'] ?? ''),
          xlsx.TextCellValue(r['diwan'] ?? ''),
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
          body: BlocConsumer<SellsModelsCubit, SellsModelsState>(
            listener: (context, state) {
              if (state.hasError) {
                SnackBarUtil.showError(context, state.error ?? 'حدث خطأ');
              }
            },
            builder: (context, state) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  spacing: 12,
                  children: [
                    Row(
                      spacing: 10,
                      children: [
                        Expanded(
                          flex: 3,
                          child: AppInput(
                            title: 'الموديل',
                            controller: nameController,
                          ),
                        ),
                        Expanded(child: _priceInput('10 مقاعد', tenController)),
                        Expanded(child: _priceInput('8 مقاعد', eightController)),
                        Expanded(child: _priceInput('7 مقاعد', sevenController)),
                      ],
                    ),
                    Row(
                      spacing: 10,
                      children: [
                        Expanded(child: _priceInput('ثلاثية', threeController)),
                        Expanded(child: _priceInput('ثنائية', twoController)),
                        Expanded(child: _priceInput('كرسي', chairController)),
                        Expanded(child: _priceInput('ديوان', diwanController)),
                        AppPrimaryButton(
                          text: editingUuid != null ? 'تعديل' : 'إضافة',
                          onPressed: _save,
                        ),
                        if (editingUuid != null)
                          OutlinedButton(
                            onPressed: _clearForm,
                            child: const Text('إلغاء'),
                          ),
                      ],
                    ),
                    AppInput(
                      title: 'بحث',
                      controller: searchController,
                      onChanged: (_) {
                        if (mounted) setState(() {});
                      },
                      suffixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF003763),
                      ),
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
                          rows: _toRows(state.models),
                        ),
                      ),
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
              onDuplicate: () =>
                  SnackBarUtil.showError(context, 'النسخ غير مدعوم'),
              onExport: _exportToExcel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceInput(String title, TextEditingController c) {
    return AppInput(
      title: title,
      controller: c,
      isPrice: true,
      inputType: TextInputType.number,
      direction: TextDirection.ltr,
    );
  }
}

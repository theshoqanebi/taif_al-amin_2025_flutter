import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xlsx;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shtable/shtable.dart';
import 'package:taif_alamin/presentation/cubits/exhibitions_models_cubit/exhibitions_models_cubit.dart';
import 'package:taif_alamin/presentation/cubits/exhibitions_models_cubit/exhibitions_models_state.dart';
import 'package:uuid/uuid.dart';
import 'package:taif_alamin/app_window.dart';
import 'package:taif_alamin/data/constants/edit_messages.dart';
import 'package:taif_alamin/data/models/exhibitions_model_model.dart';
import 'package:taif_alamin/utils/snack_bar_util.dart';
import 'package:taif_alamin/widgets/app_primary_button.dart';
import 'package:taif_alamin/widgets/general/app_action_buttons.dart';
import 'package:taif_alamin/widgets/general/app_input.dart';

const _kAccent = Color(0xFF003763);

/// Manage the exhibition price book (ExhibitionsModels) for one showroom.
class ExhibitionsModelsScreen extends StatefulWidget {
  final String belongTo;
  final String title;

  const ExhibitionsModelsScreen({
    super.key,
    required this.belongTo,
    required this.title,
  });

  @override
  State<ExhibitionsModelsScreen> createState() =>
      _ExhibitionsModelsScreenState();
}

class _ExhibitionsModelsScreenState extends State<ExhibitionsModelsScreen> {
  final nameController = TextEditingController();
  final sevenController = TextEditingController();
  final eightController = TextEditingController();
  final tenController = TextEditingController();
  final twoController = TextEditingController();
  final threeController = TextEditingController();
  final chairController = TextEditingController();
  final diwanController = TextEditingController();
  final SHTableController tableController = SHTableController();

  int? editingId;
  String? editingUuid; // present => editing => append revision

  @override
  void initState() {
    super.initState();
    context.read<ExhibitionsModelsCubit>().loadModels(
      belongTo: widget.belongTo,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    sevenController.dispose();
    eightController.dispose();
    tenController.dispose();
    twoController.dispose();
    threeController.dispose();
    chairController.dispose();
    diwanController.dispose();
    tableController.dispose();
    super.dispose();
  }

  final List<SHColumn> _columns = [
    SHColumn(id: 'id', title: 'id', weight: 1, hidden: true),
    SHColumn(id: 'name', title: 'الموديل', weight: 3),
    SHColumn(
      id: 'seven',
      title: '٧ مقاعد',
      weight: 2,
      isNumeric: true,
      priceFormat: true,
    ),
    SHColumn(
      id: 'eight',
      title: '٨ مقاعد',
      weight: 2,
      isNumeric: true,
      priceFormat: true,
    ),
    SHColumn(
      id: 'ten',
      title: '١٠ مقاعد',
      weight: 2,
      isNumeric: true,
      priceFormat: true,
    ),
    SHColumn(
      id: 'two',
      title: 'ثنائية',
      weight: 2,
      isNumeric: true,
      priceFormat: true,
    ),
    SHColumn(
      id: 'three',
      title: 'ثلاثية',
      weight: 2,
      isNumeric: true,
      priceFormat: true,
    ),
    SHColumn(
      id: 'chair',
      title: 'كرسي',
      weight: 2,
      isNumeric: true,
      priceFormat: true,
    ),
    SHColumn(
      id: 'diwan',
      title: 'ديوان',
      weight: 2,
      isNumeric: true,
      priceFormat: true,
    ),
  ];

  List<Map<String, String>> _toRows(List<ExhibitionsModel> models) {
    return models
        .map(
          (m) => {
            'id': m.id.toString(),
            'name': m.name,
            'seven': m.sevenChairs.toString(),
            'eight': m.eightChairs.toString(),
            'ten': m.tenChairs.toString(),
            'two': m.two.toString(),
            'three': m.three.toString(),
            'chair': m.chair.toString(),
            'diwan': m.diwan.toString(),
          },
        )
        .toList();
  }

  int _p(TextEditingController c) =>
      int.tryParse(c.text.replaceAll(',', '').trim()) ?? 0;

  void _save() {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      SnackBarUtil.showError(context, 'أدخل اسم الموديل');
      return;
    }

    final model = ExhibitionsModel(
      id: 0,
      name: name,
      // editing keeps the same uuid (append-only revision); new => fresh uuid
      uuid: editingUuid ?? const Uuid().v4(),
      sevenChairs: _p(sevenController),
      eightChairs: _p(eightController),
      tenChairs: _p(tenController),
      two: _p(twoController),
      three: _p(threeController),
      chair: _p(chairController),
      diwan: _p(diwanController),
      belongTo: widget.belongTo,
    );

    final cubit = context.read<ExhibitionsModelsCubit>();
    if (editingUuid != null) {
      cubit.edit(model);
    } else {
      cubit.add(model);
    }
    _clearForm();
  }

  void _clearForm() {
    nameController.clear();
    sevenController.clear();
    eightController.clear();
    tenController.clear();
    twoController.clear();
    threeController.clear();
    chairController.clear();
    diwanController.clear();
    editingId = null;
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
    final models = context.read<ExhibitionsModelsCubit>().state.models;
    final idx = selected.first;
    if (idx >= models.length) return;
    final m = models[idx];
    setState(() {
      editingId = m.id;
      editingUuid = m.uuid;
      nameController.text = m.name;
      sevenController.text = m.sevenChairs.toString();
      eightController.text = m.eightChairs.toString();
      tenController.text = m.tenChairs.toString();
      twoController.text = m.two.toString();
      threeController.text = m.three.toString();
      chairController.text = m.chair.toString();
      diwanController.text = m.diwan.toString();
    });
  }

  void _handleDelete() {
    final selected = tableController.selectedIndexes;
    if (selected.isEmpty) {
      SnackBarUtil.showError(context, 'اختر موديلاً واحداً على الأقل');
      return;
    }
    final cubit = context.read<ExhibitionsModelsCubit>();
    final models = cubit.state.models;
    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('سيتم إخفاء ${selected.length} موديل، تأكيد؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                for (final idx in selected) {
                  if (idx < models.length) cubit.remove(models[idx].uuid);
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
          'models_${widget.belongTo}_${DateTime.now().year}-${DateTime.now().month}.xlsx',
      acceptedTypeGroups: [
        const XTypeGroup(label: 'Excel', extensions: ['xlsx']),
      ],
    );
    if (result == null || !mounted) return;
    try {
      final state = context.read<ExhibitionsModelsCubit>().state;
      final rows = _toRows(state.models);
      final excel = xlsx.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow([
        xlsx.TextCellValue('الموديل'),
        xlsx.TextCellValue('٧ مقاعد'),
        xlsx.TextCellValue('٨ مقاعد'),
        xlsx.TextCellValue('١٠ مقاعد'),
        xlsx.TextCellValue('ثنائية'),
        xlsx.TextCellValue('ثلاثية'),
        xlsx.TextCellValue('كرسي'),
        xlsx.TextCellValue('ديوان'),
      ]);
      for (final r in rows) {
        sheet.appendRow([
          xlsx.TextCellValue(r['name'] ?? ''),
          xlsx.TextCellValue(r['seven'] ?? ''),
          xlsx.TextCellValue(r['eight'] ?? ''),
          xlsx.TextCellValue(r['ten'] ?? ''),
          xlsx.TextCellValue(r['two'] ?? ''),
          xlsx.TextCellValue(r['three'] ?? ''),
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
          body: BlocConsumer<ExhibitionsModelsCubit, ExhibitionsModelsState>(
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
                    Row(
                      children: [
                        Text(
                          'موديلات: ${widget.title}',
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _kAccent,
                          ),
                        ),
                      ],
                    ),

                    // name
                    Row(
                      spacing: 12,
                      children: [
                        Expanded(
                          flex: 2,
                          child: AppInput(
                            title: 'اسم الموديل',
                            controller: nameController,
                          ),
                        ),
                        Expanded(child: _price('٧ مقاعد', sevenController)),
                        Expanded(child: _price('٨ مقاعد', eightController)),
                        Expanded(child: _price('١٠ مقاعد', tenController)),
                      ],
                    ),

                    // prices
                    Row(
                      spacing: 12,
                      children: [
                        Expanded(child: _price('ثنائية', twoController)),
                        Expanded(child: _price('ثلاثية', threeController)),
                        Expanded(child: _price('كرسي', chairController)),
                        Expanded(child: _price('ديوان', diwanController)),
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
                        rows: _toRows(state.models),
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

  Widget _price(String title, TextEditingController c) => AppInput(
    title: title,
    controller: c,
    isPrice: true,
    inputType: TextInputType.number,
    direction: TextDirection.ltr,
  );
}

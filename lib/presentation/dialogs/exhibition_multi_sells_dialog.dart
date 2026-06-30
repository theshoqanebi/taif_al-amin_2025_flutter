import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shtable/shtable.dart';
import 'package:taif_alamin/data/models/exhibition_multi_sell_model.dart';
import 'package:taif_alamin/data/models/exhibitions_model_model.dart';
import 'package:taif_alamin/data/models/multi_sells_model.dart' show SellType;
import 'package:taif_alamin/data/repositories/exhibitions_models_repository.dart';
import 'package:taif_alamin/presentation/cubits/exhibitions_cubit/exhibitions_cubit.dart';
import 'package:taif_alamin/presentation/cubits/exhibitions_cubit/exhibitions_state.dart';
import 'package:taif_alamin/presentation/cubits/exhibitions_models_cubit/exhibitions_models_cubit.dart';
import 'package:taif_alamin/presentation/cubits/exhibitions_models_cubit/exhibitions_models_state.dart';
import 'package:taif_alamin/utils/price_utils.dart';
import 'package:taif_alamin/utils/snack_bar_util.dart';
import 'package:taif_alamin/widgets/app_primary_button.dart';
import 'package:taif_alamin/widgets/general/app_input.dart';

/// Manage the furniture line-items of an exhibition. Price is resolved from
/// the chosen [ExhibitionsModel] and type. Reads/writes [ExhibitionsCubit].
class ExhibitionMultiSellsDialog extends StatefulWidget {
  final String bill;
  const ExhibitionMultiSellsDialog({required this.bill, super.key});

  @override
  State<ExhibitionMultiSellsDialog> createState() =>
      _ExhibitionMultiSellsDialogState();
}

class _ExhibitionMultiSellsDialogState
    extends State<ExhibitionMultiSellsDialog> {
  final colorController = TextEditingController();
  final countController = TextEditingController();
  final SHTableController tableController = SHTableController();
  final ExhibitionsModelsRepository _modelsRepo = ExhibitionsModelsRepository();

  ExhibitionsModel? selectedModel;
  SellType selectedType = SellType.set;
  int? setNumber;
  int? chairCount;
  int? editingIndex;
  int _formVersion = 0;

  /// Set when the line item being edited references a model revision that
  /// is no longer in the active price-book list (the model was revised or
  /// hidden after this item was added). Kept around so the dropdown still
  /// has a matching entry to select and shows the correct historical price,
  /// instead of silently falling back to an unrelated model.
  ExhibitionsModel? _staleModelOption;

  @override
  void dispose() {
    colorController.dispose();
    countController.dispose();
    tableController.dispose();
    super.dispose();
  }

  final List<SHColumn> _columns = [
    SHColumn(id: 'model', title: 'الموديل', weight: 4),
    SHColumn(id: 'type', title: 'النوع', weight: 2),
    SHColumn(id: 'set', title: 'السيتات', weight: 2, isNumeric: true),
    SHColumn(id: 'count', title: 'العدد', weight: 2, isNumeric: true),
    SHColumn(id: 'color', title: 'اللون', weight: 2),
    SHColumn(
      id: 'price',
      title: 'السعر',
      weight: 3,
      isNumeric: true,
      priceFormat: true,
    ),
  ];

  List<Map<String, String>> _toRows(List<ExhibitionMultiSell> items) {
    return items
        .map(
          (m) => {
            'model': m.modelName,
            'type': m.type.label,
            'set': m.type == SellType.set ? m.setNumber.toString() : '',
            'count': _fmtCount(m.count),
            'color': m.color ?? '',
            'price': m.totalPrice.toString(),
          },
        )
        .toList();
  }

  String _fmtCount(double c) =>
      c == c.roundToDouble() ? c.toInt().toString() : c.toString();

  String? get _colorOrNull {
    final c = colorController.text.trim();
    return c.isEmpty ? null : c;
  }

  ExhibitionMultiSell? _buildFromForm() {
    if (selectedModel == null) {
      SnackBarUtil.showError(context, 'اختر الموديل أولاً');
      return null;
    }
    if (selectedType == SellType.set) {
      if (setNumber == null || chairCount == null) {
        SnackBarUtil.showError(context, 'اختر عدد السيتات ونوع المقاعد');
        return null;
      }
      return ExhibitionMultiSell.fromForm(
        id: 0,
        bill: widget.bill,
        model: selectedModel!,
        type: SellType.set,
        setNumber: setNumber!,
        count: chairCount!.toDouble(),
        color: _colorOrNull,
      );
    }
    final qty = double.tryParse(countController.text.trim());
    if (qty == null || qty <= 0) {
      SnackBarUtil.showError(context, 'أدخل عدداً صحيحاً');
      return null;
    }
    return ExhibitionMultiSell.fromForm(
      id: 0,
      bill: widget.bill,
      model: selectedModel!,
      type: selectedType,
      count: qty,
      color: _colorOrNull,
    );
  }

  void _save() {
    final item = _buildFromForm();
    if (item == null) return;
    final cubit = context.read<ExhibitionsCubit>();
    if (editingIndex != null) {
      cubit.replaceDraftMultiSell(editingIndex!, item);
    } else {
      cubit.addDraftMultiSell(item);
    }
    _clearForm();
  }

  void _clearForm() {
    colorController.clear();
    countController.clear();
    selectedModel = null;
    selectedType = SellType.set;
    setNumber = null;
    chairCount = null;
    editingIndex = null;
    _staleModelOption = null;
    _formVersion++;
    if (mounted) setState(() {});
  }

  Future<void> _editSelected() async {
    final selected = tableController.selectedIndexes;
    if (selected.isEmpty) {
      SnackBarUtil.showError(context, 'اختر عنصراً للتعديل');
      return;
    }
    if (selected.length > 1) {
      SnackBarUtil.showError(context, 'حدد عنصراً واحداً فقط');
      return;
    }
    final items = context.read<ExhibitionsCubit>().state.draftMultiSells;
    final idx = selected.first;
    if (idx >= items.length) return;
    final m = items[idx];

    final activeModels = context.read<ExhibitionsModelsCubit>().state.models;
    ExhibitionsModel? match;
    for (final mm in activeModels) {
      if (mm.id == m.modelId) {
        match = mm;
        break;
      }
    }
    // Not in the active catalog — the model was likely revised (new
    // id/uuid) or hidden since this item was added. Fetch the exact
    // historical revision directly so the price stays correct.
    ExhibitionsModel? stale;
    if (match == null) {
      stale = await _modelsRepo.getById(m.modelId);
    }
    if (!mounted) return;

    setState(() {
      editingIndex = idx;
      selectedType = m.type;
      colorController.text = m.color ?? '';
      if (m.type == SellType.set) {
        setNumber = m.setNumber;
        chairCount = m.count.round();
      } else {
        setNumber = null;
        chairCount = null;
        countController.text = _fmtCount(m.count);
      }
      selectedModel = match ?? stale;
      _staleModelOption = stale;
      _formVersion++;
    });

    if (match == null && stale == null) {
      // Model was deleted entirely (no row left, not just hidden) — can't
      // recover the original price; let the user know instead of silently
      // picking an unrelated model.
      if (mounted) {
        SnackBarUtil.showError(
          context,
          'موديل هذا العنصر غير موجود، اختر موديلاً جديداً',
        );
      }
    }
  }

  void _deleteSelected() {
    final selected = tableController.selectedIndexes;
    if (selected.isEmpty) {
      SnackBarUtil.showError(context, 'اختر عنصراً للحذف');
      return;
    }
    final cubit = context.read<ExhibitionsCubit>();
    final sorted = [...selected]..sort((a, b) => b.compareTo(a));
    for (final idx in sorted) {
      cubit.removeDraftMultiSellAt(idx);
    }
    tableController.clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        insetPadding: const EdgeInsets.all(40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 1000,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'عناصر المعرض',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Amiri',
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInputRow(),
              const SizedBox(height: 16),
              BlocBuilder<ExhibitionsCubit, ExhibitionsState>(
                builder: (context, state) {
                  return SizedBox(
                    height: 280,
                    child: SHTable(
                      controller: tableController,
                      direction: TextDirection.rtl,
                      hasIndex: true,
                      indexLabel: 'ت',
                      pagination: true,
                      columns: _columns,
                      rows: _toRows(state.draftMultiSells),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              BlocBuilder<ExhibitionsCubit, ExhibitionsState>(
                builder: (context, state) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'الإجمالي: ${PriceUtils.addCommas(state.draftMultiTotal)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Row(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _editSelected,
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('تعديل'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _deleteSelected,
                            icon: const Icon(
                              Icons.delete,
                              size: 18,
                              color: Colors.red,
                            ),
                            label: const Text('حذف'),
                          ),
                          AppPrimaryButton(
                            text: 'تم',
                            onPressed: () => Navigator.pop(context),
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
      ),
    );
  }

  Widget _buildInputRow() {
    return BlocBuilder<ExhibitionsModelsCubit, ExhibitionsModelsState>(
      builder: (context, modelsState) {
        return Column(
          spacing: 12,
          children: [
            Row(
              spacing: 12,
              children: [
                Expanded(
                  flex: 3,
                  child: _Labeled(
                    label: 'الموديل',
                    child: DropdownButtonFormField<ExhibitionsModel>(
                      key: ValueKey('model_$_formVersion'),
                      isExpanded: true,
                      initialValue: selectedModel,
                      decoration: _dropdownDecoration(),
                      hint: const Text('اسم الموديل'),
                      items: [
                        ...modelsState.models,
                        if (_staleModelOption != null &&
                            !modelsState.models.any(
                              (mm) => mm.id == _staleModelOption!.id,
                            ))
                          _staleModelOption!,
                      ].map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(
                            _staleModelOption?.id == m.id &&
                                    !modelsState.models.any(
                                      (mm) => mm.id == m.id,
                                    )
                                ? '${m.name} (قديم)'
                                : m.name,
                          ),
                        ),
                      ).toList(),
                      onChanged: (m) => setState(() => selectedModel = m),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _Labeled(
                    label: 'النوع',
                    child: DropdownButtonFormField<SellType>(
                      key: ValueKey('type_$_formVersion'),
                      isExpanded: true,
                      initialValue: selectedType,
                      decoration: _dropdownDecoration(),
                      items: SellType.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.label),
                            ),
                          )
                          .toList(),
                      onChanged: (t) => setState(() {
                        selectedType = t ?? SellType.set;
                        setNumber = null;
                        chairCount = null;
                        countController.clear();
                      }),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: AppInput(title: 'اللون', controller: colorController),
                ),
              ],
            ),
            Row(
              spacing: 12,
              children: [
                if (selectedType == SellType.set) ...[
                  Expanded(
                    child: _Labeled(
                      label: 'عدد السيتات',
                      child: DropdownButtonFormField<int>(
                        key: ValueKey('setn_$_formVersion'),
                        isExpanded: true,
                        initialValue: setNumber,
                        decoration: _dropdownDecoration(),
                        hint: const Text('السيتات'),
                        items: List.generate(9, (i) => i + 1)
                            .map(
                              (n) =>
                                  DropdownMenuItem(value: n, child: Text('$n')),
                            )
                            .toList(),
                        onChanged: (n) => setState(() => setNumber = n),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _Labeled(
                      label: 'المقاعد',
                      child: DropdownButtonFormField<int>(
                        key: ValueKey('chair_$_formVersion'),
                        isExpanded: true,
                        initialValue: chairCount,
                        decoration: _dropdownDecoration(),
                        hint: const Text('المقاعد'),
                        items: const [7, 8, 10]
                            .map(
                              (n) =>
                                  DropdownMenuItem(value: n, child: Text('$n')),
                            )
                            .toList(),
                        onChanged: (n) => setState(() => chairCount = n),
                      ),
                    ),
                  ),
                ] else
                  Expanded(
                    child: AppInput(
                      title: 'العدد',
                      controller: countController,
                      inputType: TextInputType.number,
                      direction: TextDirection.ltr,
                    ),
                  ),
                AppPrimaryButton(
                  text: editingIndex != null ? 'تعديل' : 'إضافة',
                  onPressed: _save,
                ),
                if (editingIndex != null)
                  OutlinedButton(
                    onPressed: _clearForm,
                    child: const Text('إلغاء'),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  InputDecoration _dropdownDecoration() => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF003763)),
    ),
  );
}

class _Labeled extends StatelessWidget {
  final String label;
  final Widget child;
  const _Labeled({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
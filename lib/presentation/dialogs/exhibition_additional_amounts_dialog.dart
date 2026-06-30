import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shtable/shtable.dart';
import 'package:taif_alamin/data/models/exhibition_additional_amount_model.dart';
import 'package:taif_alamin/presentation/cubits/exhibitions_cubit/exhibitions_cubit.dart';
import 'package:taif_alamin/presentation/cubits/exhibitions_cubit/exhibitions_state.dart';
import 'package:taif_alamin/utils/price_utils.dart';
import 'package:taif_alamin/utils/snack_bar_util.dart';
import 'package:taif_alamin/widgets/app_primary_button.dart';
import 'package:taif_alamin/widgets/general/app_input.dart';

/// Manage the extra charges of an exhibition. Reads/writes the draft list
/// held in [ExhibitionsCubit].
class ExhibitionAdditionalAmountsDialog extends StatefulWidget {
  final String bill;
  const ExhibitionAdditionalAmountsDialog({required this.bill, super.key});

  @override
  State<ExhibitionAdditionalAmountsDialog> createState() =>
      _ExhibitionAdditionalAmountsDialogState();
}

class _ExhibitionAdditionalAmountsDialogState
    extends State<ExhibitionAdditionalAmountsDialog> {
  final nameController = TextEditingController();
  final countController = TextEditingController();
  final priceController = TextEditingController();
  final SHTableController tableController = SHTableController();

  int? editingIndex;

  @override
  void dispose() {
    nameController.dispose();
    countController.dispose();
    priceController.dispose();
    tableController.dispose();
    super.dispose();
  }

  final List<SHColumn> _columns = [
    SHColumn(id: 'name', title: 'الاسم', weight: 4),
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
  ];

  String _fmtCount(double c) =>
      c == c.roundToDouble() ? c.toInt().toString() : c.toString();

  List<Map<String, String>> _toRows(List<ExhibitionAdditionalAmount> items) {
    return items
        .map(
          (a) => {
            'name': a.name ?? '',
            'count': _fmtCount(a.count),
            'price': a.price.toString(),
            'total': a.totalPrice.toString(),
          },
        )
        .toList();
  }

  ExhibitionAdditionalAmount? _buildFromForm() {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      SnackBarUtil.showError(context, 'أدخل اسم العنصر');
      return null;
    }
    final count = double.tryParse(countController.text.trim());
    if (count == null || count <= 0) {
      SnackBarUtil.showError(context, 'أدخل عدداً صحيحاً');
      return null;
    }
    final price = int.tryParse(priceController.text.replaceAll(',', '').trim());
    if (price == null || price <= 0) {
      SnackBarUtil.showError(context, 'أدخل سعراً صحيحاً');
      return null;
    }
    return ExhibitionAdditionalAmount(
      id: 0,
      bill: widget.bill,
      name: name,
      count: count,
      price: price,
    );
  }

  void _save() {
    final item = _buildFromForm();
    if (item == null) return;
    final cubit = context.read<ExhibitionsCubit>();
    if (editingIndex != null) {
      cubit.replaceDraftAdditional(editingIndex!, item);
    } else {
      cubit.addDraftAdditional(item);
    }
    _clearForm();
  }

  void _clearForm() {
    nameController.clear();
    countController.clear();
    priceController.clear();
    editingIndex = null;
    if (mounted) setState(() {});
  }

  void _editSelected() {
    final selected = tableController.selectedIndexes;
    if (selected.isEmpty) {
      SnackBarUtil.showError(context, 'اختر عنصراً للتعديل');
      return;
    }
    if (selected.length > 1) {
      SnackBarUtil.showError(context, 'حدد عنصراً واحداً فقط');
      return;
    }
    final items = context.read<ExhibitionsCubit>().state.draftAdditional;
    final idx = selected.first;
    if (idx >= items.length) return;
    final a = items[idx];
    setState(() {
      editingIndex = idx;
      nameController.text = a.name ?? '';
      countController.text = _fmtCount(a.count);
      priceController.text = a.price.toString();
    });
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
      cubit.removeDraftAdditionalAt(idx);
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
          width: 900,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'مبالغ إضافية',
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
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    flex: 3,
                    child: AppInput(title: 'الاسم', controller: nameController),
                  ),
                  Expanded(
                    flex: 2,
                    child: AppInput(
                      title: 'العدد',
                      controller: countController,
                      inputType: TextInputType.number,
                      direction: TextDirection.ltr,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: AppInput(
                      title: 'السعر',
                      controller: priceController,
                      isPrice: true,
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
              const SizedBox(height: 16),
              BlocBuilder<ExhibitionsCubit, ExhibitionsState>(
                builder: (context, state) {
                  return SizedBox(
                    height: 260,
                    child: SHTable(
                      controller: tableController,
                      direction: TextDirection.rtl,
                      hasIndex: true,
                      indexLabel: 'ت',
                      pagination: true,
                      columns: _columns,
                      rows: _toRows(state.draftAdditional),
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
                          'الإجمالي: ${PriceUtils.addCommas(state.draftAdditionalTotal)}',
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
}

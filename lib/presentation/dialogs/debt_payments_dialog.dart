import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shtable/shtable.dart';
import 'package:taif_alamin/data/models/customer_debt_model.dart';
import 'package:taif_alamin/data/models/customer_payment_model.dart';
import 'package:taif_alamin/presentation/cubits/debts_cubit/debts_cubit.dart';
import 'package:taif_alamin/utils/price_utils.dart';
import 'package:taif_alamin/utils/snack_bar_util.dart';
import 'package:taif_alamin/widgets/app_primary_button.dart';
import 'package:taif_alamin/widgets/general/app_input.dart';

/// Manage the payments of one [CustomerDebt].
class DebtPaymentsDialog extends StatefulWidget {
  final CustomerDebt debt;
  const DebtPaymentsDialog({required this.debt, super.key});

  @override
  State<DebtPaymentsDialog> createState() => _DebtPaymentsDialogState();
}

class _DebtPaymentsDialogState extends State<DebtPaymentsDialog> {
  final amountController = TextEditingController();
  final dateController = TextEditingController();
  final notesController = TextEditingController();
  final SHTableController tableController = SHTableController();

  DateTime selectedDate = DateTime.now();
  int? editingId;

  @override
  void initState() {
    super.initState();
    dateController.text = _fmt(selectedDate);
    context.read<DebtsCubit>().openDebt(widget.debt.id);
  }

  @override
  void dispose() {
    amountController.dispose();
    dateController.dispose();
    notesController.dispose();
    tableController.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  final List<SHColumn> _columns = [
    SHColumn(id: 'id', title: 'id', weight: 1, hidden: true),
    SHColumn(
      id: 'amount',
      title: 'المبلغ',
      weight: 3,
      isNumeric: true,
      priceFormat: true,
    ),
    SHColumn(id: 'date', title: 'التاريخ', weight: 3),
    SHColumn(id: 'notes', title: 'ملاحظات', weight: 4),
  ];

  List<Map<String, String>> _rows(List<CustomerPayment> ps) => ps
      .map(
        (p) => {
          'id': p.id.toString(),
          'amount': p.paymentAmount.toString(),
          'date': _fmt(p.paymentDate),
          'notes': p.notes ?? '',
        },
      )
      .toList();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateController.text = _fmt(picked);
      });
    }
  }

  void _save() {
    final amount =
        int.tryParse(amountController.text.replaceAll(',', '').trim()) ?? 0;
    if (amount <= 0) {
      SnackBarUtil.showError(context, 'أدخل مبلغ الدفعة');
      return;
    }
    final cubit = context.read<DebtsCubit>();
    final payment = CustomerPayment(
      id: editingId ?? 0,
      debtId: widget.debt.id,
      paymentAmount: amount,
      paymentDate: selectedDate,
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
    );
    if (editingId != null) {
      cubit.updatePayment(payment);
    } else {
      cubit.addPayment(payment);
    }
    _clear();
  }

  void _clear() {
    amountController.clear();
    notesController.clear();
    selectedDate = DateTime.now();
    dateController.text = _fmt(selectedDate);
    editingId = null;
    if (mounted) setState(() {});
  }

  void _editSelected(DebtsState state) {
    final sel = tableController.selectedIndexes;
    if (sel.isEmpty || sel.length > 1) {
      SnackBarUtil.showError(context, 'اختر دفعة واحدة للتعديل');
      return;
    }
    final idx = sel.first;
    if (idx >= state.openPayments.length) return;
    final p = state.openPayments[idx];
    setState(() {
      editingId = p.id;
      amountController.text = p.paymentAmount.toString();
      selectedDate = p.paymentDate;
      dateController.text = _fmt(p.paymentDate);
      notesController.text = p.notes ?? '';
    });
  }

  void _deleteSelected(DebtsState state) {
    final sel = tableController.selectedIndexes;
    if (sel.isEmpty) {
      SnackBarUtil.showError(context, 'اختر دفعة للحذف');
      return;
    }
    final cubit = context.read<DebtsCubit>();
    for (final idx in sel) {
      if (idx < state.openPayments.length) {
        cubit.deletePayment(state.openPayments[idx].id, widget.debt.id);
      }
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
          width: 820,
          padding: const EdgeInsets.all(20),
          child: BlocBuilder<DebtsCubit, DebtsState>(
            builder: (context, state) {
              final total = state.totalOf(widget.debt);
              final finalPrice = state.finalOf(widget.debt);
              final remaining = finalPrice - state.openPaid; // may be negative
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'دفعات: ${widget.debt.debtorName} (وصل ${widget.debt.bill ?? ''})',
                        style: const TextStyle(
                          fontSize: 18,
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
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat('الكلي', total),
                      _stat('الخصم', widget.debt.discount),
                      _stat('النهائي', finalPrice),
                      _stat('المدفوع', state.openPaid),
                      _stat('المتبقي', remaining, highlight: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        flex: 2,
                        child: AppInput(
                          title: 'مبلغ الدفعة',
                          controller: amountController,
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
                          onTap: _pickDate,
                          direction: TextDirection.ltr,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: AppInput(
                          title: 'ملاحظات',
                          controller: notesController,
                        ),
                      ),
                      AppPrimaryButton(
                        text: editingId != null ? 'تعديل' : 'إضافة',
                        onPressed: _save,
                      ),
                      if (editingId != null)
                        OutlinedButton(
                          onPressed: _clear,
                          child: const Text('إلغاء'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 240,
                    child: SHTable(
                      controller: tableController,
                      direction: TextDirection.rtl,
                      hasIndex: true,
                      indexLabel: 'ت',
                      pagination: true,
                      columns: _columns,
                      rows: _rows(state.openPayments),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _editSelected(state),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('تعديل'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _deleteSelected(state),
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
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
        ),
      ),
    );
  }

  Widget _stat(String label, int value, {bool highlight = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          PriceUtils.addCommas(value),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: highlight ? Colors.red : const Color(0xFF003763),
          ),
        ),
      ],
    );
  }
}

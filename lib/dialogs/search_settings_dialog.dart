import 'package:flutter/material.dart';
import 'package:shtable/shtable.dart';
import 'package:taif_alamin/theme/app_colors.dart';
import 'package:taif_alamin/widgets/app_primary_button.dart';

class SearchSettingsDialog extends StatefulWidget {
  final BuildContext context;
  final List<SHColumn> columns;
  final String? searchIn;
  final VoidCallback? onDismiss;
  final Function(String)? onSave;
  const SearchSettingsDialog({
    super.key,
    required this.context,
    required this.columns,
    this.searchIn,
    this.onSave,
    this.onDismiss,
  });

  @override
  State<SearchSettingsDialog> createState() => _SearchSettingsDialogState();
}

class _SearchSettingsDialogState extends State<SearchSettingsDialog> {
  late List<SHColumn> searchableColumns;
  late String? _selectedColumn;

  @override
  void initState() {
    searchableColumns = widget.columns.where((item) => !item.hidden).toList();
    _selectedColumn = widget.searchIn ?? searchableColumns.first.id;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      width: 400,
      decoration: BoxDecoration(
        color: AppColors.neutral,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.maxFinite,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.primary,
              ),
              child: Text(
                "البحث في ...",
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            RadioGroup<String>(
              groupValue: _selectedColumn,
              onChanged: (value) => setState(() => _selectedColumn = value),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: searchableColumns.length,
                itemBuilder: (BuildContext context, int index) {
                  final column = searchableColumns[index];
                  return Row(
                    children: [
                      Radio<String>(value: column.id),
                      Text(
                        column.title,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: AppPrimaryButton(text: "حفظ", onPressed: onSave),
                  ),
                  Expanded(
                    child: AppPrimaryButton(
                      text: "إلغاء",
                      onPressed: widget.onDismiss!,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onSave() {
    if (widget.onSave != null) {
      widget.onSave!(_selectedColumn!);
    }
  }
}

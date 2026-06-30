import 'package:flutter/material.dart';
import 'package:taif_alamin/widgets/general/app_action_button.dart';

class AppActionButtons extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onExport;

  /// Optional — only screens that pass this get a "طباعة" button. Other
  /// screens using this shared widget are unaffected.
  final VoidCallback? onPrint;

  const AppActionButtons({
    super.key,
    required this.onBack,
    required this.onDelete,
    required this.onEdit,
    required this.onDuplicate,
    required this.onExport,
    this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Color(0xFFFDFDFE),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(64, 0, 0, 0),
                offset: Offset(1, 2),
              ),
            ],
          ),
          width: 768,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 16,
                children: [
                  AppActionButton(
                    title: "رجوع",
                    icon: Icons.arrow_back,
                    iconColor: Colors.black,
                    callback: onBack,
                  ),
                  Container(
                    height: 32,
                    width: 1,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(128, 0, 0, 0),
                    ),
                  ),
                  AppActionButton(
                    title: "حذف",
                    icon: Icons.delete,
                    iconColor: Colors.red,
                    callback: onDelete,
                  ),
                  AppActionButton(
                    title: "تعديل",
                    icon: Icons.edit,
                    iconColor: Colors.blueGrey,
                    callback: onEdit,
                  ),
                  AppActionButton(
                    title: "تكرار",
                    icon: Icons.control_point_duplicate,
                    iconColor: Colors.blueGrey,
                    callback: onDuplicate,
                  ),
                  if (onPrint != null)
                    AppActionButton(
                      title: "طباعة",
                      icon: Icons.print,
                      iconColor: Colors.blueGrey,
                      callback: onPrint!,
                    ),
                ],
              ),
              InkWell(
                onTap: onExport,
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Color(0xFF003763),
                  ),
                  child: AppActionButton(
                    icon: Icons.upload,
                    iconColor: Colors.white,
                    textColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActionButtonItem {
  final String title;
  final Function() onTap;
  final ActionButtonTheme theme;

  ActionButtonItem({
    required this.title,
    required this.onTap,
    required this.theme,
  });
}

class ActionButtonTheme {
  final Color bgColor, iconColor, textColor;

  ActionButtonTheme({
    required this.bgColor,
    required this.iconColor,
    required this.textColor,
  });
}

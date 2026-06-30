import 'package:flutter/material.dart';

class AppActionButton extends StatelessWidget {
  final String? title;
  final Color? iconColor, textColor;
  final IconData? icon;
  final VoidCallback? callback;
  const AppActionButton({
    super.key,
    this.title,
    required this.iconColor,
    required this.icon,
    this.callback,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: callback,
      child: Container(
        //width: 128,
        padding: title != null
            ? EdgeInsets.symmetric(vertical: 16, horizontal: 8)
            : EdgeInsets.zero,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 4,
          children: [
            Icon(icon, color: iconColor ?? Colors.black, size: 16),
            if (title != null)
              Text(
                title!,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  color: textColor ?? Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class HomeButton extends StatefulWidget {
  final String title;
  final VoidCallback callback;
  final String? icon;
  final Color? color;
  final List<Color>? gradient;
  const HomeButton({
    super.key,
    required this.title,
    required this.callback,
    this.color,
    this.gradient,
    this.icon,
  });

  @override
  State<HomeButton> createState() => _HomeButtonState();
}

class _HomeButtonState extends State<HomeButton> {
  Color backgroundColor = Colors.white;
  Color iconBackgroundColor = Color(0xFFF2F4F5);
  Color iconColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.callback,
      onHover: (value) {
        if (value) {
          backgroundColor = Color(0xFFD2E4FF);
          iconBackgroundColor = Color(0xFFFFDDBA);
          iconColor = Color(0xFF2B1700);
        } else {
          backgroundColor = Colors.white;
          iconBackgroundColor = Color(0xFFF2F4F5);
          iconColor = Colors.black;
        }
        if (mounted) setState(() {});
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 8,
          children: [
            Container(
              width: 64,
              height: 64,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SvgPicture.asset(
                widget.icon ?? 'icons/home/fabric.svg',
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
            Text(
              widget.title,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                color: Color(0xFF66758C),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:taif_alamin/presentation/cubits/button_cubit/button_cubit.dart';
import 'package:taif_alamin/presentation/cubits/button_cubit/button_state.dart';
import 'package:taif_alamin/widgets/app_button/app_button_theme.dart';

class AppButton extends StatelessWidget {
  final String title;
  final String? iconPath;
  final BytesLoader? svgIcon;
  final IconData?
  materialIcon; // built-in Material icon (used by the home menu)
  final AppButtonTheme theme;
  final Function()? onTap;

  const AppButton({
    super.key,
    required this.title,
    required this.theme,
    this.iconPath,
    this.svgIcon,
    this.materialIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ButtonCubit(ButtonState(color: theme.defaultColor)),
      child: BlocBuilder<ButtonCubit, ButtonState>(
        builder: (context, state) {
          late AppButtonColor colors;
          if (state is ButtonHover) {
            colors = state.color;
          } else {
            colors = state.color;
          }
          return InkWell(
            onTap: onTap,
            onHover: (value) {
              if (value) {
                context.read<ButtonCubit>().changeState(theme.hoverColor);
              } else {
                context.read<ButtonCubit>().changeState(theme.defaultColor);
              }
            },
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: colors.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x28000000)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.iconBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: icon(colors),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        color: colors.textColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget icon(AppButtonColor color) {
    if (materialIcon != null) {
      return FittedBox(child: Icon(materialIcon, color: color.iconColor));
    } else if (iconPath != null && iconPath!.isNotEmpty) {
      return Image.asset(iconPath!, color: color.iconColor);
    } else if (svgIcon != null) {
      return SvgPicture(svgIcon!);
    } else {
      return const SizedBox.shrink();
    }
  }
}

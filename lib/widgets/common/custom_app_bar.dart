import 'package:flutter/material.dart';
import '../../config/constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget? leading;
  final double height;
  final Color? backgroundColor;
  final Color? titleColor;
  final TextStyle? titleStyle;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.leading,
    this.height = 56.0,
    this.backgroundColor,
    this.titleColor,
    this.titleStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: titleStyle ??
            TextStyle(
              color: titleColor ?? Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
      ),
      backgroundColor: backgroundColor ?? AppColors.primary,
      elevation: 0,
      centerTitle: true,
      leading: showBackButton
          ? leading ??
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              )
          : leading,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
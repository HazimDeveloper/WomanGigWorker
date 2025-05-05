import 'package:flutter/material.dart';
import '../../config/constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isPrimary;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? (isPrimary ? AppColors.secondary : Colors.white),
          foregroundColor: textColor ?? (isPrimary ? Colors.white : AppColors.primary),
          padding: padding ?? const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: isPrimary
                ? BorderSide.none
                : const BorderSide(color: AppColors.primary),
          ),
          elevation: isPrimary ? 2 : 0,
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? (isPrimary ? Colors.white : AppColors.primary),
                  ),
                  strokeWidth: 2.0,
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? (isPrimary ? Colors.white : AppColors.primary),
                ),
              ),
      ),
    );
  }
}
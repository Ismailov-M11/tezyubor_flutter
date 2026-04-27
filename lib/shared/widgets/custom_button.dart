import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum ButtonVariant { primary, outline, ghost, destructive }

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final Widget? icon;
  final double? width;
  final double height;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.width,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _loaderColor(context),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
              Text(label),
            ],
          );

    Widget button;
    switch (variant) {
      case ButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case ButtonVariant.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case ButtonVariant.ghost:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case ButtonVariant.destructive:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            minimumSize: Size(width ?? double.infinity, height),
          ),
          child: child,
        );
    }

    if (width != null) {
      return SizedBox(width: width, height: height, child: button);
    }
    return SizedBox(height: height, child: button);
  }

  Color _loaderColor(BuildContext context) {
    switch (variant) {
      case ButtonVariant.primary:
      case ButtonVariant.destructive:
        return Colors.white;
      case ButtonVariant.outline:
      case ButtonVariant.ghost:
        return AppColors.primary;
    }
  }
}

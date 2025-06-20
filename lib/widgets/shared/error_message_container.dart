import 'package:flutter/material.dart';

class ErrorMessageContainer extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? iconColor;
  final VoidCallback? onDismiss;
  final bool showIcon;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const ErrorMessageContainer({
    Key? key,
    required this.message,
    this.icon,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.iconColor,
    this.onDismiss,
    this.showIcon = true,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? Colors.red.shade50;
    final effectiveBorderColor = borderColor ?? Colors.red.shade200;
    final effectiveTextColor = textColor ?? Colors.red.shade800;
    final effectiveIconColor = iconColor ?? Colors.red.shade700;
    final effectiveIcon = icon ?? Icons.error_outline;
    final effectivePadding = padding ?? const EdgeInsets.all(12);
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(8);

    return Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: effectiveBorderRadius,
        border: Border.all(color: effectiveBorderColor),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(
              effectiveIcon,
              color: effectiveIconColor,
              size: 18,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: effectiveTextColor,
                fontSize: 14,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(4),
              child: Icon(
                Icons.close,
                color: effectiveIconColor,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class WarningMessageContainer extends StatelessWidget {
  final String message;
  final IconData? icon;
  final VoidCallback? onDismiss;
  final bool showIcon;
  final EdgeInsetsGeometry? padding;

  const WarningMessageContainer({
    Key? key,
    required this.message,
    this.icon,
    this.onDismiss,
    this.showIcon = true,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorMessageContainer(
      message: message,
      icon: icon ?? Icons.warning_amber_outlined,
      backgroundColor: Colors.orange.shade50,
      borderColor: Colors.orange.shade200,
      textColor: Colors.orange.shade800,
      iconColor: Colors.orange.shade700,
      onDismiss: onDismiss,
      showIcon: showIcon,
      padding: padding,
    );
  }
}

class InfoMessageContainer extends StatelessWidget {
  final String message;
  final IconData? icon;
  final VoidCallback? onDismiss;
  final bool showIcon;
  final EdgeInsetsGeometry? padding;

  const InfoMessageContainer({
    Key? key,
    required this.message,
    this.icon,
    this.onDismiss,
    this.showIcon = true,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorMessageContainer(
      message: message,
      icon: icon ?? Icons.info_outline,
      backgroundColor: Colors.blue.shade50,
      borderColor: Colors.blue.shade100,
      textColor: Colors.blue.shade800,
      iconColor: Colors.blue.shade700,
      onDismiss: onDismiss,
      showIcon: showIcon,
      padding: padding,
    );
  }
}

class SuccessMessageContainer extends StatelessWidget {
  final String message;
  final IconData? icon;
  final VoidCallback? onDismiss;
  final bool showIcon;
  final EdgeInsetsGeometry? padding;

  const SuccessMessageContainer({
    Key? key,
    required this.message,
    this.icon,
    this.onDismiss,
    this.showIcon = true,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorMessageContainer(
      message: message,
      icon: icon ?? Icons.check_circle_outline,
      backgroundColor: Colors.green.shade50,
      borderColor: Colors.green.shade200,
      textColor: Colors.green.shade800,
      iconColor: Colors.green.shade700,
      onDismiss: onDismiss,
      showIcon: showIcon,
      padding: padding,
    );
  }
}
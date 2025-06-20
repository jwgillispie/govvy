import 'package:flutter/material.dart';

class LoadingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;
  final String? loadingLabel;
  final IconData? icon;
  final IconData? loadingIcon;
  final ButtonStyle? style;
  final Widget? loadingIndicator;
  final Color? loadingIndicatorColor;
  final double? loadingIndicatorSize;
  final bool showLoadingIcon;
  final MainAxisSize mainAxisSize;

  const LoadingButton({
    Key? key,
    required this.onPressed,
    required this.isLoading,
    required this.label,
    this.loadingLabel,
    this.icon,
    this.loadingIcon,
    this.style,
    this.loadingIndicator,
    this.loadingIndicatorColor,
    this.loadingIndicatorSize = 20,
    this.showLoadingIcon = true,
    this.mainAxisSize = MainAxisSize.min,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveLoadingLabel = loadingLabel ?? 'Loading...';
    final effectiveLoadingIndicatorColor = loadingIndicatorColor ?? Colors.white;
    
    Widget buildLoadingIndicator() {
      if (loadingIndicator != null) {
        return loadingIndicator!;
      }
      
      return Container(
        width: loadingIndicatorSize,
        height: loadingIndicatorSize,
        padding: const EdgeInsets.all(2.0),
        child: CircularProgressIndicator(
          color: effectiveLoadingIndicatorColor,
          strokeWidth: 2,
        ),
      );
    }

    Widget buildIcon() {
      if (isLoading && showLoadingIcon) {
        return buildLoadingIndicator();
      } else if (icon != null) {
        return Icon(icon);
      } else {
        return const SizedBox.shrink();
      }
    }

    String getButtonText() {
      return isLoading ? effectiveLoadingLabel : label;
    }

    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: buildIcon(),
      label: Text(getButtonText()),
      style: style,
    );
  }
}

class LoadingTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;
  final String? loadingLabel;
  final IconData? icon;
  final ButtonStyle? style;
  final Widget? loadingIndicator;
  final Color? loadingIndicatorColor;
  final double? loadingIndicatorSize;
  final bool showLoadingIcon;

  const LoadingTextButton({
    Key? key,
    required this.onPressed,
    required this.isLoading,
    required this.label,
    this.loadingLabel,
    this.icon,
    this.style,
    this.loadingIndicator,
    this.loadingIndicatorColor,
    this.loadingIndicatorSize = 16,
    this.showLoadingIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveLoadingLabel = loadingLabel ?? 'Loading...';
    final effectiveLoadingIndicatorColor = loadingIndicatorColor ?? theme.colorScheme.primary;
    
    Widget buildLoadingIndicator() {
      if (loadingIndicator != null) {
        return loadingIndicator!;
      }
      
      return Container(
        width: loadingIndicatorSize,
        height: loadingIndicatorSize,
        padding: const EdgeInsets.all(1.0),
        child: CircularProgressIndicator(
          color: effectiveLoadingIndicatorColor,
          strokeWidth: 2,
        ),
      );
    }

    Widget buildIcon() {
      if (isLoading && showLoadingIcon) {
        return buildLoadingIndicator();
      } else if (icon != null) {
        return Icon(icon);
      } else {
        return const SizedBox.shrink();
      }
    }

    String getButtonText() {
      return isLoading ? effectiveLoadingLabel : label;
    }

    if (icon != null || (isLoading && showLoadingIcon)) {
      return TextButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: buildIcon(),
        label: Text(getButtonText()),
        style: style,
      );
    } else {
      return TextButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: Text(getButtonText()),
      );
    }
  }
}

class LoadingOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;
  final String? loadingLabel;
  final IconData? icon;
  final ButtonStyle? style;
  final Widget? loadingIndicator;
  final Color? loadingIndicatorColor;
  final double? loadingIndicatorSize;
  final bool showLoadingIcon;

  const LoadingOutlinedButton({
    Key? key,
    required this.onPressed,
    required this.isLoading,
    required this.label,
    this.loadingLabel,
    this.icon,
    this.style,
    this.loadingIndicator,
    this.loadingIndicatorColor,
    this.loadingIndicatorSize = 20,
    this.showLoadingIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveLoadingLabel = loadingLabel ?? 'Loading...';
    final effectiveLoadingIndicatorColor = loadingIndicatorColor ?? theme.colorScheme.primary;
    
    Widget buildLoadingIndicator() {
      if (loadingIndicator != null) {
        return loadingIndicator!;
      }
      
      return Container(
        width: loadingIndicatorSize,
        height: loadingIndicatorSize,
        padding: const EdgeInsets.all(2.0),
        child: CircularProgressIndicator(
          color: effectiveLoadingIndicatorColor,
          strokeWidth: 2,
        ),
      );
    }

    Widget buildIcon() {
      if (isLoading && showLoadingIcon) {
        return buildLoadingIndicator();
      } else if (icon != null) {
        return Icon(icon);
      } else {
        return const SizedBox.shrink();
      }
    }

    String getButtonText() {
      return isLoading ? effectiveLoadingLabel : label;
    }

    if (icon != null || (isLoading && showLoadingIcon)) {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: buildIcon(),
        label: Text(getButtonText()),
        style: style,
      );
    } else {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: Text(getButtonText()),
      );
    }
  }
}

class LoadingIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData icon;
  final String? tooltip;
  final String? loadingTooltip;
  final Widget? loadingIndicator;
  final Color? loadingIndicatorColor;
  final double? loadingIndicatorSize;
  final double? iconSize;
  final Color? color;
  final ButtonStyle? style;

  const LoadingIconButton({
    Key? key,
    required this.onPressed,
    required this.isLoading,
    required this.icon,
    this.tooltip,
    this.loadingTooltip,
    this.loadingIndicator,
    this.loadingIndicatorColor,
    this.loadingIndicatorSize,
    this.iconSize,
    this.color,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveLoadingIndicatorSize = loadingIndicatorSize ?? iconSize ?? 24;
    final effectiveLoadingIndicatorColor = loadingIndicatorColor ?? color ?? theme.colorScheme.primary;
    final effectiveTooltip = isLoading ? (loadingTooltip ?? 'Loading...') : tooltip;
    
    Widget buildContent() {
      if (isLoading) {
        if (loadingIndicator != null) {
          return loadingIndicator!;
        }
        return SizedBox(
          width: effectiveLoadingIndicatorSize,
          height: effectiveLoadingIndicatorSize,
          child: CircularProgressIndicator(
            color: effectiveLoadingIndicatorColor,
            strokeWidth: 2,
          ),
        );
      } else {
        return Icon(
          icon,
          size: iconSize,
          color: color,
        );
      }
    }

    final button = IconButton(
      onPressed: isLoading ? null : onPressed,
      icon: buildContent(),
      style: style,
    );

    if (effectiveTooltip != null) {
      return Tooltip(
        message: effectiveTooltip,
        child: button,
      );
    }

    return button;
  }
}
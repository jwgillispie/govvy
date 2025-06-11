// lib/widgets/shared/government_level_badge.dart

import 'package:flutter/material.dart';
import 'package:govvy/utils/government_level_helper.dart';

enum BadgeSize {
  small,
  medium,
  large,
}

class GovernmentLevelBadge extends StatelessWidget {
  final GovernmentLevel level;
  final BadgeSize size;
  final bool showIcon;
  final bool showText;
  final bool compact;

  const GovernmentLevelBadge({
    Key? key,
    required this.level,
    this.size = BadgeSize.medium,
    this.showIcon = true,
    this.showText = true,
    this.compact = false,
  }) : super(key: key);

  /// Convenience constructor for representative chamber
  factory GovernmentLevelBadge.fromChamber({
    Key? key,
    required String? chamber,
    String? bioGuideId,
    String? source,
    BadgeSize size = BadgeSize.medium,
    bool showIcon = true,
    bool showText = true,
    bool compact = false,
  }) {
    return GovernmentLevelBadge(
      key: key,
      level: GovernmentLevelHelper.getLevelFromChamber(chamber, bioGuideId: bioGuideId, source: source),
      size: size,
      showIcon: showIcon,
      showText: showText,
      compact: compact,
    );
  }

  /// Convenience constructor for representative object (recommended)
  factory GovernmentLevelBadge.fromRepresentative({
    Key? key,
    required dynamic representative,
    BadgeSize size = BadgeSize.medium,
    bool showIcon = true,
    bool showText = true,
    bool compact = false,
  }) {
    return GovernmentLevelBadge(
      key: key,
      level: GovernmentLevelHelper.getLevelFromRepresentative(representative),
      size: size,
      showIcon: showIcon,
      showText: showText,
      compact: compact,
    );
  }

  /// Convenience constructor for bill type
  factory GovernmentLevelBadge.fromBillType({
    Key? key,
    required String? billType,
    BadgeSize size = BadgeSize.medium,
    bool showIcon = true,
    bool showText = true,
    bool compact = false,
  }) {
    return GovernmentLevelBadge(
      key: key,
      level: GovernmentLevelHelper.getLevelFromBillType(billType),
      size: size,
      showIcon: showIcon,
      showText: showText,
      compact: compact,
    );
  }

  double get _fontSize {
    switch (size) {
      case BadgeSize.small:
        return 10.0;
      case BadgeSize.medium:
        return 12.0;
      case BadgeSize.large:
        return 14.0;
    }
  }

  double get _iconSize {
    switch (size) {
      case BadgeSize.small:
        return 12.0;
      case BadgeSize.medium:
        return 14.0;
      case BadgeSize.large:
        return 16.0;
    }
  }

  EdgeInsets get _padding {
    if (compact) {
      switch (size) {
        case BadgeSize.small:
          return const EdgeInsets.symmetric(horizontal: 4, vertical: 2);
        case BadgeSize.medium:
          return const EdgeInsets.symmetric(horizontal: 6, vertical: 3);
        case BadgeSize.large:
          return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      }
    } else {
      switch (size) {
        case BadgeSize.small:
          return const EdgeInsets.symmetric(horizontal: 6, vertical: 3);
        case BadgeSize.medium:
          return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
        case BadgeSize.large:
          return const EdgeInsets.symmetric(horizontal: 10, vertical: 5);
      }
    }
  }

  double get _borderRadius {
    switch (size) {
      case BadgeSize.small:
        return 8.0;
      case BadgeSize.medium:
        return 10.0;
      case BadgeSize.large:
        return 12.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = GovernmentLevelHelper.getLevelColor(level);
    final icon = GovernmentLevelHelper.getLevelIcon(level);
    final text = compact 
        ? GovernmentLevelHelper.getLevelShortName(level)
        : GovernmentLevelHelper.getLevelDisplayName(level);

    // If neither icon nor text should be shown, return empty widget
    if (!showIcon && !showText) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              icon,
              size: _iconSize,
              color: color,
            ),
            if (showText) SizedBox(width: compact ? 2 : 4),
          ],
          if (showText)
            Text(
              text,
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}

/// A simple dot indicator for government level
class GovernmentLevelDot extends StatelessWidget {
  final GovernmentLevel level;
  final double size;

  const GovernmentLevelDot({
    Key? key,
    required this.level,
    this.size = 12.0,
  }) : super(key: key);

  /// Convenience constructor for representative chamber
  factory GovernmentLevelDot.fromChamber({
    Key? key,
    required String? chamber,
    String? bioGuideId,
    String? source,
    double size = 12.0,
  }) {
    return GovernmentLevelDot(
      key: key,
      level: GovernmentLevelHelper.getLevelFromChamber(chamber, bioGuideId: bioGuideId, source: source),
      size: size,
    );
  }

  /// Convenience constructor for representative object (recommended)
  factory GovernmentLevelDot.fromRepresentative({
    Key? key,
    required dynamic representative,
    double size = 12.0,
  }) {
    return GovernmentLevelDot(
      key: key,
      level: GovernmentLevelHelper.getLevelFromRepresentative(representative),
      size: size,
    );
  }

  /// Convenience constructor for bill type
  factory GovernmentLevelDot.fromBillType({
    Key? key,
    required String? billType,
    double size = 12.0,
  }) {
    return GovernmentLevelDot(
      key: key,
      level: GovernmentLevelHelper.getLevelFromBillType(billType),
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = GovernmentLevelHelper.getLevelColor(level);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Extension to add convenience methods to widgets
extension GovernmentLevelBadgeExtension on Widget {
  /// Wraps the widget with a government level context
  Widget withLevelContext(GovernmentLevel level, {Color? backgroundColor}) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? GovernmentLevelHelper.getLevelLightColor(level),
        border: Border(
          left: BorderSide(
            color: GovernmentLevelHelper.getLevelColor(level),
            width: 3,
          ),
        ),
      ),
      child: this,
    );
  }
}
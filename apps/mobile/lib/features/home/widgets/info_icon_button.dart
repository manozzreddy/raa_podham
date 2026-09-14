import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// The ⓘ tap target used everywhere a rider's Info modal can be opened
/// from — the map callout, the expanded sheet row — a properly sized,
/// platform-appropriate button instead of a bare `Icon` wrapped in a
/// `GestureDetector`, whose hit area would otherwise be exactly that
/// small icon's own visual size.
class InfoIconButton extends StatelessWidget {
  const InfoIconButton({
    super.key,
    required this.onTap,
    this.size = 36,
    this.iconSize = 20,
    this.color,
  });

  final VoidCallback onTap;

  /// The tappable button's own footprint — kept separate from [iconSize]
  /// so a caller with limited space (the map callout, inside its small
  /// pill) can shrink the overall footprint while keeping the icon
  /// itself legible.
  final double size;
  final double iconSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? AppColors.asphaltInk.withValues(alpha: 0.7);

    if (isCupertino) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size(size, size),
        onPressed: onTap,
        child: Icon(
          CupertinoIcons.info_circle,
          size: iconSize,
          color: resolvedColor,
        ),
      );
    }

    return IconButton(
      padding: EdgeInsets.zero,
      // Material's own default visual density otherwise pads this out
      // further than the explicit constraints below suggest.
      visualDensity: VisualDensity.compact,
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      iconSize: iconSize,
      onPressed: onTap,
      icon: Icon(Icons.info_outline, color: resolvedColor),
    );
  }
}

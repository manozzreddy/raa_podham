import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/theme.dart';
import 'rider_avatar_chip.dart';

/// The top, Google Maps-style search pill: a menu button, the ride name,
/// and the current rider's profile avatar.
class RideSearchBar extends StatelessWidget {
  const RideSearchBar({
    super.key,
    required this.rideName,
    this.onMenuTap,
    this.onProfileTap,
  });

  final String rideName;
  final VoidCallback? onMenuTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isCupertino
        ? CupertinoTheme.of(context).scaffoldBackgroundColor
        : Theme.of(context).colorScheme.surface;
    final nameStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.navTitleTextStyle
        : Theme.of(context).textTheme.titleMedium;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _CircleIconButton(
            icon: isCupertino ? CupertinoIcons.line_horizontal_3 : Icons.menu,
            onPressed: onMenuTap ?? HapticFeedback.selectionClick,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rideName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: nameStyle?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onProfileTap ?? HapticFeedback.selectionClick,
            child: const RiderAvatarCircle(
              label: 'You',
              diameter: 36,
              background: AppColors.sunriseAmber,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    if (isCupertino) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size.square(_size),
        onPressed: onPressed,
        child: Icon(icon, size: 20),
      );
    }

    return SizedBox(
      width: _size,
      height: _size,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}

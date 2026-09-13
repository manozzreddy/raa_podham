import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// The map's floating recenter-on-me button — matching Google Maps'
/// own single my-location FAB. Invite/end/leave used to also float here,
/// but now live in the rider sheet's own action row instead (Invite was
/// previously offered in both places at once).
class MapFabStack extends StatelessWidget {
  const MapFabStack({
    super.key,
    required this.isFollowingUser,
    required this.onRecenter,
  });

  final bool isFollowingUser;
  final VoidCallback onRecenter;

  @override
  Widget build(BuildContext context) {
    return _MapFabButton(
      icon: isCupertino ? CupertinoIcons.location_fill : Icons.my_location,
      isAccented: isFollowingUser,
      onPressed: onRecenter,
    );
  }
}

class _MapFabButton extends StatelessWidget {
  const _MapFabButton({
    required this.icon,
    required this.isAccented,
    required this.onPressed,
  });

  final IconData icon;
  final bool isAccented;
  final VoidCallback onPressed;

  static const double _size = 44;

  @override
  Widget build(BuildContext context) {
    final neutralBackground = isCupertino
        ? CupertinoTheme.of(context).scaffoldBackgroundColor
        : Theme.of(context).colorScheme.surface;
    final neutralIconColor = isCupertino
        ? CupertinoTheme.of(context).textTheme.textStyle.color
        : Theme.of(context).colorScheme.onSurface;

    final backgroundColor = isAccented
        ? AppColors.sunriseAmber
        : neutralBackground;
    final iconColor = isAccented ? Colors.white : neutralIconColor;

    if (isCupertino) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size.square(_size),
        onPressed: onPressed,
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: isAccented ? null : Border.all(color: AppColors.hairline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      );
    }

    return Material(
      color: backgroundColor,
      shape: CircleBorder(
        side: isAccented
            ? BorderSide.none
            : const BorderSide(color: AppColors.hairline),
      ),
      elevation: isAccented ? 2 : 1,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: _size,
          height: _size,
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}

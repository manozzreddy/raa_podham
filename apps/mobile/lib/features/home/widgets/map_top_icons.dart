import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/theme.dart';
import 'rider_avatar_chip.dart';

/// The two floating buttons pinned above the map: menu (left, opens the
/// app drawer) and profile (right, opens Settings) — no connecting bar
/// or title between them, matching how [MapFabStack]'s own buttons float
/// independently on the other side of the screen.
class MapTopIcons extends StatelessWidget {
  const MapTopIcons({
    super.key,
    this.onMenuTap,
    this.onProfileTap,
    this.selfPhotoUrl,
  });

  final VoidCallback? onMenuTap;
  final VoidCallback? onProfileTap;

  /// The signed-in user's Google/Apple account photo, when there is one.
  final String? selfPhotoUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _FloatingIconButton(
          icon: isCupertino ? CupertinoIcons.line_horizontal_3 : Icons.menu,
          onPressed: onMenuTap ?? HapticFeedback.selectionClick,
        ),
        _FloatingProfileButton(
          photoUrl: selfPhotoUrl,
          onPressed: onProfileTap ?? HapticFeedback.selectionClick,
        ),
      ],
    );
  }
}

class _FloatingIconButton extends StatelessWidget {
  const _FloatingIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  static const double _size = 44;

  @override
  Widget build(BuildContext context) {
    final background = isCupertino
        ? CupertinoTheme.of(context).scaffoldBackgroundColor
        : Theme.of(context).colorScheme.surface;
    final iconColor = isCupertino
        ? CupertinoTheme.of(context).textTheme.textStyle.color
        : Theme.of(context).colorScheme.onSurface;
    final shadow = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.12),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];

    if (isCupertino) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size.square(_size),
        onPressed: onPressed,
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.hairline),
            boxShadow: shadow,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      );
    }

    return Material(
      color: background,
      shape: const CircleBorder(side: BorderSide(color: AppColors.hairline)),
      elevation: 1,
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

class _FloatingProfileButton extends StatelessWidget {
  const _FloatingProfileButton({required this.onPressed, this.photoUrl});

  final VoidCallback onPressed;
  final String? photoUrl;

  static const double _size = 44;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    // White ring only for the flat-fill initial fallback, where it's
    // doing real contrast work against an arbitrary map color — once
    // there's an actual photo, match the sheet's own amber ring instead.
    final ringColor = hasPhoto ? AppColors.sunriseAmber : Colors.white;

    return GestureDetector(
      onTap: onPressed,
      child: RiderAvatarCircle(
        label: 'You',
        photoUrl: photoUrl,
        diameter: _size,
        background: AppColors.sunriseAmber,
        border: Border.all(color: ringColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }
}

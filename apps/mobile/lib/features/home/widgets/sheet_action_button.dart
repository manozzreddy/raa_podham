import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// A compact icon+label pill for a sheet's action row — the row of
/// primary actions that sits right under a sheet's header (Invite / End
/// ride, Create / Join, ...), the same way Google Maps places
/// Directions/Share/Save right under a place's title instead of pinning
/// them to the bottom of the sheet.
class SheetActionButton extends StatelessWidget {
  const SheetActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  /// Tints the pill red instead of the brand amber, for actions that end
  /// or remove the user from something (e.g. leaving/ending a ride).
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? (isCupertino ? CupertinoColors.destructiveRed : Colors.red)
        : AppColors.sunriseAmber;

    if (isCupertino) {
      return CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 10),
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        onPressed: onPressed,
        child: _Content(icon: icon, label: label, color: color),
      );
    }

    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: _Content(icon: icon, label: label, color: color),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A compact icon+label pill for a sheet or page's action row — the row
/// of primary actions right under a header (Invite / End ride, Create /
/// Join, Delete ride, ...). Used across both `home` (sheets) and `rides`
/// (`RideDetailScreen`'s action row) — promoted here once that second
/// feature needed it too, per this codebase's widget-sharing rule
/// (`.agents/rules/architecture.md`).
class SheetActionButton extends StatelessWidget {
  const SheetActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;

  /// Null renders the button in its normal disabled look (Flutter/
  /// Cupertino's own built-in dimming) rather than this widget needing
  /// its own separate disabled styling. Ignored (treated as disabled)
  /// while [isLoading] is true, so a caller can't accidentally leave the
  /// button tappable mid-request by forgetting to also null this out.
  final VoidCallback? onPressed;

  /// Tints the pill red instead of the brand amber, for actions that end
  /// or remove something (leaving/ending a ride, deleting a past one).
  final bool isDestructive;

  /// Swaps the icon+label for a small spinner and disables the button —
  /// for an action slow enough (a real network round trip, e.g. deleting
  /// a ride) that the built-in disabled dimming alone isn't a clear
  /// enough sign it's actually doing something, not just inert.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? (isCupertino ? CupertinoColors.destructiveRed : Colors.red)
        : AppColors.sunriseAmber;
    final effectiveOnPressed = isLoading ? null : onPressed;
    final content = isLoading
        ? Center(child: _LoadingContent(color: color))
        : _Content(icon: icon, label: label, color: color);

    if (isCupertino) {
      return CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 10),
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        onPressed: effectiveOnPressed,
        child: content,
      );
    }

    return FilledButton.tonal(
      onPressed: effectiveOnPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        disabledBackgroundColor: isLoading ? color.withValues(alpha: 0.12) : null,
        disabledForegroundColor: isLoading ? color : null,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: content,
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      width: 18,
      child: isCupertino
          ? CupertinoActivityIndicator(color: color)
          : CircularProgressIndicator(strokeWidth: 2, color: color),
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

import 'package:flutter/widgets.dart';

/// An icon plus a line of text — used by every "quick look" detail
/// view in the app (`RiderInfoSheet`, `RideDetailScreen`) for a labeled
/// fact like a distance, a scheduled time, or a destination. Promoted
/// here once a second feature needed the exact same shape a third file
/// was about to duplicate again — see `.agents/rules/architecture.md`'s
/// widget-sharing rule.
class InfoLine extends StatelessWidget {
  const InfoLine({
    super.key,
    required this.icon,
    required this.label,
    this.style,
    this.maxLines = 1,
  });

  final IconData icon;
  final String label;
  final TextStyle? style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: style?.color?.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

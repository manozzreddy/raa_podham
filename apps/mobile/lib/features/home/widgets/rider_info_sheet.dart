import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../widgets/info_line.dart';
import '../../../widgets/sheet_drag_handle.dart';
import '../view_model/home_view_model.dart';
import 'rider_avatar_chip.dart';
import 'sheet_action_button.dart';

/// The "quick look" modal opened from a rider's ⓘ — map marker label or
/// expanded sheet row alike — presented via `showModalBottomSheet`, not
/// a route: there's deliberately not enough content here to justify
/// navigating away from the map.
class RiderInfoSheet extends StatelessWidget {
  const RiderInfoSheet({
    super.key,
    required this.details,
    required this.onDirections,
    required this.onCenterMap,
    required this.onRemove,
  });

  final RiderInfoDetails details;
  final VoidCallback onDirections;
  final VoidCallback onCenterMap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final nameStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.navTitleTextStyle
        : Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700);
    final captionStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.bodyMedium;
    final mutedColor = captionStyle?.color?.withValues(alpha: 0.7);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: SheetDragHandle()),
            const SizedBox(height: 20),
            Row(
              children: [
                RiderAvatarCircle(
                  label: details.displayName,
                  photoUrl: details.photoUrl,
                  diameter: 60,
                  background: details.isSelf
                      ? AppColors.sunriseAmber
                      : AppColors.riderFallbackColor(details.uid),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              details.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: nameStyle,
                            ),
                          ),
                          if (details.isHost) ...[
                            const SizedBox(width: 8),
                            const _HostChip(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        details.lastUpdatedLabel,
                        style: captionStyle?.copyWith(
                          color: details.isOnline
                              ? AppColors.sunRimGold
                              : mutedColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            InfoLine(
              icon: isCupertino
                  ? CupertinoIcons.location_solid
                  : Icons.social_distance,
              label: details.distanceFromSelfLabel,
              style: captionStyle,
            ),
            if (details.distanceToDestinationLabel != null) ...[
              const SizedBox(height: 6),
              InfoLine(
                icon: isCupertino ? CupertinoIcons.flag_fill : Icons.flag,
                label: details.distanceToDestinationLabel!,
                style: captionStyle,
              ),
            ],
            if (details.relativeToSelfLabel != null) ...[
              const SizedBox(height: 6),
              InfoLine(
                icon: isCupertino
                    ? CupertinoIcons.arrow_left_right
                    : Icons.compare_arrows,
                label: details.relativeToSelfLabel!,
                style: captionStyle,
              ),
            ],
            // Directions/Center-map apply to anyone viewing someone
            // else, host or not — hidden for self since neither means
            // anything pointed at yourself.
            if (!details.isSelf) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SheetActionButton(
                      icon: isCupertino
                          ? CupertinoIcons.location_north_fill
                          : Icons.directions,
                      label: 'Directions',
                      onPressed: details.canNavigate
                          ? () {
                              Navigator.of(context).pop();
                              onDirections();
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SheetActionButton(
                      icon: isCupertino
                          ? CupertinoIcons.scope
                          : Icons.center_focus_strong,
                      label: 'Center map',
                      onPressed: details.canNavigate
                          ? () {
                              Navigator.of(context).pop();
                              onCenterMap();
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ],
            // Remove is its own, narrower condition — host only, on
            // someone else's row — rather than folding into the isSelf
            // check above: a non-host viewer sees Directions/Center-map
            // for another rider but must never see this.
            if (details.canRemove) ...[
              const SizedBox(height: 12),
              SheetActionButton(
                icon: isCupertino
                    ? CupertinoIcons.person_badge_minus
                    : Icons.person_remove_outlined,
                label: 'Remove from ride',
                isDestructive: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  onRemove();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HostChip extends StatelessWidget {
  const _HostChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.sunriseAmber,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'HOST',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

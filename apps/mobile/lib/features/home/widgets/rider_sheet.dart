import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../widgets/sheet_drag_handle.dart';
import '../view_model/home_view_model.dart';
import 'home_sheet_chrome.dart';
import 'info_icon_button.dart';
import 'reached_badge.dart';
import 'rider_avatar_chip.dart';
import 'sheet_action_button.dart';

/// Normalized sheet position (0 at [HomeScreen]'s min extent, 1 at its
/// max) past which the rider section switches from its collapsed chip
/// row to the full vertical rider list.
const double _sheetExpandedThreshold = 0.5;

/// The draggable rider sheet's content: header, a persistent action row
/// (Invite / End-Leave — always visible, not pinned to the bottom the
/// way they used to be), then a collapsed [_RiderChipRow] or (once
/// dragged up) a full [_RiderDetailList] — swapped based on
/// [sheetExtent] rather than owned by the ViewModel, since it's pure
/// drag-gesture UI state.
///
/// The drag handle, header, and action row scroll away with the rest of
/// the content rather than staying pinned above it — the whole thing is
/// one [ListView], not a fixed block followed by a separately-scrollable
/// list. A fixed block sized for its own content can't shrink below
/// that content's height, so at a low enough sheet extent it simply
/// doesn't fit and Flutter throws a RenderFlex overflow; a single
/// scrollable never has that failure mode; whatever doesn't fit in the
/// sheet's current height is just reached by scrolling instead.
class RiderSheet extends StatelessWidget {
  const RiderSheet({
    super.key,
    required this.rideName,
    this.destinationName,
    this.routeSummary,
    required this.riders,
    required this.isHost,
    required this.sheetExtent,
    required this.onInviteMore,
    required this.onCta,
    required this.onRiderTap,
    required this.onShowInfo,
  });

  final String rideName;

  /// The ride's destination, if one was set when it was created.
  final String? destinationName;

  /// E.g. "12.3 km, 24 min" from self to the destination, once the
  /// route's resolved — null while it's still pending or unavailable.
  final String? routeSummary;
  final List<RiderVm> riders;
  final bool isHost;
  final ValueListenable<double> sheetExtent;
  final VoidCallback onInviteMore;
  final VoidCallback onCta;

  /// Recenters the map on the tapped rider — see
  /// `HomeViewModel.locationOf`.
  final ValueChanged<String> onRiderTap;

  /// Opens the Rider Info modal — only reachable from the expanded list's
  /// own inline ⓘ (see `_RiderDetailRow`), not the collapsed chip row,
  /// there's no room for a second tap target at that density.
  final ValueChanged<String> onShowInfo;

  @override
  Widget build(BuildContext context) {
    final ctaLabel = isHost ? 'End ride' : 'Leave ride';

    return HomeSheetContainer(
      child: ValueListenableBuilder<double>(
        valueListenable: sheetExtent,
        builder: (context, extent, child) {
          final isExpanded = extent >= _sheetExpandedThreshold;
          return ListView(
            primary: true,
            physics: homeSheetSnapPhysics,
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 8),
              const Center(child: SheetDragHandle()),
              const SizedBox(height: 12),
              _HeaderRow(
                riderCount: riders.length,
                rideName: rideName,
                destinationName: destinationName,
                routeSummary: routeSummary,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: SheetActionButton(
                        icon: isCupertino
                            ? CupertinoIcons.person_add_solid
                            : Icons.person_add_alt_1,
                        label: 'Invite',
                        onPressed: onInviteMore,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SheetActionButton(
                        icon: isCupertino
                            ? CupertinoIcons.square_arrow_right
                            : Icons.logout,
                        label: ctaLabel,
                        onPressed: onCta,
                        isDestructive: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isExpanded
                    ? _RiderDetailList(
                        key: const ValueKey('expanded'),
                        riders: riders,
                        onRiderTap: onRiderTap,
                        onShowInfo: onShowInfo,
                      )
                    : _CollapsedContent(
                        key: const ValueKey('collapsed'),
                        riders: riders,
                        onRiderTap: onRiderTap,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.riderCount,
    required this.rideName,
    this.destinationName,
    this.routeSummary,
  });

  final int riderCount;
  final String rideName;
  final String? destinationName;
  final String? routeSummary;

  @override
  Widget build(BuildContext context) {
    final nameStyle = isCupertino
        ? CupertinoTheme.of(
            context,
          ).textTheme.navTitleTextStyle.copyWith(fontSize: 20)
        : Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700);
    final countStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.bodyMedium;
    final countColor = countStyle?.color?.withValues(alpha: 0.7);
    final countLabel = riderCount == 1 ? '1 rider' : '$riderCount riders';
    final destination = destinationName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rideName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: nameStyle,
          ),
          if (destination != null) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(
                  isCupertino ? CupertinoIcons.location_solid : Icons.place,
                  size: 14,
                  color: AppColors.sunriseAmber,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    destination,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: countStyle?.copyWith(
                      color: countColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (routeSummary != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    routeSummary!,
                    maxLines: 1,
                    style: countStyle?.copyWith(color: countColor),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 4),
          Text(countLabel, style: countStyle?.copyWith(color: countColor)),
        ],
      ),
    );
  }
}

class _CollapsedContent extends StatelessWidget {
  const _CollapsedContent({
    super.key,
    required this.riders,
    required this.onRiderTap,
  });

  final List<RiderVm> riders;
  final ValueChanged<String> onRiderTap;

  @override
  Widget build(BuildContext context) {
    // No scrollable of its own — RiderSheet's outer ListView is the only
    // scrollable now, this just supplies one of its items.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: _RiderChipRow(riders: riders, onRiderTap: onRiderTap),
    );
  }
}

class _RiderChipRow extends StatelessWidget {
  const _RiderChipRow({required this.riders, required this.onRiderTap});

  final List<RiderVm> riders;
  final ValueChanged<String> onRiderTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: riders.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final rider = riders[index];
          return RiderAvatarChip(
            uid: rider.uid,
            displayName: rider.displayName,
            photoUrl: rider.photoUrl,
            distanceLabel: rider.distanceLabel,
            isOnline: rider.isOnline,
            isSelf: rider.isSelf,
            isHost: rider.isHost,
            hasReachedDestination: rider.hasReachedDestination,
            onTap: () => onRiderTap(rider.uid),
          );
        },
      ),
    );
  }
}

class _RiderDetailList extends StatelessWidget {
  const _RiderDetailList({
    super.key,
    required this.riders,
    required this.onRiderTap,
    required this.onShowInfo,
  });

  final List<RiderVm> riders;
  final ValueChanged<String> onRiderTap;
  final ValueChanged<String> onShowInfo;

  @override
  Widget build(BuildContext context) {
    // No scrollable of its own — see _CollapsedContent.
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        children: [
          for (final rider in riders)
            _RiderDetailRow(
              rider: rider,
              onTap: () => onRiderTap(rider.uid),
              onShowInfo: () => onShowInfo(rider.uid),
            ),
        ],
      ),
    );
  }
}

class _RiderDetailRow extends StatelessWidget {
  const _RiderDetailRow({
    required this.rider,
    required this.onTap,
    required this.onShowInfo,
  });

  final RiderVm rider;
  final VoidCallback onTap;
  final VoidCallback onShowInfo;

  @override
  Widget build(BuildContext context) {
    final avatarBackground = rider.isSelf
        ? AppColors.sunriseAmber
        : AppColors.riderFallbackColor(rider.uid);
    final sheetBackground = isCupertino
        ? CupertinoTheme.of(context).scaffoldBackgroundColor
        : Theme.of(context).colorScheme.surface;

    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(rider.displayName, overflow: TextOverflow.ellipsis),
        ),
        if (rider.isHost) ...[
          const SizedBox(width: 6),
          HostBadge(ringColor: sheetBackground),
        ],
        if (rider.hasReachedDestination) ...[
          const SizedBox(width: 6),
          ReachedBadge(ringColor: sheetBackground),
        ],
      ],
    );

    // Self gets an info icon too now — the modal adapts what it shows
    // for yourself (e.g. no Directions/Center-map/Remove, since none of
    // those apply to yourself) rather than being excluded entirely.
    final infoIcon = InfoIconButton(
      onTap: onShowInfo,
      color: sheetBackground.computeLuminance() > 0.5
          ? AppColors.asphaltInk.withValues(alpha: 0.6)
          : Colors.white70,
    );

    if (isCupertino) {
      return CupertinoListTile(
        onTap: onTap,
        leading: RiderAvatarCircle(
          label: rider.displayName,
          photoUrl: rider.photoUrl,
          diameter: 40,
          background: avatarBackground,
        ),
        title: title,
        additionalInfo: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(rider.distanceLabel),
            if (rider.isOnline) ...[
              const SizedBox(width: 8),
              const _LiveStatusPulse(size: 8),
            ],
          ],
        ),
        trailing: infoIcon,
      );
    }

    return ListTile(
      onTap: onTap,
      leading: RiderAvatarCircle(
        label: rider.displayName,
        photoUrl: rider.photoUrl,
        diameter: 40,
        background: avatarBackground,
      ),
      title: title,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rider.distanceLabel,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (rider.isOnline) ...[
            const SizedBox(width: 8),
            const _LiveStatusPulse(size: 8),
          ],
          const SizedBox(width: 8),
          infoIcon,
        ],
      ),
    );
  }
}

/// A small pulsing gold dot, indicating a rider's position is updating
/// live.
class _LiveStatusPulse extends StatefulWidget {
  const _LiveStatusPulse({required this.size});

  final double size;

  @override
  State<_LiveStatusPulse> createState() => _LiveStatusPulseState();
}

class _LiveStatusPulseState extends State<_LiveStatusPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2.5,
      height: widget.size * 2.5,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 1 - t,
                child: Transform.scale(
                  scale: 1 + t * 1.5,
                  child: _dot(widget.size),
                ),
              ),
              _dot(widget.size),
            ],
          );
        },
      ),
    );
  }

  Widget _dot(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.sunRimGold,
        shape: BoxShape.circle,
      ),
    );
  }
}

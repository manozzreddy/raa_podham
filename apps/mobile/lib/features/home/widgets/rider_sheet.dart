import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../widgets/sheet_drag_area.dart';
import '../../../widgets/sheet_drag_handle.dart';
import '../view_model/home_view_model.dart';
import 'home_sheet_chrome.dart';
import 'rider_avatar_chip.dart';
import 'sheet_action_button.dart';

/// Sheet fractional extent past which the rider section switches from its
/// collapsed chip row to the full vertical rider list.
const double _sheetExpandedThreshold = 0.5;

/// The draggable rider sheet's content: header, a persistent action row
/// (Invite / End-Leave — always visible, not pinned to the bottom the
/// way they used to be), then a collapsed [_RiderChipRow] or (once
/// dragged up) a full [_RiderDetailList] — swapped based on
/// [sheetExtent] rather than owned by the ViewModel, since it's pure
/// drag-gesture UI state.
class RiderSheet extends StatelessWidget {
  const RiderSheet({
    super.key,
    required this.rideName,
    required this.riders,
    required this.isHost,
    required this.sheetExtent,
    required this.sheetController,
    required this.sheetMinExtent,
    required this.sheetMaxExtent,
    required this.scrollController,
    required this.onInviteMore,
    required this.onCta,
    required this.onRiderTap,
  });

  final String rideName;
  final List<RiderVm> riders;
  final bool isHost;
  final ValueListenable<double> sheetExtent;
  final DraggableScrollableController sheetController;
  final double sheetMinExtent;
  final double sheetMaxExtent;
  final ScrollController scrollController;
  final VoidCallback onInviteMore;
  final VoidCallback onCta;

  /// Recenters the map on the tapped rider — see
  /// `HomeViewModel.locationOf`.
  final ValueChanged<String> onRiderTap;

  @override
  Widget build(BuildContext context) {
    final ctaLabel = isHost ? 'End ride' : 'Leave ride';

    return HomeSheetContainer(
      child: Column(
        children: [
          SheetDragArea(
            controller: sheetController,
            minExtent: sheetMinExtent,
            maxExtent: sheetMaxExtent,
            child: Column(
              children: [
                const SizedBox(height: 8),
                const SheetDragHandle(),
                const SizedBox(height: 12),
                _HeaderRow(riderCount: riders.length, rideName: rideName),
              ],
            ),
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
          Expanded(
            child: ValueListenableBuilder<double>(
              valueListenable: sheetExtent,
              builder: (context, extent, child) {
                final isExpanded = extent >= _sheetExpandedThreshold;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isExpanded
                      ? _RiderDetailList(
                          key: const ValueKey('expanded'),
                          riders: riders,
                          scrollController: scrollController,
                          onRiderTap: onRiderTap,
                        )
                      : _CollapsedContent(
                          key: const ValueKey('collapsed'),
                          riders: riders,
                          scrollController: scrollController,
                          onRiderTap: onRiderTap,
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.riderCount, required this.rideName});

  final int riderCount;
  final String rideName;

  @override
  Widget build(BuildContext context) {
    final nameStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.navTitleTextStyle
        : Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700);
    final countStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.bodyMedium;
    final countColor = countStyle?.color?.withValues(alpha: 0.7);
    final countLabel = riderCount == 1 ? '1 rider' : '$riderCount riders';

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
          const SizedBox(height: 2),
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
    required this.scrollController,
    required this.onRiderTap,
  });

  final List<RiderVm> riders;
  final ScrollController scrollController;
  final ValueChanged<String> onRiderTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
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
            displayName: rider.displayName,
            photoUrl: rider.photoUrl,
            distanceLabel: rider.distanceLabel,
            isOnline: rider.isOnline,
            isSelf: rider.isSelf,
            isHost: rider.isHost,
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
    required this.scrollController,
    required this.onRiderTap,
  });

  final List<RiderVm> riders;
  final ScrollController scrollController;
  final ValueChanged<String> onRiderTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      itemCount: riders.length,
      separatorBuilder: (context, index) => const SizedBox.shrink(),
      itemBuilder: (context, index) {
        final rider = riders[index];
        return _RiderDetailRow(
          rider: rider,
          onTap: () => onRiderTap(rider.uid),
        );
      },
    );
  }
}

class _RiderDetailRow extends StatelessWidget {
  const _RiderDetailRow({required this.rider, required this.onTap});

  final RiderVm rider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatarBackground = rider.isSelf
        ? AppColors.sunriseAmber
        : AppColors.predawnIndigo;
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
      ],
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
        trailing: const CupertinoListTileChevron(),
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

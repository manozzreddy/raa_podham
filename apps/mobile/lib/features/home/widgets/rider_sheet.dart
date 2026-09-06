import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../theme/theme.dart';
import '../models/rider.dart';
import 'rider_avatar_chip.dart';

/// The draggable rider sheet's content: a header, a collapsed chip row +
/// "End ride" CTA, or (once dragged up) a full vertical rider list.
class RiderSheet extends StatelessWidget {
  const RiderSheet({
    super.key,
    required this.rideName,
    required this.riders,
    required this.selfLocation,
    required this.isExpanded,
    required this.scrollController,
    required this.onEndRide,
  });

  final String rideName;
  final List<Rider> riders;
  final LatLng selfLocation;
  final bool isExpanded;
  final ScrollController scrollController;
  final VoidCallback onEndRide;

  @override
  Widget build(BuildContext context) {
    final sheetBackground = isCupertino
        ? CupertinoTheme.of(context).scaffoldBackgroundColor
        : Theme.of(context).colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: sheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const _DragHandle(),
          const SizedBox(height: 12),
          _HeaderRow(riderCount: riders.length, rideName: rideName),
          const SizedBox(height: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isExpanded
                  ? _ExpandedRiderList(
                      key: const ValueKey('expanded'),
                      riders: riders,
                      selfLocation: selfLocation,
                      scrollController: scrollController,
                    )
                  : _CollapsedContent(
                      key: const ValueKey('collapsed'),
                      riders: riders,
                      selfLocation: selfLocation,
                      scrollController: scrollController,
                      onEndRide: onEndRide,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.hairline,
        borderRadius: BorderRadius.circular(2),
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
    final boldStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.navTitleTextStyle
        : Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    final mutedStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.bodyMedium;
    final mutedColor = mutedStyle?.color?.withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text('$riderCount riders', style: boldStyle),
          const Spacer(),
          Flexible(
            child: Text(
              rideName,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: mutedStyle?.copyWith(color: mutedColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapsedContent extends StatelessWidget {
  const _CollapsedContent({
    super.key,
    required this.riders,
    required this.selfLocation,
    required this.scrollController,
    required this.onEndRide,
  });

  final List<Rider> riders;
  final LatLng selfLocation;
  final ScrollController scrollController;
  final VoidCallback onEndRide;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: riders.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final rider = riders[index];
                return RiderAvatarChip(
                  displayName: rider.displayName,
                  distanceLabel: formatRiderDistance(rider, selfLocation),
                  isOnline: rider.isOnline,
                  isSelf: rider.isSelf,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _EndRideButton(onPressed: onEndRide),
        ],
      ),
    );
  }
}

class _EndRideButton extends StatelessWidget {
  const _EndRideButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isCupertino) {
      return SizedBox(
        width: double.infinity,
        child: CupertinoButton.filled(
          borderRadius: BorderRadius.circular(999),
          onPressed: onPressed,
          child: const Text('End ride'),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        child: const Text('End ride'),
      ),
    );
  }
}

class _ExpandedRiderList extends StatelessWidget {
  const _ExpandedRiderList({
    super.key,
    required this.riders,
    required this.selfLocation,
    required this.scrollController,
  });

  final List<Rider> riders;
  final LatLng selfLocation;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
      itemCount: riders.length,
      separatorBuilder: (context, index) => const SizedBox.shrink(),
      itemBuilder: (context, index) {
        final rider = riders[index];
        final distanceLabel = formatRiderDistance(rider, selfLocation);
        final avatarBackground = rider.isSelf ? AppColors.sunriseAmber : AppColors.predawnIndigo;

        if (isCupertino) {
          return CupertinoListTile(
            leading: RiderAvatarCircle(label: rider.displayName, diameter: 40, background: avatarBackground),
            title: Text(rider.displayName),
            additionalInfo: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(distanceLabel),
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
          leading: RiderAvatarCircle(label: rider.displayName, diameter: 40, background: avatarBackground),
          title: Text(rider.displayName),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(distanceLabel, style: Theme.of(context).textTheme.bodyMedium),
              if (rider.isOnline) ...[
                const SizedBox(width: 8),
                const _LiveStatusPulse(size: 8),
              ],
            ],
          ),
        );
      },
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

class _LiveStatusPulseState extends State<_LiveStatusPulse> with SingleTickerProviderStateMixin {
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
      decoration: const BoxDecoration(color: AppColors.sunRimGold, shape: BoxShape.circle),
    );
  }
}

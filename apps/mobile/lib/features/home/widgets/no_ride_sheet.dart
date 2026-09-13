import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../widgets/sheet_drag_area.dart';
import '../../../widgets/sheet_drag_handle.dart';
import 'home_sheet_chrome.dart';
import 'sheet_action_button.dart';

/// The draggable sheet's content when the signed-in user isn't currently
/// in a ride: a persistent action row (Create / Join — always visible,
/// same pattern [RiderSheet] uses for its own actions) and nothing else
/// — no past-rides list, per product direction.
class NoRideSheet extends StatelessWidget {
  const NoRideSheet({
    super.key,
    required this.sheetController,
    required this.sheetMinExtent,
    required this.sheetMaxExtent,
    required this.onCreateRide,
    required this.onJoinRide,
  });

  final DraggableScrollableController sheetController;
  final double sheetMinExtent;
  final double sheetMaxExtent;
  final VoidCallback onCreateRide;
  final VoidCallback onJoinRide;

  @override
  Widget build(BuildContext context) {
    final headerStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.navTitleTextStyle
              .copyWith(fontSize: 22, fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700);
    final bodyStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.bodyMedium;

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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [Text('Start riding', style: headerStyle)],
                  ),
                ),
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
                    icon: isCupertino ? CupertinoIcons.add_circled : Icons.add,
                    label: 'Create ride',
                    onPressed: onCreateRide,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SheetActionButton(
                    icon: isCupertino ? CupertinoIcons.qrcode : Icons.group_add,
                    label: 'Join ride',
                    onPressed: onJoinRide,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  "You're not in a ride yet. Create one or join with an invite code.",
                  textAlign: TextAlign.center,
                  style: bodyStyle?.copyWith(
                    color: bodyStyle.color?.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sheet/sheet.dart';

import '../../../theme/theme.dart';

/// The physics [HomeScreen]'s outer `Sheet` drags/snaps with — also
/// handed to every scrollable list inside [RiderSheet]/[NoRideSheet].
/// A nested `Scrollable` only joins the sheet's own snap-on-release
/// behavior when it declares this same [SheetPhysics] itself; left to
/// its default physics, dragging the list body (rather than the fixed
/// header) settles wherever the finger lifts instead of snapping.
const SheetPhysics homeSheetSnapPhysics = SnapSheetPhysics(
  stops: <double>[0, 1],
);

/// The rounded, shadowed card every draggable sheet on the home screen
/// sits in — shared by [RiderSheet] and [NoRideSheet] so both draggable
/// sheet contents look identical regardless of which state the home
/// screen is in.
class HomeSheetContainer extends StatelessWidget {
  const HomeSheetContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sheetBackground = isCupertino
        ? CupertinoTheme.of(context).scaffoldBackgroundColor
        : Theme.of(context).colorScheme.surface;

    const shape = BorderRadius.vertical(top: Radius.circular(20));

    return Container(
      decoration: BoxDecoration(
        color: sheetBackground,
        borderRadius: shape,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      // The outer Container above is a plain DecoratedBox — Material
      // widgets like RiderSheet's ListTile rows paint their background
      // and ink splashes on the nearest Material ancestor, which a
      // DecoratedBox doesn't provide. This inner transparent Material
      // supplies that surface without adding a second background/shadow
      // of its own; ClipRRect keeps ink splashes from spilling past the
      // same rounded corners the outer decoration already draws.
      child: ClipRRect(
        borderRadius: shape,
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );
  }
}

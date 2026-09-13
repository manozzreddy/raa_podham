import 'package:flutter/widgets.dart';

/// Makes [child] (a sheet's fixed header — [SheetDragHandle] plus
/// whatever sits next to it) drag the sheet's own extent directly.
///
/// [DraggableScrollableSheet] only resizes in response to dragging its
/// scrollable content once that's already scrolled to the top — a fixed
/// header above that scrollable (where the drag handle actually is) has
/// no gesture wired to it at all otherwise, so touching the handle itself
/// does nothing despite looking draggable.
class SheetDragArea extends StatelessWidget {
  const SheetDragArea({
    super.key,
    required this.controller,
    required this.minExtent,
    required this.maxExtent,
    required this.child,
  });

  final DraggableScrollableController controller;
  final double minExtent;
  final double maxExtent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (details) {
        // The gesture arena keeps delivering drag-update callbacks to
        // this closure for a gesture already in progress even if the
        // sheet itself gets torn down mid-drag (e.g. the ride list
        // reloading and swapping RiderSheet/NoRideSheet out from under
        // it) — controller.size/.jumpTo() both assert on an unattached
        // controller, so this has to check first rather than catch.
        if (!controller.isAttached) return;
        final screenHeight = MediaQuery.sizeOf(context).height;
        final newExtent = controller.size - details.delta.dy / screenHeight;
        controller.jumpTo(newExtent.clamp(minExtent, maxExtent));
      },
      child: child,
    );
  }
}

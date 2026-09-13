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
        try {
          controller.jumpTo(newExtent.clamp(minExtent, maxExtent));
        } on AssertionError {
          // Same underlying cause as the isAttached check above, just a
          // narrower window that check can't catch: isAttached only means
          // "attached to at least one" scrollable, but for one frame
          // during a RiderSheet/NoRideSheet swap the controller can be
          // attached to *both* the outgoing and incoming sheet at once —
          // jumpTo()'s own internal ScrollPosition lookup asserts there's
          // exactly one. Dropping this single drag-update is fine: the
          // next one (or the sheet's own snap) picks up from wherever the
          // now-single remaining sheet actually settled.
        }
      },
      child: child,
    );
  }
}

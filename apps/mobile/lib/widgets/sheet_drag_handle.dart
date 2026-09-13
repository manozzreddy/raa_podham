import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// The small pill at the top-center of a bottom sheet.
///
/// Every Material bottom sheet in the app should start with this —
/// [HomeScreen]'s rider/no-ride sheets, the sign-out sheet, the support
/// sheet, and any new one — so sheets share one consistent look.
/// Cupertino's `CupertinoActionSheet` is exempt: native iOS action sheets
/// never have a drag handle.
class SheetDragHandle extends StatelessWidget {
  const SheetDragHandle({super.key});

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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../widgets/permission_rationale_scaffold.dart';

/// Shown once, in place of the map, the first time an active ride is
/// about to start reporting this device's position — before background
/// location, the foreground-service notification, and the
/// battery-optimization exemption are ever requested (see
/// `HomeViewModel.allowBackgroundSharing`/`skipBackgroundSharing`, which
/// this screen's two actions call).
///
/// Unlike [LocationPermissionScreen] this never blocks anything: "Not
/// now" proceeds straight to foreground-only reporting, the same
/// fallback a plain denial would already leave a rider in.
class BackgroundSharingPermissionScreen extends StatelessWidget {
  const BackgroundSharingPermissionScreen({
    super.key,
    required this.onAllow,
    required this.onSkip,
  });

  final Future<void> Function() onAllow;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return PermissionRationaleScaffold(
      badgeIcon: Icons.sync_alt,
      badgeCupertinoIcon: CupertinoIcons.arrow_2_circlepath,
      title: 'Keep sharing while you ride',
      body:
          'To keep your position visible to the group even when your '
          'phone is locked or another app is open, Raa Podham needs a '
          'few more permissions.',
      reasons: const [
        PermissionReason(
          icon: Icons.location_history_outlined,
          cupertinoIcon: CupertinoIcons.location_fill,
          text: 'Share your position with the group even in the background',
        ),
        PermissionReason(
          icon: Icons.notifications_active_outlined,
          cupertinoIcon: CupertinoIcons.bell_fill,
          text: 'Show a notification so you always know sharing is active',
        ),
        PermissionReason(
          icon: Icons.battery_charging_full_outlined,
          cupertinoIcon: CupertinoIcons.battery_charging,
          text: 'Stop your phone from pausing sharing to save battery',
        ),
      ],
      primaryLabel: 'Allow',
      onPrimaryPressed: onAllow,
      onSkip: onSkip,
      footer: 'You can turn these on later from your device settings.',
    );
  }
}

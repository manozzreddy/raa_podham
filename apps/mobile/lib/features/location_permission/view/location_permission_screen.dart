import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../services/permission_service.dart';
import '../../../theme/theme.dart';
import '../../../widgets/app_error_screen.dart';
import '../../../widgets/permission_rationale_scaffold.dart';
import '../view_model/location_permission_view_model.dart';

/// The mandatory gate between sign-in and `/home`: explains why Raa
/// Podham needs location before the OS permission prompt ever appears,
/// then requests it. `app.dart`'s router redirect sends the user back
/// here on every navigation attempt until permission is granted, so
/// there's no skip button and no way around it — the map is the app, and
/// it has nothing useful to show without a location.
class LocationPermissionScreen extends ConsumerStatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  ConsumerState<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState
    extends ConsumerState<LocationPermissionScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Picks up a grant made from the device's own Settings app (the only
  /// way back in once [LocationPermissionStatus.permanentlyDenied]) as
  /// soon as this screen is back in the foreground, with no extra tap
  /// needed from the user.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(locationPermissionViewModelProvider.notifier).refreshStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(locationPermissionViewModelProvider);
    final notifier = ref.read(locationPermissionViewModelProvider.notifier);

    ref.listen<AsyncValue<LocationPermissionUiState>>(
      locationPermissionViewModelProvider,
      (previous, next) {
        if (next.value?.status == LocationPermissionStatus.granted) {
          context.go('/home');
        }
      },
    );

    return stateAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (error, stackTrace) => AppErrorScreen(
        error: error,
        stackTrace: stackTrace,
        message: "Couldn't check your location permission.",
        onRetry: () => ref.invalidate(locationPermissionViewModelProvider),
      ),
      data: (state) {
        final isPermanentlyDenied =
            state.status == LocationPermissionStatus.permanentlyDenied;
        return PermissionRationaleScaffold(
          badgeIcon: Icons.location_on,
          badgeCupertinoIcon: CupertinoIcons.location_solid,
          title: 'Turn on location',
          body: isPermanentlyDenied
              ? "Location access for Raa Podham is currently off. Open "
                    "Settings and allow it so your group can see you on the "
                    "map."
              : "Raa Podham shows your group where you are on a shared "
                    "map, and shows you where they are too.",
          reasons: const [
            PermissionReason(
              icon: Icons.map_outlined,
              cupertinoIcon: CupertinoIcons.map,
              text: 'See every rider in your group on one live map',
            ),
            PermissionReason(
              icon: Icons.share_location_outlined,
              cupertinoIcon: CupertinoIcons.location_fill,
              text: 'Let your group see your position too',
            ),
            PermissionReason(
              icon: Icons.bolt_outlined,
              cupertinoIcon: CupertinoIcons.bolt_fill,
              text: 'Keeps sharing your position steady, even in the background',
            ),
          ],
          primaryLabel: isPermanentlyDenied ? 'Open Settings' : 'Allow Location Access',
          onPrimaryPressed: isPermanentlyDenied
              ? notifier.openSettings
              : notifier.requestPermission,
          warning: state.hasBeenDenied && !isPermanentlyDenied
              ? 'Location is required for Raa Podham to work. Please allow '
                    'it to continue.'
              : null,
          footer: 'You can change this anytime in your device settings.',
        );
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    final indicator = isCupertino
        ? const CupertinoActivityIndicator()
        : const CircularProgressIndicator();
    if (isCupertino) {
      return CupertinoPageScaffold(child: Center(child: indicator));
    }
    return Scaffold(body: Center(child: indicator));
  }
}

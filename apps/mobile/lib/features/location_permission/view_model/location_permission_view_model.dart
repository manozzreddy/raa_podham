import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/permission_service.dart';

part 'location_permission_view_model.g.dart';

class LocationPermissionUiState {
  const LocationPermissionUiState({
    required this.status,
    required this.hasBeenDenied,
  });

  final LocationPermissionStatus status;

  /// True once a request from this screen visit has come back short of
  /// granted at least once — lets the View switch from the plain "why we
  /// ask" copy to a firmer "this is required to continue" note, without
  /// showing that to someone who hasn't tried yet.
  final bool hasBeenDenied;
}

/// Drives [LocationPermissionScreen]: checks where location permission
/// stands, requests it (or opens Settings) on the user's tap, and
/// re-checks on demand so a grant made from Settings is picked up
/// without needing another tap.
@riverpod
class LocationPermissionViewModel extends _$LocationPermissionViewModel {
  @override
  Future<LocationPermissionUiState> build() async {
    final status = await ref.read(permissionServiceProvider).locationWhenInUseStatus();
    return LocationPermissionUiState(status: status, hasBeenDenied: false);
  }

  Future<void> requestPermission() async {
    final status = await ref
        .read(permissionServiceProvider)
        .requestLocationWhenInUse();
    // The OS permission dialog can itself trigger an app lifecycle
    // resume (see refreshStatus), which races this call: whichever of
    // the two finishes first sets state to granted, which navigates away
    // and disposes this auto-dispose provider — the other must not then
    // touch `state`/`ref`, or it throws UnmountedRefException.
    if (!ref.mounted) return;
    state = AsyncData(
      LocationPermissionUiState(
        status: status,
        hasBeenDenied: status != LocationPermissionStatus.granted,
      ),
    );
  }

  Future<void> openSettings() => ref.read(permissionServiceProvider).openSettings();

  /// Re-checks status without prompting — called when the screen resumes
  /// from the background, so a grant made from the device's Settings app
  /// (the only path once [LocationPermissionStatus.permanentlyDenied])
  /// is picked up on its own.
  Future<void> refreshStatus() async {
    final status = await ref.read(permissionServiceProvider).locationWhenInUseStatus();
    // See requestPermission's own comment — the same race applies here,
    // just with the two calls' roles swapped.
    if (!ref.mounted) return;
    final hasBeenDenied = state.value?.hasBeenDenied ?? false;
    state = AsyncData(
      LocationPermissionUiState(status: status, hasBeenDenied: hasBeenDenied),
    );
  }
}

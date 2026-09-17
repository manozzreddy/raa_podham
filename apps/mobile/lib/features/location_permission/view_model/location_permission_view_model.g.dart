// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_permission_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives [LocationPermissionScreen]: checks where location permission
/// stands, requests it (or opens Settings) on the user's tap, and
/// re-checks on demand so a grant made from Settings is picked up
/// without needing another tap.

@ProviderFor(LocationPermissionViewModel)
final locationPermissionViewModelProvider =
    LocationPermissionViewModelProvider._();

/// Drives [LocationPermissionScreen]: checks where location permission
/// stands, requests it (or opens Settings) on the user's tap, and
/// re-checks on demand so a grant made from Settings is picked up
/// without needing another tap.
final class LocationPermissionViewModelProvider
    extends
        $AsyncNotifierProvider<
          LocationPermissionViewModel,
          LocationPermissionUiState
        > {
  /// Drives [LocationPermissionScreen]: checks where location permission
  /// stands, requests it (or opens Settings) on the user's tap, and
  /// re-checks on demand so a grant made from Settings is picked up
  /// without needing another tap.
  LocationPermissionViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationPermissionViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationPermissionViewModelHash();

  @$internal
  @override
  LocationPermissionViewModel create() => LocationPermissionViewModel();
}

String _$locationPermissionViewModelHash() =>
    r'66a2c6600bcbc4960840eb60ed2ac6fd96d6b347';

/// Drives [LocationPermissionScreen]: checks where location permission
/// stands, requests it (or opens Settings) on the user's tap, and
/// re-checks on demand so a grant made from Settings is picked up
/// without needing another tap.

abstract class _$LocationPermissionViewModel
    extends $AsyncNotifier<LocationPermissionUiState> {
  FutureOr<LocationPermissionUiState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<LocationPermissionUiState>,
              LocationPermissionUiState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<LocationPermissionUiState>,
                LocationPermissionUiState
              >,
              AsyncValue<LocationPermissionUiState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

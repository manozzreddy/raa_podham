// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'no_active_ride_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The landing screen's view model for when there's no active ride.
///
/// Mirrors [HomeViewModel]'s self-location/follow mechanics exactly (down
/// to sharing [acquireCurrentPosition]) but with no ride to merge them
/// with — kept as its own small notifier rather than a degenerate case of
/// [HomeViewModel], since that one is keyed on a [Ride] it wouldn't have
/// yet.

@ProviderFor(NoActiveRideViewModel)
final noActiveRideViewModelProvider = NoActiveRideViewModelProvider._();

/// The landing screen's view model for when there's no active ride.
///
/// Mirrors [HomeViewModel]'s self-location/follow mechanics exactly (down
/// to sharing [acquireCurrentPosition]) but with no ride to merge them
/// with — kept as its own small notifier rather than a degenerate case of
/// [HomeViewModel], since that one is keyed on a [Ride] it wouldn't have
/// yet.
final class NoActiveRideViewModelProvider
    extends $AsyncNotifierProvider<NoActiveRideViewModel, NoActiveRideUiState> {
  /// The landing screen's view model for when there's no active ride.
  ///
  /// Mirrors [HomeViewModel]'s self-location/follow mechanics exactly (down
  /// to sharing [acquireCurrentPosition]) but with no ride to merge them
  /// with — kept as its own small notifier rather than a degenerate case of
  /// [HomeViewModel], since that one is keyed on a [Ride] it wouldn't have
  /// yet.
  NoActiveRideViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noActiveRideViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noActiveRideViewModelHash();

  @$internal
  @override
  NoActiveRideViewModel create() => NoActiveRideViewModel();
}

String _$noActiveRideViewModelHash() =>
    r'31bcadf7937d2325efc5bda5e39b1aba084cab72';

/// The landing screen's view model for when there's no active ride.
///
/// Mirrors [HomeViewModel]'s self-location/follow mechanics exactly (down
/// to sharing [acquireCurrentPosition]) but with no ride to merge them
/// with — kept as its own small notifier rather than a degenerate case of
/// [HomeViewModel], since that one is keyed on a [Ride] it wouldn't have
/// yet.

abstract class _$NoActiveRideViewModel
    extends $AsyncNotifier<NoActiveRideUiState> {
  FutureOr<NoActiveRideUiState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<NoActiveRideUiState>, NoActiveRideUiState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<NoActiveRideUiState>, NoActiveRideUiState>,
              AsyncValue<NoActiveRideUiState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

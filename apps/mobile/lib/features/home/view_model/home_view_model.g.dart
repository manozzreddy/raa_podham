// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The home screen's view model, scoped to one ride.
///
/// Resolves the device's own location, merges it with
/// [ridersForRideProvider]'s live riders, and holds the screen's
/// map-follow state. Widget-level concerns — the `MapController`, the
/// rider sheet's own drag mechanics — stay in the View (`HomeScreen`) and
/// react to this state rather than living here.

@ProviderFor(HomeViewModel)
final homeViewModelProvider = HomeViewModelFamily._();

/// The home screen's view model, scoped to one ride.
///
/// Resolves the device's own location, merges it with
/// [ridersForRideProvider]'s live riders, and holds the screen's
/// map-follow state. Widget-level concerns — the `MapController`, the
/// rider sheet's own drag mechanics — stay in the View (`HomeScreen`) and
/// react to this state rather than living here.
final class HomeViewModelProvider
    extends $AsyncNotifierProvider<HomeViewModel, HomeUiState> {
  /// The home screen's view model, scoped to one ride.
  ///
  /// Resolves the device's own location, merges it with
  /// [ridersForRideProvider]'s live riders, and holds the screen's
  /// map-follow state. Widget-level concerns — the `MapController`, the
  /// rider sheet's own drag mechanics — stay in the View (`HomeScreen`) and
  /// react to this state rather than living here.
  HomeViewModelProvider._({
    required HomeViewModelFamily super.from,
    required Ride super.argument,
  }) : super(
         retry: null,
         name: r'homeViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$homeViewModelHash();

  @override
  String toString() {
    return r'homeViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  HomeViewModel create() => HomeViewModel();

  @override
  bool operator ==(Object other) {
    return other is HomeViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$homeViewModelHash() => r'66d9feb90888cb3c60620b3533cabe1278431563';

/// The home screen's view model, scoped to one ride.
///
/// Resolves the device's own location, merges it with
/// [ridersForRideProvider]'s live riders, and holds the screen's
/// map-follow state. Widget-level concerns — the `MapController`, the
/// rider sheet's own drag mechanics — stay in the View (`HomeScreen`) and
/// react to this state rather than living here.

final class HomeViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          HomeViewModel,
          AsyncValue<HomeUiState>,
          HomeUiState,
          FutureOr<HomeUiState>,
          Ride
        > {
  HomeViewModelFamily._()
    : super(
        retry: null,
        name: r'homeViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The home screen's view model, scoped to one ride.
  ///
  /// Resolves the device's own location, merges it with
  /// [ridersForRideProvider]'s live riders, and holds the screen's
  /// map-follow state. Widget-level concerns — the `MapController`, the
  /// rider sheet's own drag mechanics — stay in the View (`HomeScreen`) and
  /// react to this state rather than living here.

  HomeViewModelProvider call(Ride ride) =>
      HomeViewModelProvider._(argument: ride, from: this);

  @override
  String toString() => r'homeViewModelProvider';
}

/// The home screen's view model, scoped to one ride.
///
/// Resolves the device's own location, merges it with
/// [ridersForRideProvider]'s live riders, and holds the screen's
/// map-follow state. Widget-level concerns — the `MapController`, the
/// rider sheet's own drag mechanics — stay in the View (`HomeScreen`) and
/// react to this state rather than living here.

abstract class _$HomeViewModel extends $AsyncNotifier<HomeUiState> {
  late final _$args = ref.$arg as Ride;
  Ride get ride => _$args;

  FutureOr<HomeUiState> build(Ride ride);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<HomeUiState>, HomeUiState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<HomeUiState>, HomeUiState>,
              AsyncValue<HomeUiState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

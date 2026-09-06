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
/// interaction state (following/sheet-expanded). Widget-level concerns —
/// the `MapController`, the sheet's drag mechanics — stay in the View
/// (`HomeScreen`) and react to this state rather than living here.

@ProviderFor(HomeViewModel)
final homeViewModelProvider = HomeViewModelFamily._();

/// The home screen's view model, scoped to one ride.
///
/// Resolves the device's own location, merges it with
/// [ridersForRideProvider]'s live riders, and holds the screen's
/// interaction state (following/sheet-expanded). Widget-level concerns —
/// the `MapController`, the sheet's drag mechanics — stay in the View
/// (`HomeScreen`) and react to this state rather than living here.
final class HomeViewModelProvider
    extends $AsyncNotifierProvider<HomeViewModel, HomeState> {
  /// The home screen's view model, scoped to one ride.
  ///
  /// Resolves the device's own location, merges it with
  /// [ridersForRideProvider]'s live riders, and holds the screen's
  /// interaction state (following/sheet-expanded). Widget-level concerns —
  /// the `MapController`, the sheet's drag mechanics — stay in the View
  /// (`HomeScreen`) and react to this state rather than living here.
  HomeViewModelProvider._({
    required HomeViewModelFamily super.from,
    required String super.argument,
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

String _$homeViewModelHash() => r'884eaa4f09ef09667f4a86cf6a0e2795f5eb1698';

/// The home screen's view model, scoped to one ride.
///
/// Resolves the device's own location, merges it with
/// [ridersForRideProvider]'s live riders, and holds the screen's
/// interaction state (following/sheet-expanded). Widget-level concerns —
/// the `MapController`, the sheet's drag mechanics — stay in the View
/// (`HomeScreen`) and react to this state rather than living here.

final class HomeViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          HomeViewModel,
          AsyncValue<HomeState>,
          HomeState,
          FutureOr<HomeState>,
          String
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
  /// interaction state (following/sheet-expanded). Widget-level concerns —
  /// the `MapController`, the sheet's drag mechanics — stay in the View
  /// (`HomeScreen`) and react to this state rather than living here.

  HomeViewModelProvider call(String rideId) =>
      HomeViewModelProvider._(argument: rideId, from: this);

  @override
  String toString() => r'homeViewModelProvider';
}

/// The home screen's view model, scoped to one ride.
///
/// Resolves the device's own location, merges it with
/// [ridersForRideProvider]'s live riders, and holds the screen's
/// interaction state (following/sheet-expanded). Widget-level concerns —
/// the `MapController`, the sheet's drag mechanics — stay in the View
/// (`HomeScreen`) and react to this state rather than living here.

abstract class _$HomeViewModel extends $AsyncNotifier<HomeState> {
  late final _$args = ref.$arg as String;
  String get rideId => _$args;

  FutureOr<HomeState> build(String rideId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<HomeState>, HomeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<HomeState>, HomeState>,
              AsyncValue<HomeState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

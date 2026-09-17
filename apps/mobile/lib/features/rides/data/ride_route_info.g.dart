// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_route_info.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The rider's own real-road distance/duration to [ride]'s destination —
/// the same [RoutesRepository] call `HomeViewModel` already makes for an
/// active ride's own ETA, reused here for `RideDetailScreen`'s upcoming-
/// ride preview. Null if there's no destination to route to, or if the
/// device's position isn't available (permission denied, location
/// services off) — never fatal to the rest of the screen, which stands
/// on its own without this.

@ProviderFor(rideRouteInfo)
final rideRouteInfoProvider = RideRouteInfoFamily._();

/// The rider's own real-road distance/duration to [ride]'s destination —
/// the same [RoutesRepository] call `HomeViewModel` already makes for an
/// active ride's own ETA, reused here for `RideDetailScreen`'s upcoming-
/// ride preview. Null if there's no destination to route to, or if the
/// device's position isn't available (permission denied, location
/// services off) — never fatal to the rest of the screen, which stands
/// on its own without this.

final class RideRouteInfoProvider
    extends
        $FunctionalProvider<
          AsyncValue<RouteInfo?>,
          RouteInfo?,
          FutureOr<RouteInfo?>
        >
    with $FutureModifier<RouteInfo?>, $FutureProvider<RouteInfo?> {
  /// The rider's own real-road distance/duration to [ride]'s destination —
  /// the same [RoutesRepository] call `HomeViewModel` already makes for an
  /// active ride's own ETA, reused here for `RideDetailScreen`'s upcoming-
  /// ride preview. Null if there's no destination to route to, or if the
  /// device's position isn't available (permission denied, location
  /// services off) — never fatal to the rest of the screen, which stands
  /// on its own without this.
  RideRouteInfoProvider._({
    required RideRouteInfoFamily super.from,
    required Ride super.argument,
  }) : super(
         retry: null,
         name: r'rideRouteInfoProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$rideRouteInfoHash();

  @override
  String toString() {
    return r'rideRouteInfoProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<RouteInfo?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<RouteInfo?> create(Ref ref) {
    final argument = this.argument as Ride;
    return rideRouteInfo(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RideRouteInfoProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$rideRouteInfoHash() => r'a847cbaa7426511a30d324b551d3d402d82fbce0';

/// The rider's own real-road distance/duration to [ride]'s destination —
/// the same [RoutesRepository] call `HomeViewModel` already makes for an
/// active ride's own ETA, reused here for `RideDetailScreen`'s upcoming-
/// ride preview. Null if there's no destination to route to, or if the
/// device's position isn't available (permission denied, location
/// services off) — never fatal to the rest of the screen, which stands
/// on its own without this.

final class RideRouteInfoFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<RouteInfo?>, Ride> {
  RideRouteInfoFamily._()
    : super(
        retry: null,
        name: r'rideRouteInfoProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The rider's own real-road distance/duration to [ride]'s destination —
  /// the same [RoutesRepository] call `HomeViewModel` already makes for an
  /// active ride's own ETA, reused here for `RideDetailScreen`'s upcoming-
  /// ride preview. Null if there's no destination to route to, or if the
  /// device's position isn't available (permission denied, location
  /// services off) — never fatal to the rest of the screen, which stands
  /// on its own without this.

  RideRouteInfoProvider call(Ride ride) =>
      RideRouteInfoProvider._(argument: ride, from: this);

  @override
  String toString() => r'rideRouteInfoProvider';
}

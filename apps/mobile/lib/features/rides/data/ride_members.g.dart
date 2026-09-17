// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_members.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A ride's member list — just the static profile info ([RiderProfile]),
/// no live position tracking combined in the way `ridersForRideProvider`
/// does for an active ride. Used by `RideDetailScreen`, where there's
/// nothing live left to show once a ride has ended (and, for an upcoming
/// one, nothing live to show yet).

@ProviderFor(rideMembers)
final rideMembersProvider = RideMembersFamily._();

/// A ride's member list — just the static profile info ([RiderProfile]),
/// no live position tracking combined in the way `ridersForRideProvider`
/// does for an active ride. Used by `RideDetailScreen`, where there's
/// nothing live left to show once a ride has ended (and, for an upcoming
/// one, nothing live to show yet).

final class RideMembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RiderProfile>>,
          List<RiderProfile>,
          Stream<List<RiderProfile>>
        >
    with
        $FutureModifier<List<RiderProfile>>,
        $StreamProvider<List<RiderProfile>> {
  /// A ride's member list — just the static profile info ([RiderProfile]),
  /// no live position tracking combined in the way `ridersForRideProvider`
  /// does for an active ride. Used by `RideDetailScreen`, where there's
  /// nothing live left to show once a ride has ended (and, for an upcoming
  /// one, nothing live to show yet).
  RideMembersProvider._({
    required RideMembersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'rideMembersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$rideMembersHash();

  @override
  String toString() {
    return r'rideMembersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<RiderProfile>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<RiderProfile>> create(Ref ref) {
    final argument = this.argument as String;
    return rideMembers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RideMembersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$rideMembersHash() => r'ba40a61c73484ee3dc8d9fa6f29176874d895351';

/// A ride's member list — just the static profile info ([RiderProfile]),
/// no live position tracking combined in the way `ridersForRideProvider`
/// does for an active ride. Used by `RideDetailScreen`, where there's
/// nothing live left to show once a ride has ended (and, for an upcoming
/// one, nothing live to show yet).

final class RideMembersFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<RiderProfile>>, String> {
  RideMembersFamily._()
    : super(
        retry: null,
        name: r'rideMembersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A ride's member list — just the static profile info ([RiderProfile]),
  /// no live position tracking combined in the way `ridersForRideProvider`
  /// does for an active ride. Used by `RideDetailScreen`, where there's
  /// nothing live left to show once a ride has ended (and, for an upcoming
  /// one, nothing live to show yet).

  RideMembersProvider call(String rideId) =>
      RideMembersProvider._(argument: rideId, from: this);

  @override
  String toString() => r'rideMembersProvider';
}

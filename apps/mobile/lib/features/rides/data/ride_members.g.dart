// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_members.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A ride's member list — just the static profile info ([RiderProfile]),
/// no live position tracking combined in the way `ridersForRideProvider`
/// does for an active ride. Used by [PastRideDetailScreen], where there's
/// nothing live left to show once a ride has ended.

@ProviderFor(rideMembers)
final rideMembersProvider = RideMembersFamily._();

/// A ride's member list — just the static profile info ([RiderProfile]),
/// no live position tracking combined in the way `ridersForRideProvider`
/// does for an active ride. Used by [PastRideDetailScreen], where there's
/// nothing live left to show once a ride has ended.

final class RideMembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RiderProfile>>,
          List<RiderProfile>,
          Stream<List<RiderProfile>>
        >
    with $FutureModifier<List<RiderProfile>>, $StreamProvider<List<RiderProfile>> {
  /// A ride's member list — just the static profile info ([RiderProfile]),
  /// no live position tracking combined in the way `ridersForRideProvider`
  /// does for an active ride. Used by [PastRideDetailScreen], where there's
  /// nothing live left to show once a ride has ended.
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

String _$rideMembersHash() => r'2f8b4e6a9c1d3f507b2e8a4c6d1f9e3b5a7c0d2e';

/// A ride's member list — just the static profile info ([RiderProfile]),
/// no live position tracking combined in the way `ridersForRideProvider`
/// does for an active ride. Used by [PastRideDetailScreen], where there's
/// nothing live left to show once a ride has ended.

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
  /// does for an active ride. Used by [PastRideDetailScreen], where there's
  /// nothing live left to show once a ride has ended.

  RideMembersProvider call(String rideId) =>
      RideMembersProvider._(argument: rideId, from: this);

  @override
  String toString() => r'rideMembersProvider';
}

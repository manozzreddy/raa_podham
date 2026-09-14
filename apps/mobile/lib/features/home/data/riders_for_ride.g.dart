// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'riders_for_ride.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The ride's riders, ready to render: [PositionRepository]'s live
/// locations merged with [MembershipRepository]'s profiles.

@ProviderFor(ridersForRide)
final ridersForRideProvider = RidersForRideFamily._();

/// The ride's riders, ready to render: [PositionRepository]'s live
/// locations merged with [MembershipRepository]'s profiles.

final class RidersForRideProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Rider>>,
          List<Rider>,
          Stream<List<Rider>>
        >
    with $FutureModifier<List<Rider>>, $StreamProvider<List<Rider>> {
  /// The ride's riders, ready to render: [PositionRepository]'s live
  /// locations merged with [MembershipRepository]'s profiles.
  RidersForRideProvider._({
    required RidersForRideFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'ridersForRideProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ridersForRideHash();

  @override
  String toString() {
    return r'ridersForRideProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Rider>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Rider>> create(Ref ref) {
    final argument = this.argument as String;
    return ridersForRide(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RidersForRideProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ridersForRideHash() => r'753d95ec69a505e2ded1227eceb45260f5c818fe';

/// The ride's riders, ready to render: [PositionRepository]'s live
/// locations merged with [MembershipRepository]'s profiles.

final class RidersForRideFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Rider>>, String> {
  RidersForRideFamily._()
    : super(
        retry: null,
        name: r'ridersForRideProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The ride's riders, ready to render: [PositionRepository]'s live
  /// locations merged with [MembershipRepository]'s profiles.

  RidersForRideProvider call(String rideId) =>
      RidersForRideProvider._(argument: rideId, from: this);

  @override
  String toString() => r'ridersForRideProvider';
}

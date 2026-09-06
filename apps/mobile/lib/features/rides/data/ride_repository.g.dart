// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(rideRepository)
final rideRepositoryProvider = RideRepositoryProvider._();

final class RideRepositoryProvider
    extends $FunctionalProvider<RideRepository, RideRepository, RideRepository>
    with $Provider<RideRepository> {
  RideRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rideRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rideRepositoryHash();

  @$internal
  @override
  $ProviderElement<RideRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RideRepository create(Ref ref) {
    return rideRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RideRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RideRepository>(value),
    );
  }
}

String _$rideRepositoryHash() => r'c600de9d47dea4a33cf1ca4fddeb3722d211b039';

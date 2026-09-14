// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(routesRepository)
final routesRepositoryProvider = RoutesRepositoryProvider._();

final class RoutesRepositoryProvider
    extends
        $FunctionalProvider<
          RoutesRepository,
          RoutesRepository,
          RoutesRepository
        >
    with $Provider<RoutesRepository> {
  RoutesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routesRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routesRepositoryHash();

  @$internal
  @override
  $ProviderElement<RoutesRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RoutesRepository create(Ref ref) {
    return routesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RoutesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RoutesRepository>(value),
    );
  }
}

String _$routesRepositoryHash() => r'53255688678e2dc7125be73087f801773867e158';

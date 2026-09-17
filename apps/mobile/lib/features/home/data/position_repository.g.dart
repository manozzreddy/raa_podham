// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(positionRepository)
final positionRepositoryProvider = PositionRepositoryProvider._();

final class PositionRepositoryProvider
    extends
        $FunctionalProvider<
          PositionRepository,
          PositionRepository,
          PositionRepository
        >
    with $Provider<PositionRepository> {
  PositionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'positionRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$positionRepositoryHash();

  @$internal
  @override
  $ProviderElement<PositionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PositionRepository create(Ref ref) {
    return positionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PositionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PositionRepository>(value),
    );
  }
}

String _$positionRepositoryHash() =>
    r'1844d8387feab18031c130e5b5bcc30062e3edeb';

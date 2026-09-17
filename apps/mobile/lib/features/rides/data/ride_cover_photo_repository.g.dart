// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_cover_photo_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(rideCoverPhotoRepository)
final rideCoverPhotoRepositoryProvider = RideCoverPhotoRepositoryProvider._();

final class RideCoverPhotoRepositoryProvider
    extends
        $FunctionalProvider<
          RideCoverPhotoRepository,
          RideCoverPhotoRepository,
          RideCoverPhotoRepository
        >
    with $Provider<RideCoverPhotoRepository> {
  RideCoverPhotoRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rideCoverPhotoRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rideCoverPhotoRepositoryHash();

  @$internal
  @override
  $ProviderElement<RideCoverPhotoRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RideCoverPhotoRepository create(Ref ref) {
    return rideCoverPhotoRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RideCoverPhotoRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RideCoverPhotoRepository>(value),
    );
  }
}

String _$rideCoverPhotoRepositoryHash() =>
    r'0bb3e73f31e5c8502ee085614482a9080c811c82';

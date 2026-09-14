// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(themeModeRepository)
final themeModeRepositoryProvider = ThemeModeRepositoryProvider._();

final class ThemeModeRepositoryProvider
    extends
        $FunctionalProvider<
          ThemeModeRepository,
          ThemeModeRepository,
          ThemeModeRepository
        >
    with $Provider<ThemeModeRepository> {
  ThemeModeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeRepositoryHash();

  @$internal
  @override
  $ProviderElement<ThemeModeRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ThemeModeRepository create(Ref ref) {
    return themeModeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeModeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeModeRepository>(value),
    );
  }
}

String _$themeModeRepositoryHash() =>
    r'a5503490a2201ba0b863ef430d4205c900c07f0e';

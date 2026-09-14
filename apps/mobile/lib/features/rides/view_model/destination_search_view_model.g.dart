// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'destination_search_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Backs the dedicated destination-search screen — scoped to just that
/// screen's lifetime, separate from [CreateRideViewModel], since search
/// state (query/suggestions/isSearching/isResolving) has nothing to do
/// with the ride-creation form underneath it once a destination is
/// actually picked and this screen is popped.

@ProviderFor(DestinationSearchViewModel)
final destinationSearchViewModelProvider =
    DestinationSearchViewModelProvider._();

/// Backs the dedicated destination-search screen — scoped to just that
/// screen's lifetime, separate from [CreateRideViewModel], since search
/// state (query/suggestions/isSearching/isResolving) has nothing to do
/// with the ride-creation form underneath it once a destination is
/// actually picked and this screen is popped.
final class DestinationSearchViewModelProvider
    extends
        $NotifierProvider<
          DestinationSearchViewModel,
          DestinationSearchUiState
        > {
  /// Backs the dedicated destination-search screen — scoped to just that
  /// screen's lifetime, separate from [CreateRideViewModel], since search
  /// state (query/suggestions/isSearching/isResolving) has nothing to do
  /// with the ride-creation form underneath it once a destination is
  /// actually picked and this screen is popped.
  DestinationSearchViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'destinationSearchViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$destinationSearchViewModelHash();

  @$internal
  @override
  DestinationSearchViewModel create() => DestinationSearchViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DestinationSearchUiState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DestinationSearchUiState>(value),
    );
  }
}

String _$destinationSearchViewModelHash() =>
    r'd512be64ea321f0acf65c54a5458c29467bd0a22';

/// Backs the dedicated destination-search screen — scoped to just that
/// screen's lifetime, separate from [CreateRideViewModel], since search
/// state (query/suggestions/isSearching/isResolving) has nothing to do
/// with the ride-creation form underneath it once a destination is
/// actually picked and this screen is popped.

abstract class _$DestinationSearchViewModel
    extends $Notifier<DestinationSearchUiState> {
  DestinationSearchUiState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<DestinationSearchUiState, DestinationSearchUiState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DestinationSearchUiState, DestinationSearchUiState>,
              DestinationSearchUiState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

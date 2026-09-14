// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_ride_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CreateRideViewModel)
final createRideViewModelProvider = CreateRideViewModelProvider._();

final class CreateRideViewModelProvider
    extends $NotifierProvider<CreateRideViewModel, CreateRideUiState> {
  CreateRideViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createRideViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createRideViewModelHash();

  @$internal
  @override
  CreateRideViewModel create() => CreateRideViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateRideUiState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateRideUiState>(value),
    );
  }
}

String _$createRideViewModelHash() =>
    r'7ab7dd5ccb891c0783901c28a9adb76cf137371d';

abstract class _$CreateRideViewModel extends $Notifier<CreateRideUiState> {
  CreateRideUiState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CreateRideUiState, CreateRideUiState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CreateRideUiState, CreateRideUiState>,
              CreateRideUiState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

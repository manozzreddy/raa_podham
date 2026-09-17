// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_ride_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CreateRideViewModel)
final createRideViewModelProvider = CreateRideViewModelFamily._();

final class CreateRideViewModelProvider
    extends $NotifierProvider<CreateRideViewModel, CreateRideUiState> {
  CreateRideViewModelProvider._({
    required CreateRideViewModelFamily super.from,
    required Ride? super.argument,
  }) : super(
         retry: null,
         name: r'createRideViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$createRideViewModelHash();

  @override
  String toString() {
    return r'createRideViewModelProvider'
        ''
        '($argument)';
  }

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

  @override
  bool operator ==(Object other) {
    return other is CreateRideViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$createRideViewModelHash() =>
    r'fe9b3c3cf1994a4d10259dde123765f098df75df';

final class CreateRideViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          CreateRideViewModel,
          CreateRideUiState,
          CreateRideUiState,
          CreateRideUiState,
          Ride?
        > {
  CreateRideViewModelFamily._()
    : super(
        retry: null,
        name: r'createRideViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CreateRideViewModelProvider call(Ride? existingRide) =>
      CreateRideViewModelProvider._(argument: existingRide, from: this);

  @override
  String toString() => r'createRideViewModelProvider';
}

abstract class _$CreateRideViewModel extends $Notifier<CreateRideUiState> {
  late final _$args = ref.$arg as Ride?;
  Ride? get existingRide => _$args;

  CreateRideUiState build(Ride? existingRide);
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
    return element.handleCreate(ref, () => build(_$args));
  }
}

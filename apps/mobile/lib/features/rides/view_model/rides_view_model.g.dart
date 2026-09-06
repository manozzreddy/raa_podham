// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rides_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The signed-in user's rides.

@ProviderFor(RidesViewModel)
final ridesViewModelProvider = RidesViewModelProvider._();

/// The signed-in user's rides.
final class RidesViewModelProvider
    extends $AsyncNotifierProvider<RidesViewModel, List<Ride>> {
  /// The signed-in user's rides.
  RidesViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ridesViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ridesViewModelHash();

  @$internal
  @override
  RidesViewModel create() => RidesViewModel();
}

String _$ridesViewModelHash() => r'73ef5f31577b35346265f6283e377d95bf03b8ee';

/// The signed-in user's rides.

abstract class _$RidesViewModel extends $AsyncNotifier<List<Ride>> {
  FutureOr<List<Ride>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Ride>>, List<Ride>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Ride>>, List<Ride>>,
              AsyncValue<List<Ride>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The create-ride form's submit action.
///
/// Kept separate from [RidesViewModel] so the list's loading/error state
/// and the form's submit loading/error state don't share one [AsyncValue].

@ProviderFor(CreateRideViewModel)
final createRideViewModelProvider = CreateRideViewModelProvider._();

/// The create-ride form's submit action.
///
/// Kept separate from [RidesViewModel] so the list's loading/error state
/// and the form's submit loading/error state don't share one [AsyncValue].
final class CreateRideViewModelProvider
    extends $AsyncNotifierProvider<CreateRideViewModel, Ride?> {
  /// The create-ride form's submit action.
  ///
  /// Kept separate from [RidesViewModel] so the list's loading/error state
  /// and the form's submit loading/error state don't share one [AsyncValue].
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
}

String _$createRideViewModelHash() =>
    r'eafc71317c523886a39f469ef0e80754a5ede752';

/// The create-ride form's submit action.
///
/// Kept separate from [RidesViewModel] so the list's loading/error state
/// and the form's submit loading/error state don't share one [AsyncValue].

abstract class _$CreateRideViewModel extends $AsyncNotifier<Ride?> {
  FutureOr<Ride?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Ride?>, Ride?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Ride?>, Ride?>,
              AsyncValue<Ride?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The join-ride form's submit action. Same reasoning as
/// [CreateRideViewModel] — its own [AsyncValue], separate from the list.

@ProviderFor(JoinRideViewModel)
final joinRideViewModelProvider = JoinRideViewModelProvider._();

/// The join-ride form's submit action. Same reasoning as
/// [CreateRideViewModel] — its own [AsyncValue], separate from the list.
final class JoinRideViewModelProvider
    extends $AsyncNotifierProvider<JoinRideViewModel, Ride?> {
  /// The join-ride form's submit action. Same reasoning as
  /// [CreateRideViewModel] — its own [AsyncValue], separate from the list.
  JoinRideViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'joinRideViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$joinRideViewModelHash();

  @$internal
  @override
  JoinRideViewModel create() => JoinRideViewModel();
}

String _$joinRideViewModelHash() => r'da77d07b123b147f03bbaca3102a6e0e6fd393e9';

/// The join-ride form's submit action. Same reasoning as
/// [CreateRideViewModel] — its own [AsyncValue], separate from the list.

abstract class _$JoinRideViewModel extends $AsyncNotifier<Ride?> {
  FutureOr<Ride?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Ride?>, Ride?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Ride?>, Ride?>,
              AsyncValue<Ride?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

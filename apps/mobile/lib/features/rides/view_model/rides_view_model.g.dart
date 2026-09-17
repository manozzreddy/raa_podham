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

String _$ridesViewModelHash() => r'91e989f41523dce40794e9d255ac48d8f20f6d45';

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

/// The join-ride form's submit action. Its own [AsyncValue], separate
/// from [RidesViewModel]'s list — [CreateRideViewModel] (its own file,
/// `create_ride_view_model.dart`) is the create-ride equivalent, though
/// shaped differently since that form has more going on (destination
/// search) than a single submit action.

@ProviderFor(JoinRideViewModel)
final joinRideViewModelProvider = JoinRideViewModelProvider._();

/// The join-ride form's submit action. Its own [AsyncValue], separate
/// from [RidesViewModel]'s list — [CreateRideViewModel] (its own file,
/// `create_ride_view_model.dart`) is the create-ride equivalent, though
/// shaped differently since that form has more going on (destination
/// search) than a single submit action.
final class JoinRideViewModelProvider
    extends $AsyncNotifierProvider<JoinRideViewModel, Ride?> {
  /// The join-ride form's submit action. Its own [AsyncValue], separate
  /// from [RidesViewModel]'s list — [CreateRideViewModel] (its own file,
  /// `create_ride_view_model.dart`) is the create-ride equivalent, though
  /// shaped differently since that form has more going on (destination
  /// search) than a single submit action.
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

/// The join-ride form's submit action. Its own [AsyncValue], separate
/// from [RidesViewModel]'s list — [CreateRideViewModel] (its own file,
/// `create_ride_view_model.dart`) is the create-ride equivalent, though
/// shaped differently since that form has more going on (destination
/// search) than a single submit action.

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

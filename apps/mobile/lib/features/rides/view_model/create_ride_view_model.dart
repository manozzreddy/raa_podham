import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/geocoding_repository.dart';
import '../data/ride_repository.dart';
import '../models/ride.dart';

part 'create_ride_view_model.g.dart';

/// The new-ride form's state. Destination search itself lives in
/// [DestinationSearchViewModel] (the dedicated search screen's own
/// ViewModel) — this only holds the *result* of that, once picked.
class CreateRideUiState {
  const CreateRideUiState({
    this.name = '',
    this.selectedDestination,
    this.isCreating = false,
    this.error,
  });

  final String name;
  final DestinationSuggestion? selectedDestination;
  final bool isCreating;
  final String? error;

  CreateRideUiState copyWith({
    String? name,
    DestinationSuggestion? selectedDestination,
    bool? isCreating,
    String? error,
    bool clearError = false,
  }) {
    return CreateRideUiState(
      name: name ?? this.name,
      selectedDestination: selectedDestination ?? this.selectedDestination,
      isCreating: isCreating ?? this.isCreating,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

@riverpod
class CreateRideViewModel extends _$CreateRideViewModel {
  @override
  CreateRideUiState build() => const CreateRideUiState();

  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void selectDestination(DestinationSuggestion destination) {
    state = state.copyWith(selectedDestination: destination);
  }

  /// Returns the created [Ride] on success, or `null` with [state.error]
  /// set on failure (including the missing-destination case) — the
  /// screen reads that instead of a thrown exception, so it can show it
  /// in a SnackBar without a try/catch of its own.
  Future<Ride?> createRide() async {
    final destination = state.selectedDestination;
    if (destination == null) {
      state = state.copyWith(error: 'Choose a destination for the ride.');
      return null;
    }

    state = state.copyWith(isCreating: true, clearError: true);
    try {
      final ride = await ref
          .read(rideRepositoryProvider)
          .createRide(name: state.name.trim(), destination: destination);
      state = state.copyWith(isCreating: false);
      return ride;
    } catch (_) {
      state = state.copyWith(
        isCreating: false,
        error: 'Could not create the ride. Please try again.',
      );
      return null;
    }
  }
}

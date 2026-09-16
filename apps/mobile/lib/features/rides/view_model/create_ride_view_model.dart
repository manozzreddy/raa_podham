import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/geocoding_repository.dart';
import '../data/ride_cover_photo_repository.dart';
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
    this.notes = '',
    this.scheduledAt,
    this.coverPhotoUrl,
    this.isUploadingPhoto = false,
    this.isCreating = false,
    this.error,
  });

  final String name;
  final DestinationSuggestion? selectedDestination;
  final String notes;

  /// When the ride should start — null means "right away", the same
  /// behavior as before this field existed.
  final DateTime? scheduledAt;

  /// Set once [CreateRideViewModel.pickAndUploadCoverPhoto] finishes — the
  /// photo is already uploaded to Storage by the time this is non-null,
  /// so `createRide` never has its own upload step.
  final String? coverPhotoUrl;
  final bool isUploadingPhoto;
  final bool isCreating;
  final String? error;

  CreateRideUiState copyWith({
    String? name,
    DestinationSuggestion? selectedDestination,
    String? notes,
    DateTime? scheduledAt,
    String? coverPhotoUrl,
    bool? isUploadingPhoto,
    bool? isCreating,
    String? error,
    bool clearError = false,
    bool clearScheduledAt = false,
    bool clearCoverPhoto = false,
  }) {
    return CreateRideUiState(
      name: name ?? this.name,
      selectedDestination: selectedDestination ?? this.selectedDestination,
      notes: notes ?? this.notes,
      scheduledAt: clearScheduledAt ? null : (scheduledAt ?? this.scheduledAt),
      coverPhotoUrl: clearCoverPhoto ? null : (coverPhotoUrl ?? this.coverPhotoUrl),
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
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

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void setScheduledAt(DateTime? scheduledAt) {
    state = scheduledAt == null
        ? state.copyWith(clearScheduledAt: true)
        : state.copyWith(scheduledAt: scheduledAt);
  }

  /// Picks a photo from the gallery (never the camera — see
  /// `CreateRideScreen`'s own note on why) and uploads it immediately,
  /// rather than waiting for the ride to actually be submitted: a failed/
  /// retried submit would otherwise re-upload — and orphan — a fresh copy
  /// of the same file on every attempt.
  Future<void> pickAndUploadCoverPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    state = state.copyWith(isUploadingPhoto: true, clearError: true);
    try {
      final url = await ref
          .read(rideCoverPhotoRepositoryProvider)
          .uploadCoverPhoto(File(picked.path));
      // See requestPermission's own reasoning in LocationPermissionViewModel
      // — ref.mounted guards a `state=` after an async gap that could have
      // outlived this provider (e.g. navigating away mid-upload).
      if (!ref.mounted) return;
      state = state.copyWith(coverPhotoUrl: url, isUploadingPhoto: false);
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isUploadingPhoto: false,
        error: "Couldn't upload that photo. Please try again.",
      );
    }
  }

  Future<void> removeCoverPhoto() async {
    final url = state.coverPhotoUrl;
    state = state.copyWith(clearCoverPhoto: true);
    if (url != null) {
      await ref.read(rideCoverPhotoRepositoryProvider).deleteCoverPhoto(url);
    }
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
          .createRide(
            name: state.name.trim(),
            destination: destination,
            scheduledAt: state.scheduledAt,
            notes: state.notes.trim(),
            coverPhotoUrl: state.coverPhotoUrl,
          );
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

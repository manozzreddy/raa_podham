import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/geocoding_repository.dart';

part 'destination_search_view_model.g.dart';

/// How long to wait after the search field stops changing before
/// actually searching — keeps a fast typist from firing a request per
/// keystroke.
const _debounceDuration = Duration(milliseconds: 450);

class DestinationSearchUiState {
  const DestinationSearchUiState({
    this.query = '',
    this.suggestions = const [],
    this.isSearching = false,
    this.isResolving = false,
  });

  final String query;
  final List<DestinationPrediction> suggestions;
  final bool isSearching;

  /// True while a picked prediction's Place Details call is in flight —
  /// Autocomplete (New) doesn't return coordinates itself, so selecting a
  /// suggestion is a second round trip, not an instant pop.
  final bool isResolving;

  DestinationSearchUiState copyWith({
    String? query,
    List<DestinationPrediction>? suggestions,
    bool? isSearching,
    bool? isResolving,
  }) {
    return DestinationSearchUiState(
      query: query ?? this.query,
      suggestions: suggestions ?? this.suggestions,
      isSearching: isSearching ?? this.isSearching,
      isResolving: isResolving ?? this.isResolving,
    );
  }
}

/// Backs the dedicated destination-search screen — scoped to just that
/// screen's lifetime, separate from [CreateRideViewModel], since search
/// state (query/suggestions/isSearching/isResolving) has nothing to do
/// with the ride-creation form underneath it once a destination is
/// actually picked and this screen is popped.
@riverpod
class DestinationSearchViewModel extends _$DestinationSearchViewModel {
  Timer? _debounceTimer;

  @override
  DestinationSearchUiState build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return const DestinationSearchUiState();
  }

  void setQuery(String query) {
    if (query == state.query) return;

    _debounceTimer?.cancel();
    state = state.copyWith(query: query, suggestions: const []);

    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _debounceTimer = Timer(_debounceDuration, () => _search(query, trimmed));
  }

  Future<void> _search(String query, String trimmed) async {
    state = state.copyWith(isSearching: true);
    try {
      final results = await ref
          .read(geocodingRepositoryProvider)
          .autocomplete(trimmed);
      // The query kept changing while this request was in flight — a
      // newer search already superseded it, so this response is stale
      // and must not overwrite what's now on screen.
      if (state.query != query) return;
      state = state.copyWith(suggestions: results, isSearching: false);
    } catch (error) {
      if (state.query != query) return;
      state = state.copyWith(isSearching: false, suggestions: const []);
    }
  }

  /// Resolves a picked prediction to coordinates via Place Details.
  /// Returns `null` on failure so the screen can show that inline rather
  /// than popping with nothing to show for it.
  Future<DestinationSuggestion?> selectPrediction(
    DestinationPrediction prediction,
  ) async {
    state = state.copyWith(isResolving: true);
    try {
      final suggestion = await ref
          .read(geocodingRepositoryProvider)
          .resolvePlace(prediction);
      state = state.copyWith(isResolving: false);
      return suggestion;
    } catch (_) {
      state = state.copyWith(isResolving: false);
      return null;
    }
  }
}

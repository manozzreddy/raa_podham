// Unit tests for DestinationSearchViewModel's debounce/stale-response
// guarding and prediction resolution, against a fake GeocodingRepository
// whose responses this test controls directly (no debounce timing races,
// no real network).
//
// Uses testWidgets purely for its fake-clock support (a Timer created
// during a widget test only fires once the test advances time via
// tester.pump) — nothing here actually pumps a widget.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:raa_podham/features/rides/view_model/destination_search_view_model.dart';
import 'package:raa_podham/services/geocoding_repository.dart';

/// Returns a `Completer`-backed future per query, so the test controls
/// exactly when (and in what order) each search "resolves" — necessary
/// to simulate an earlier request's response arriving after a later one.
class _FakeGeocodingRepository implements GeocodingRepository {
  final List<String> queries = [];
  final Map<String, Completer<List<DestinationPrediction>>> _pending = {};

  /// Set before calling `selectPrediction` to control whether
  /// [resolvePlace] succeeds or throws.
  DestinationSuggestion? nextResolved;

  @override
  Future<List<DestinationPrediction>> autocomplete(
    String query, {
    LatLng? origin,
  }) {
    queries.add(query);
    final completer = Completer<List<DestinationPrediction>>();
    _pending[query] = completer;
    return completer.future;
  }

  void resolve(String query, List<DestinationPrediction> results) {
    _pending[query]!.complete(results);
  }

  @override
  Future<DestinationSuggestion> resolvePlace(
    DestinationPrediction prediction,
  ) async {
    final resolved = nextResolved;
    if (resolved == null) throw Exception('place details failed');
    return resolved;
  }
}

void main() {
  late _FakeGeocodingRepository fakeGeocoding;
  late ProviderContainer container;

  setUp(() {
    fakeGeocoding = _FakeGeocodingRepository();
    container = ProviderContainer(
      overrides: [geocodingRepositoryProvider.overrideWithValue(fakeGeocoding)],
    );
    // This provider is (correctly) autoDispose in production, scoped to
    // the search screen's lifetime — container.read() alone doesn't hold
    // a subscription, so without this listener Riverpod disposes the
    // notifier (cancelling its debounce Timer) almost immediately.
    container.listen(destinationSearchViewModelProvider, (previous, next) {});
  });

  tearDown(() => container.dispose());

  testWidgets('rapid query changes only trigger one search', (tester) async {
    final notifier = container.read(
      destinationSearchViewModelProvider.notifier,
    );

    notifier.setQuery('c');
    notifier.setQuery('cu');
    notifier.setQuery('cub');

    await tester.pump(const Duration(milliseconds: 450));

    expect(fakeGeocoding.queries, ['cub']);
  });

  testWidgets('an empty query does not search at all', (tester) async {
    final notifier = container.read(
      destinationSearchViewModelProvider.notifier,
    );

    notifier.setQuery('cub');
    notifier.setQuery('');

    await tester.pump(const Duration(milliseconds: 450));

    expect(fakeGeocoding.queries, isEmpty);
  });

  testWidgets('a stale response is dropped once the query has moved on', (
    tester,
  ) async {
    final notifier = container.read(
      destinationSearchViewModelProvider.notifier,
    );

    notifier.setQuery('first');
    await tester.pump(const Duration(milliseconds: 450));

    notifier.setQuery('second');
    await tester.pump(const Duration(milliseconds: 450));

    expect(fakeGeocoding.queries, ['first', 'second']);

    // 'second' resolves first, 'first' resolves after — out of order,
    // simulating a slow first request.
    fakeGeocoding.resolve('second', const [
      DestinationPrediction(
        placeId: 'place-second',
        displayName: 'Second Result',
        secondaryText: '',
      ),
    ]);
    await tester.pump();
    fakeGeocoding.resolve('first', const [
      DestinationPrediction(
        placeId: 'place-first',
        displayName: 'First Result',
        secondaryText: '',
      ),
    ]);
    await tester.pump();

    final state = container.read(destinationSearchViewModelProvider);
    expect(state.query, 'second');
    expect(state.suggestions, hasLength(1));
    expect(state.suggestions.single.displayName, 'Second Result');
  });

  test('selectPrediction resolves coordinates via Place Details', () async {
    final notifier = container.read(
      destinationSearchViewModelProvider.notifier,
    );
    fakeGeocoding.nextResolved = const DestinationSuggestion(
      displayName: 'Cubbon Park',
      secondaryText: 'Bengaluru, India',
      lat: 12.97,
      lng: 77.59,
    );

    final result = await notifier.selectPrediction(
      const DestinationPrediction(
        placeId: 'place-1',
        displayName: 'Cubbon Park',
        secondaryText: 'Bengaluru, India',
      ),
    );

    expect(result, fakeGeocoding.nextResolved);
    expect(
      container.read(destinationSearchViewModelProvider).isResolving,
      isFalse,
    );
  });

  test('selectPrediction returns null when Place Details fails', () async {
    final notifier = container.read(
      destinationSearchViewModelProvider.notifier,
    );
    fakeGeocoding.nextResolved = null;

    final result = await notifier.selectPrediction(
      const DestinationPrediction(
        placeId: 'place-1',
        displayName: 'Cubbon Park',
        secondaryText: 'Bengaluru, India',
      ),
    );

    expect(result, isNull);
    expect(
      container.read(destinationSearchViewModelProvider).isResolving,
      isFalse,
    );
  });
}

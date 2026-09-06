import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../theme/theme.dart';
import '../models/rider.dart';
import '../view_model/home_view_model.dart';
import '../widgets/map_fab_stack.dart';
import '../widgets/rider_sheet.dart';
import '../widgets/ride_search_bar.dart';

const double _sheetInitialSize = 0.28;
const double _sheetMinSize = 0.28;
const double _sheetMaxSize = 0.75;
const double _recenterZoom = 16;

/// The single home-screen design: a full-bleed map with a Google
/// Maps-style overlay UI — top search bar, right-edge FAB stack, and a
/// draggable rider sheet.
///
/// This is the View half of the screen's MVVM split: it owns only
/// widget-level concerns (the `MapController`, the sheet's drag
/// mechanics) and otherwise just renders [HomeViewModel]'s state and
/// forwards user actions to it.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.rideId, this.rideName = 'Sunday Sunrise Ride'});

  final String rideId;
  final String rideName;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = homeViewModelProvider(widget.rideId);
    final stateAsync = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);

    // The ViewModel decides *where* self location is; this View decides
    // *how* to animate the map camera there, since MapController is a
    // widget-level concern the ViewModel shouldn't need to know about.
    ref.listen<AsyncValue<HomeState>>(provider, (previous, next) {
      final previousState = previous?.value;
      final nextState = next.value;
      if (nextState == null) return;
      final locationChanged = previousState?.selfLocation != nextState.selfLocation;
      if (nextState.isFollowingUser && locationChanged) {
        _mapController.move(nextState.selfLocation, _recenterZoom);
      }
    });

    return stateAsync.when(
      loading: () => _LoadingScaffold(),
      error: (error, stackTrace) => _ErrorScaffold(error: error),
      data: (state) => _HomeContent(
        rideName: widget.rideName,
        state: state,
        mapController: _mapController,
        viewModel: viewModel,
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.rideName,
    required this.state,
    required this.mapController,
    required this.viewModel,
  });

  final String rideName;
  final HomeState state;
  final MapController mapController;
  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      children: [
        Positioned.fill(
          child: _RideMap(
            mapController: mapController,
            initialCenter: state.selfLocation,
            riders: state.riders,
            onUserGesture: viewModel.onMapPanned,
          ),
        ),
        Positioned(
          top: 0,
          left: 16,
          right: 16,
          child: SafeArea(
            bottom: false,
            child: RideSearchBar(rideName: rideName),
          ),
        ),
        Positioned(
          right: 16,
          bottom: MediaQuery.sizeOf(context).height * _sheetInitialSize + 16,
          child: MapFabStack(
            isFollowingUser: state.isFollowingUser,
            onRecenter: viewModel.recenter,
            onToggleMapStyle: viewModel.toggleMapStyle,
          ),
        ),
        NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            viewModel.onSheetExtentChanged(notification.extent);
            return false;
          },
          child: DraggableScrollableSheet(
            initialChildSize: _sheetInitialSize,
            minChildSize: _sheetMinSize,
            maxChildSize: _sheetMaxSize,
            snap: true,
            snapSizes: const [_sheetInitialSize, _sheetMaxSize],
            builder: (context, scrollController) => RiderSheet(
              rideName: rideName,
              riders: state.sortedByDistance,
              selfLocation: state.selfLocation,
              isExpanded: state.isSheetExpanded,
              scrollController: scrollController,
              onEndRide: () {
                viewModel.endRide();
                Navigator.of(context).maybePop();
              },
            ),
          ),
        ),
      ],
    );

    if (isCupertino) {
      return CupertinoPageScaffold(child: content);
    }
    return Scaffold(body: content);
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    final indicator = isCupertino ? const CupertinoActivityIndicator() : const CircularProgressIndicator();
    if (isCupertino) {
      return CupertinoPageScaffold(child: Center(child: indicator));
    }
    return Scaffold(body: Center(child: indicator));
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final content = Center(child: Text("Couldn't load this ride: $error"));
    if (isCupertino) {
      return CupertinoPageScaffold(child: content);
    }
    return Scaffold(body: content);
  }
}

/// The full-bleed OpenStreetMap raster map, with a marker per rider.
class _RideMap extends StatelessWidget {
  const _RideMap({
    required this.mapController,
    required this.initialCenter,
    required this.riders,
    required this.onUserGesture,
  });

  final MapController mapController;
  final LatLng initialCenter;
  final List<Rider> riders;
  final VoidCallback onUserGesture;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 15,
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture) onUserGesture();
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.dynamicarraytech.raa_podham',
        ),
        MarkerLayer(markers: riders.map(_buildMarker).toList(growable: false)),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }

  Marker _buildMarker(Rider rider) {
    final diameter = rider.isSelf ? 22.0 : 16.0;
    return Marker(
      point: rider.location,
      width: diameter,
      height: diameter,
      child: Container(
        decoration: BoxDecoration(
          color: rider.isSelf ? AppColors.sunriseAmber : AppColors.sunRimGold,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
      ),
    );
  }
}

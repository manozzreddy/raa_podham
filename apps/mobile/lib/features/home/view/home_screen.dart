import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../services/providers.dart';
import '../../../theme/theme.dart';
import '../../../widgets/app_error_screen.dart';
import '../../rides/models/ride.dart';
import '../../rides/view_model/rides_view_model.dart';
import '../data/riders_for_ride.dart';
import '../models/rider.dart';
import '../view_model/home_view_model.dart';
import '../view_model/no_active_ride_view_model.dart';
import '../widgets/app_drawer.dart';
import '../widgets/info_icon_button.dart';
import '../widgets/map_fab_stack.dart';
import '../widgets/map_top_icons.dart';
import '../widgets/no_ride_sheet.dart';
import '../widgets/rider_avatar_chip.dart';
import '../widgets/rider_info_sheet.dart';
import '../widgets/rider_sheet.dart';

const double _sheetInitialSize = 0.24;
const double _sheetMinSize = 0.24;
const double _recenterZoom = 16;
const double _autoFitPadding = 48;

/// Height reserved at the very top of the screen so a fully-dragged-up
/// sheet always stops just below [MapTopIcons] instead of covering it —
/// that widget's own button height (44) plus a small gap above the
/// sheet, the same way Google Maps' own bottom sheet always leaves its
/// top search bar visible no matter how far up it's dragged.
const double _topIconsReservedHeight = 44 + 16;

/// The largest fraction of the screen the sheet can occupy, computed
/// from the device's actual safe-area inset rather than a flat
/// percentage — so "drag all the way up" leaves exactly
/// [_topIconsReservedHeight] of clearance regardless of screen size or
/// notch, instead of an arbitrary gap that's too big on some devices and
/// too small on others.
double _maxSheetExtentFor(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final topGap = mediaQuery.padding.top + _topIconsReservedHeight;
  return 1 - topGap / mediaQuery.size.height;
}

/// The app's landing screen: a full-bleed map with a Google Maps-style
/// overlay UI, the way Google Maps itself opens straight to the map
/// rather than gating it behind picking something first.
///
/// Resolves whether the signed-in user currently has an active ride and
/// renders one of two states accordingly:
///  - no active ride: the map centered on the user, and a sheet listing
///    their past rides plus Create ride / Join ride actions.
///  - an active ride: the full rider-sheet experience (rider list,
///    invite, end/leave).
///
/// This is the View half of the screen's MVVM split: it owns only
/// widget-level concerns (the `MapController`, the sheet's drag
/// mechanics) and otherwise just renders the relevant ViewModel's state
/// and forwards user actions to it.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  late final ValueNotifier<double> _sheetExtent = ValueNotifier(
    _sheetInitialSize,
  );
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// The rideId the initial all-riders camera fit has already been applied
  /// for — re-arms whenever the active ride changes, so joining/creating
  /// another ride later gets its own initial fit too.
  String? _autoFitAppliedForRideId;

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(
      () => _sheetExtent.value = _sheetController.size,
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    _sheetController.dispose();
    _sheetExtent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ridesAsync = ref.watch(ridesViewModelProvider);

    return ridesAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (error, stackTrace) => AppErrorScreen(
        error: error,
        stackTrace: stackTrace,
        message: "Couldn't load your rides.",
        onRetry: () => ref.invalidate(ridesViewModelProvider),
      ),
      data: (rides) {
        final activeRide = _findActiveRide(rides);
        if (activeRide != null) return _buildActiveRideHome(activeRide);
        return _buildNoActiveRideHome();
      },
    );
  }

  Ride? _findActiveRide(List<Ride> rides) {
    for (final ride in rides) {
      if (ride.status == RideStatus.active) return ride;
    }
    return null;
  }

  Widget _buildActiveRideHome(Ride ride) {
    final provider = homeViewModelProvider(ride);
    final stateAsync = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);
    final maxSheetExtent = _maxSheetExtentFor(context);

    // The ViewModel decides *where* the camera should point (self
    // location, the initial all-riders fit); this View decides *how* to
    // animate the map camera there, since MapController is a
    // widget-level concern the ViewModel shouldn't need to know about.
    ref.listen<AsyncValue<HomeUiState>>(provider, (previous, next) {
      final nextState = next.value;
      if (nextState == null) return;
      _followSelfLocation(
        previous?.value?.selfLocation,
        nextState.selfLocation,
        nextState.isFollowingUser,
      );

      final bounds = nextState.autoFitBounds;
      if (bounds != null && _autoFitAppliedForRideId != nextState.rideId) {
        try {
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(_autoFitPadding),
            ),
          );
          // Only recorded on success: the destination (unlike riders,
          // which need a network round trip) is known the instant this
          // state first emits, which can race ahead of FlutterMap's own
          // first frame — same underlying cause as _followSelfLocation's
          // try/catch below. Leaving this unset on failure means the
          // very next state emission retries the fit instead of skipping
          // it for the rest of the ride.
          _autoFitAppliedForRideId = nextState.rideId;
        } on Exception {
          // See above — safe to drop, the next update retries it.
        }
      }
    });

    // Separate from the listener above: opening the Rider Info modal
    // needs a BuildContext for showModalBottomSheet, which the ViewModel
    // must never hold — so it only sets infoRiderUid, and this is what
    // actually reacts to that by presenting the modal.
    ref.listen<AsyncValue<HomeUiState>>(provider, (previous, next) {
      final infoRiderUid = next.value?.infoRiderUid;
      if (infoRiderUid != null &&
          previous?.value?.infoRiderUid != infoRiderUid) {
        unawaited(_showRiderInfoModal(context, viewModel, infoRiderUid));
      }
    });

    return stateAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (error, stackTrace) => AppErrorScreen(
        error: error,
        stackTrace: stackTrace,
        message: "Couldn't load this ride.",
        onRetry: () => ref.invalidate(provider),
      ),
      data: (state) => _MapHomeScaffold(
        map: _RideMap(
          mapController: _mapController,
          rideId: state.rideId,
          initialCenter: state.selfLocation,
          destination: state.destination,
          routePolyline: state.routePolyline,
          selectedRiderUid: state.selectedRiderUid,
          onSelectRider: viewModel.selectRider,
          onShowInfo: viewModel.showRiderInfo,
          onUserGesture: viewModel.onMapPanned,
        ),
        onProfileTap: () => context.push('/settings'),
        selfPhotoUrl: ref.watch(authStateProvider).value?.photoURL,
        scaffoldKey: _scaffoldKey,
        maxSheetExtent: maxSheetExtent,
        banner: state.isLocationUnavailable
            ? _LocationDisabledBanner(onTurnOnTap: viewModel.openLocationSettings)
            : null,
        fabStack: MapFabStack(
          isFollowingUser: state.isFollowingUser,
          onRecenter: viewModel.recenter,
        ),
        sheetController: _sheetController,
        sheetBuilder: (context, scrollController) => RiderSheet(
          rideName: state.rideName,
          destinationName: state.destination?.name,
          routeSummary: state.routeSummary,
          riders: state.riders,
          isHost: state.isHost,
          sheetExtent: _sheetExtent,
          sheetController: _sheetController,
          sheetMinExtent: _sheetMinSize,
          sheetMaxExtent: maxSheetExtent,
          scrollController: scrollController,
          onInviteMore: viewModel.inviteMore,
          onCta: () => _handleEndOrLeaveRide(viewModel, isHost: state.isHost),
          onRiderTap: (riderId) {
            viewModel.selectRider(riderId);
            _focusOnRider(viewModel, riderId);
          },
          onShowInfo: viewModel.showRiderInfo,
        ),
      ),
    );
  }

  Widget _buildNoActiveRideHome() {
    final stateAsync = ref.watch(noActiveRideViewModelProvider);
    final viewModel = ref.read(noActiveRideViewModelProvider.notifier);
    final maxSheetExtent = _maxSheetExtentFor(context);

    ref.listen<AsyncValue<NoActiveRideUiState>>(noActiveRideViewModelProvider, (
      previous,
      next,
    ) {
      final nextState = next.value;
      if (nextState == null) return;
      _followSelfLocation(
        previous?.value?.selfLocation,
        nextState.selfLocation,
        nextState.isFollowingUser,
      );
    });

    return stateAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (error, stackTrace) => AppErrorScreen(
        error: error,
        stackTrace: stackTrace,
        onRetry: () => ref.invalidate(noActiveRideViewModelProvider),
      ),
      data: (state) => _MapHomeScaffold(
        map: _SelfLocationMap(
          mapController: _mapController,
          selfLocation: state.selfLocation,
          onUserGesture: viewModel.onMapPanned,
        ),
        onProfileTap: () => context.push('/settings'),
        selfPhotoUrl: ref.watch(authStateProvider).value?.photoURL,
        scaffoldKey: _scaffoldKey,
        maxSheetExtent: maxSheetExtent,
        fabStack: MapFabStack(
          isFollowingUser: state.isFollowingUser,
          onRecenter: viewModel.recenter,
        ),
        sheetController: _sheetController,
        sheetBuilder: (context, scrollController) => NoRideSheet(
          sheetController: _sheetController,
          sheetMinExtent: _sheetMinSize,
          sheetMaxExtent: maxSheetExtent,
          // push, not go: these are sibling top-level routes, so `go`
          // would tear /home out of the stack entirely instead of
          // stacking on top of it — no back button, no swipe-back, no
          // way back if the user changes their mind mid-form.
          onCreateRide: () => context.push('/rides/create'),
          onJoinRide: () => context.push('/rides/join'),
        ),
      ),
    );
  }

  void _followSelfLocation(LatLng? previous, LatLng next, bool isFollowing) {
    if (!isFollowing || previous == next) return;
    try {
      _mapController.move(next, _recenterZoom);
    } on Exception {
      // flutter_map throws (rather than returning a nullable) if the
      // FlutterMap this controller is attached to hasn't completed its
      // first frame yet — a real race here, not a bug to fix upstream:
      // the location resolves and this listener can fire before that
      // widget's own initState has run (or, right after switching
      // between _RideMap/_SelfLocationMap, before the new one has).
      // Safe to drop: initialCenter already shows roughly the right
      // spot, and the next location update retries this.
    }
  }

  /// Recenters the map on a tapped rider's last known position, and
  /// stops auto-following self — otherwise the very next self-location
  /// update would yank the camera straight back, undoing the tap.
  void _focusOnRider(HomeViewModel viewModel, String riderId) {
    final location = viewModel.locationOf(riderId);
    if (location == null) return;
    viewModel.onMapPanned();
    _mapController.move(location, _recenterZoom);
  }

  /// Presents the Rider Info modal for [riderId] — triggered by
  /// HomeUiState.infoRiderUid becoming non-null, since showModalBottomSheet
  /// needs a BuildContext the ViewModel must never hold. Clears
  /// infoRiderUid once the sheet closes, however it closes (a button
  /// popping it, or the user just dragging/tapping it away), so state
  /// stays in sync either way.
  Future<void> _showRiderInfoModal(
    BuildContext context,
    HomeViewModel viewModel,
    String riderId,
  ) async {
    // Opened immediately with a loading state rather than awaited first —
    // riderInfoFor now makes real Routes API calls (see its own doc
    // comment for why that's fine here specifically), so there's a real
    // network round trip to cover instead of assuming it's instant.
    final future = viewModel.riderInfoFor(riderId);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RiderInfoModalContent(
        future: future,
        onDirections: () => viewModel.openDirections(riderId),
        onCenterMap: () => _focusOnRider(viewModel, riderId),
        onRemove: () => _handleRemoveRider(context, viewModel, riderId),
      ),
    );
    viewModel.dismissRiderInfo();
  }

  /// Removes [riderId] from the ride — [RiderInfoSheet] already pops
  /// itself before calling this, so `context` here is this screen's own
  /// (still mounted either way), not the sheet's about-to-be-gone one.
  Future<void> _handleRemoveRider(
    BuildContext context,
    HomeViewModel viewModel,
    String riderId,
  ) async {
    try {
      await viewModel.removeRider(riderId);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't remove that rider. Try again.")),
      );
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Rider removed from the ride')));
  }

  /// The rider sheet's role-aware CTA: ends the ride for everyone (host)
  /// or just leaves it (member). Once that succeeds, [ridesViewModelProvider]
  /// is invalidated so this screen re-resolves to the no-active-ride state
  /// on its own — no explicit navigation needed, unlike the sign-in/out
  /// flow which the router's redirect already drives the same way.
  Future<void> _handleEndOrLeaveRide(
    HomeViewModel viewModel, {
    required bool isHost,
  }) async {
    try {
      await viewModel.endOrLeaveRide();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isHost
                ? "Couldn't end the ride. Try again."
                : "Couldn't leave the ride. Try again.",
          ),
        ),
      );
      return;
    }
    ref.invalidate(ridesViewModelProvider);
  }
}

/// Wraps the Rider Info modal's real content in a loading state while
/// [future] (a real Routes API round trip, not instant) is pending.
class _RiderInfoModalContent extends StatelessWidget {
  const _RiderInfoModalContent({
    required this.future,
    required this.onDirections,
    required this.onCenterMap,
    required this.onRemove,
  });

  final Future<RiderInfoDetails?> future;
  final VoidCallback onDirections;
  final VoidCallback onCenterMap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RiderInfoDetails?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            height: 160,
            child: Center(
              child: isCupertino
                  ? const CupertinoActivityIndicator()
                  : const CircularProgressIndicator(),
            ),
          );
        }
        final details = snapshot.data;
        if (details == null) {
          return const SizedBox(
            height: 120,
            child: Center(child: Text("Couldn't load that rider's info.")),
          );
        }
        return RiderInfoSheet(
          details: details,
          onDirections: onDirections,
          onCenterMap: onCenterMap,
          onRemove: onRemove,
        );
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    final indicator = isCupertino
        ? const CupertinoActivityIndicator()
        : const CircularProgressIndicator();
    if (isCupertino) {
      return CupertinoPageScaffold(child: Center(child: indicator));
    }
    return Scaffold(body: Center(child: indicator));
  }
}

/// Shown when this device's own location can't be reported right now
/// (permission denied or the location-services toggle off) — otherwise
/// a rider just silently never shows up to the rest of the group, with
/// nothing telling them why (see HomeUiState.isLocationUnavailable).
class _LocationDisabledBanner extends StatelessWidget {
  const _LocationDisabledBanner({required this.onTurnOnTap});

  final VoidCallback onTurnOnTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.bodySmall;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.predawnIndigo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isCupertino ? CupertinoIcons.location_slash : Icons.location_off,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Your location is off. Others in this ride cannot see your location.",
              style: textStyle?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTurnOnTap,
            child: Text(
              'Turn on',
              style: textStyle?.copyWith(
                color: AppColors.sunRimGold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The shared shell for both home states: full-bleed map, floating menu
/// and profile icons up top, right-edge FAB stack, and a draggable sheet
/// — only [map], [fabStack] and the sheet's own content ever differ
/// between them.
class _MapHomeScaffold extends StatelessWidget {
  const _MapHomeScaffold({
    required this.map,
    required this.onProfileTap,
    this.selfPhotoUrl,
    required this.scaffoldKey,
    required this.fabStack,
    required this.sheetController,
    required this.maxSheetExtent,
    required this.sheetBuilder,
    this.banner,
  });

  final Widget map;
  final VoidCallback onProfileTap;
  final String? selfPhotoUrl;

  /// Shown just below [MapTopIcons], e.g. [_LocationDisabledBanner] —
  /// null (the common case) renders nothing extra.
  final Widget? banner;

  /// Only actually used on Material, to open [AppDrawer] via
  /// [ScaffoldState.openDrawer] — Cupertino opens the same content
  /// through [openCupertinoAppMenu] instead, which needs no key.
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Widget fabStack;
  final DraggableScrollableController sheetController;

  /// See [_maxSheetExtentFor] — how far up the sheet can be dragged.
  final double maxSheetExtent;
  final ScrollableWidgetBuilder sheetBuilder;

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      children: [
        Positioned.fill(child: map),
        Positioned(
          top: 0,
          left: 16,
          right: 16,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                MapTopIcons(
                  onProfileTap: onProfileTap,
                  selfPhotoUrl: selfPhotoUrl,
                  onMenuTap: isCupertino
                      ? () => openCupertinoAppMenu(context)
                      : () => scaffoldKey.currentState?.openDrawer(),
                ),
                if (banner != null) ...[
                  const SizedBox(height: 8),
                  banner!,
                ],
              ],
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: MediaQuery.sizeOf(context).height * _sheetInitialSize + 16,
          child: fabStack,
        ),
        DraggableScrollableSheet(
          controller: sheetController,
          initialChildSize: _sheetInitialSize,
          minChildSize: _sheetMinSize,
          maxChildSize: maxSheetExtent,
          snap: true,
          snapSizes: [_sheetInitialSize, maxSheetExtent],
          builder: sheetBuilder,
        ),
      ],
    );

    if (isCupertino) {
      return CupertinoPageScaffold(child: content);
    }
    return Scaffold(key: scaffoldKey, drawer: const AppDrawer(), body: content);
  }
}

/// The full-bleed OpenStreetMap raster map, with a marker per rider.
///
/// Watches [ridersForRideProvider] directly rather than going through
/// [HomeUiState.riders] — [RiderVm] is coordinate-free (it only carries
/// what the rider sheet needs), so marker positions come straight from
/// the shared riders stream instead.
class _RideMap extends ConsumerWidget {
  const _RideMap({
    required this.mapController,
    required this.rideId,
    required this.initialCenter,
    required this.destination,
    required this.routePolyline,
    required this.selectedRiderUid,
    required this.onSelectRider,
    required this.onShowInfo,
    required this.onUserGesture,
  });

  final MapController mapController;
  final String rideId;
  final LatLng initialCenter;
  final RideDestination? destination;

  /// Self-to-destination route, decoded and ready to draw — empty draws
  /// nothing (no destination set yet, or the route hasn't resolved).
  final List<LatLng> routePolyline;

  /// Whose name label is showing above their marker, if any — owned by
  /// HomeViewModel (not local widget state), so the sheet's collapsed
  /// chips and expanded rows can drive the same selection the map does.
  final String? selectedRiderUid;
  final ValueChanged<String?> onSelectRider;
  final ValueChanged<String> onShowInfo;
  final VoidCallback onUserGesture;

  static const double _riderDiameter = 40;
  static const double _selectedRiderDiameter = _riderDiameter * 1.22;
  static const double _destinationSize = 36;
  static const double _calloutHeight = 36;
  static const double _calloutGap = 6;
  static const double _calloutWidth = 180;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riders =
        ref.watch(ridersForRideProvider(rideId)).value ?? const <Rider>[];
    final destinationPin = destination;
    Rider? selectedRider;
    final unselectedRiders = <Rider>[];
    for (final rider in riders) {
      if (rider.riderId == selectedRiderUid) {
        selectedRider = rider;
      } else {
        unselectedRiders.add(rider);
      }
    }

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 15,
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture) onUserGesture();
        },
        // Tapping empty map space dismisses whichever label is open — a
        // marker's own onTap below fires first and re-selects if that's
        // what was actually tapped, so this only ever clears it.
        onTap: (_, _) => onSelectRider(null),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.dynamicarraytech.raa_podham',
        ),
        if (routePolyline.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePolyline,
                strokeWidth: 4,
                color: AppColors.predawnIndigo.withValues(alpha: 0.7),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (destinationPin != null) _buildDestinationMarker(destinationPin),
            // Unselected riders first, the selected one last — flutter_map
            // has no explicit z-index, paint order is list order, so
            // drawing the selected marker (and its label) last is what
            // raises it above anyone it'd otherwise overlap.
            ...unselectedRiders.map(
              (rider) => _buildMarker(rider, isSelected: false),
            ),
            if (selectedRider != null) ...[
              _buildMarker(selectedRider, isSelected: true),
              _buildCallout(selectedRider),
            ],
          ],
        ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }

  Marker _buildMarker(Rider rider, {required bool isSelected}) {
    final diameter = isSelected ? _selectedRiderDiameter : _riderDiameter;
    final avatar = RiderAvatarCircle(
      label: rider.displayName,
      photoUrl: rider.photoUrl,
      diameter: diameter,
      background: rider.isSelf
          ? AppColors.sunriseAmber
          : AppColors.riderFallbackColor(rider.riderId),
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
    );
    return Marker(
      point: rider.location,
      width: diameter,
      height: diameter,
      child: GestureDetector(
        onTap: () => onSelectRider(rider.riderId),
        child: avatar,
      ),
    );
  }

  /// The selected rider's name, anchored just above their (now enlarged)
  /// avatar — plus an info icon opening the Rider Info modal, self
  /// included (that modal adapts what it shows for yourself, see
  /// RiderInfoSheet). Self shows both their real name and "(You)", since
  /// self is the one rider who doesn't otherwise see their own name
  /// anywhere on the map.
  Marker _buildCallout(Rider rider) {
    final label = rider.isSelf ? '${rider.displayName} (You)' : rider.displayName;
    return Marker(
      point: rider.location,
      width: _calloutWidth,
      height: _calloutHeight + _calloutGap + _selectedRiderDiameter / 2,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: _calloutHeight,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.firstLightCream,
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.asphaltInk,
                    ),
                  ),
                ),
                InfoIconButton(
                  onTap: () => onShowInfo(rider.riderId),
                  size: 30,
                  iconSize: 18,
                ),
              ],
            ),
          ),
          SizedBox(height: _calloutGap + _selectedRiderDiameter / 2),
        ],
      ),
    );
  }

  /// A distinct pin (not an avatar) so the ride's destination never reads
  /// as just another rider dot — same pin shape as
  /// [DestinationSearchScreen]'s own place-row icon, in the classic
  /// map-pin red so it also can't be mistaken for any rider's avatar
  /// color (the rider palette and predawnIndigo, this pin's old color,
  /// happen to be the same value).
  Marker _buildDestinationMarker(RideDestination destination) {
    return Marker(
      point: LatLng(destination.lat, destination.lng),
      width: _destinationSize,
      height: _destinationSize,
      // Anchored so the pin's tip (bottom-center), not its visual center,
      // points at the actual coordinate — otherwise it looks like it's
      // floating above the ride's actual meeting point.
      alignment: Alignment.topCenter,
      child: Icon(
        isCupertino ? CupertinoIcons.location_solid : Icons.place,
        color: AppColors.roadFlareRed,
        size: _destinationSize,
        shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
      ),
    );
  }
}

/// The landing map for when there's no active ride: just the device's own
/// position, no ride to render riders for.
class _SelfLocationMap extends StatelessWidget {
  const _SelfLocationMap({
    required this.mapController,
    required this.selfLocation,
    required this.onUserGesture,
  });

  final MapController mapController;
  final LatLng selfLocation;
  final VoidCallback onUserGesture;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: selfLocation,
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
        MarkerLayer(markers: [_selfMarker()]),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }

  Marker _selfMarker() {
    return Marker(
      point: selfLocation,
      width: 22,
      height: 22,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.sunriseAmber,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
      ),
    );
  }
}

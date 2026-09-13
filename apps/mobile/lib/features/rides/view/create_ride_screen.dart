import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../services/geocoding_repository.dart';
import '../../../theme/theme.dart';
import '../view_model/create_ride_view_model.dart';
import '../view_model/rides_view_model.dart';
import 'destination_search_screen.dart';
import 'share_invite_screen.dart';

/// The new-ride form: a name and a required destination (picked via the
/// dedicated [DestinationSearchScreen], not typed inline), with a Create
/// button that hands off to [ShareInviteScreen] — not back to this
/// screen — once the ride exists.
class CreateRideScreen extends ConsumerStatefulWidget {
  const CreateRideScreen({super.key});

  @override
  ConsumerState<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends ConsumerState<CreateRideScreen> {
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createRideViewModelProvider);
    final notifier = ref.read(createRideViewModelProvider.notifier);

    ref.listen<CreateRideUiState>(createRideViewModelProvider, (
      previous,
      next,
    ) {
      final text = next.selectedDestination?.displayName ?? '';
      if (_destinationController.text != text) {
        _destinationController.text = text;
      }
    });

    Future<void> pickDestination() async {
      final result = await context.push<DestinationSuggestion>(
        '/rides/destination-search',
      );
      if (result != null) notifier.selectDestination(result);
    }

    Future<void> submit() async {
      final ride = await notifier.createRide();
      if (!context.mounted) return;
      if (ride == null) {
        final error = ref.read(createRideViewModelProvider).error;
        if (error != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error)));
        }
        return;
      }
      ref.invalidate(ridesViewModelProvider);
      context.push('/rides/share-invite', extra: ride);
    }

    final canSubmit =
        state.name.trim().isNotEmpty &&
        state.selectedDestination != null &&
        !state.isCreating;

    final nameField = isCupertino
        ? CupertinoTextField(
            controller: _nameController,
            placeholder: 'Sunday Sunrise Ride',
            onChanged: notifier.setName,
          )
        : TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Ride name',
              hintText: 'Sunday Sunrise Ride',
            ),
            onChanged: notifier.setName,
          );

    final destinationField = isCupertino
        ? CupertinoTextField(
            controller: _destinationController,
            placeholder: 'Search a destination',
            readOnly: true,
            showCursor: false,
            suffix: const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(CupertinoIcons.search, size: 18),
            ),
          )
        : TextField(
            controller: _destinationController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Destination',
              hintText: 'Search a destination',
              suffixIcon: Icon(Icons.search),
            ),
          );

    final submitButton = isCupertino
        ? CupertinoButton.filled(
            onPressed: canSubmit ? submit : null,
            child: state.isCreating
                ? const CupertinoActivityIndicator()
                : const Text('Create ride'),
          )
        : FilledButton(
            onPressed: canSubmit ? submit : null,
            child: state.isCreating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create ride'),
          );

    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        nameField,
        const SizedBox(height: 16),
        // AbsorbPointer keeps the field itself inert (no cursor, no
        // keyboard) while the GestureDetector around it turns the whole
        // thing into a button that opens the dedicated search screen.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: pickDestination,
          child: AbsorbPointer(child: destinationField),
        ),
        const _DestinationHint(),
        const SizedBox(height: 24),
        submitButton,
      ],
    );

    if (isCupertino) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('New ride'),
          leading: CupertinoNavigationBarBackButton(
            onPressed: () => context.pop(),
          ),
        ),
        child: SafeArea(child: content),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('New ride'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: content,
    );
  }
}

class _DestinationHint extends StatelessWidget {
  const _DestinationHint();

  @override
  Widget build(BuildContext context) {
    final style = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.bodySmall;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Shown as a pin for everyone on the map, not a route. Starts right away; '
        'scheduling a ride for later is coming soon.',
        style: style?.copyWith(color: style.color?.withValues(alpha: 0.7)),
      ),
    );
  }
}

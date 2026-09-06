import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/theme.dart';
import '../view_model/rides_view_model.dart';

/// The signed-in user's rides. Functional scaffolding, not yet designed
/// against the app's visual identity the way [HomeScreen] is.
class RidesListScreen extends ConsumerWidget {
  const RidesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridesAsync = ref.watch(ridesViewModelProvider);

    final body = ridesAsync.when(
      loading: () => Center(
        child: isCupertino ? const CupertinoActivityIndicator() : const CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(child: Text("Couldn't load rides: $error")),
      data: (rides) {
        if (rides.isEmpty) {
          return const Center(child: Text('No rides yet'));
        }
        return ListView.builder(
          itemCount: rides.length,
          itemBuilder: (context, index) {
            final ride = rides[index];
            return ListTile(
              title: Text(ride.name),
              subtitle: Text(ride.status.name),
              onTap: () => context.go('/rides/${ride.id}/home'),
            );
          },
        );
      },
    );

    final content = Column(
      children: [
        Expanded(child: body),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isCupertino) ...[
                CupertinoButton(onPressed: () => context.go('/rides/create'), child: const Text('Create ride')),
                CupertinoButton(onPressed: () => context.go('/rides/join'), child: const Text('Join ride')),
              ] else ...[
                TextButton(onPressed: () => context.go('/rides/create'), child: const Text('Create ride')),
                TextButton(onPressed: () => context.go('/rides/join'), child: const Text('Join ride')),
              ],
            ],
          ),
        ),
      ],
    );

    if (isCupertino) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('My rides')),
        child: SafeArea(child: content),
      );
    }

    return Scaffold(appBar: AppBar(title: const Text('My rides')), body: content);
  }
}

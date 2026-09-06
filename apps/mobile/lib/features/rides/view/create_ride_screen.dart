import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/theme.dart';
import '../models/ride.dart';
import '../view_model/rides_view_model.dart';

/// The create-ride form. Functional scaffolding, not yet designed against
/// the app's visual identity the way [HomeScreen] is.
class CreateRideScreen extends ConsumerStatefulWidget {
  const CreateRideScreen({super.key});

  @override
  ConsumerState<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends ConsumerState<CreateRideScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createRideViewModelProvider);

    ref.listen<AsyncValue<Ride?>>(createRideViewModelProvider, (previous, next) {
      final ride = next.value;
      if (ride != null) {
        context.go('/rides/${ride.id}/home');
      }
    });

    final isSubmitting = state.isLoading;
    final errorText = state.hasError ? 'Could not create the ride: ${state.error}' : null;

    final field = isCupertino
        ? CupertinoTextField(controller: _nameController, placeholder: 'Ride name')
        : TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Ride name'),
          );

    void submit() {
      final name = _nameController.text.trim();
      if (name.isEmpty) return;
      ref.read(createRideViewModelProvider.notifier).submit(name: name);
    }

    final submitButton = isCupertino
        ? CupertinoButton.filled(
            onPressed: isSubmitting ? null : submit,
            child: isSubmitting ? const CupertinoActivityIndicator() : const Text('Create ride'),
          )
        : FilledButton(
            onPressed: isSubmitting ? null : submit,
            child: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create ride'),
          );

    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field,
          if (errorText != null) ...[
            const SizedBox(height: 8),
            Text(errorText, style: const TextStyle(color: CupertinoColors.destructiveRed)),
          ],
          const SizedBox(height: 16),
          submitButton,
        ],
      ),
    );

    if (isCupertino) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('Create ride')),
        child: SafeArea(child: content),
      );
    }

    return Scaffold(appBar: AppBar(title: const Text('Create ride')), body: content);
  }
}

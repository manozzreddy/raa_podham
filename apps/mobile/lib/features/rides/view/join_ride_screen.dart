import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/theme.dart';
import '../models/ride.dart';
import '../view_model/rides_view_model.dart';

/// The join-ride form. Functional scaffolding, not yet designed against
/// the app's visual identity the way [HomeScreen] is.
class JoinRideScreen extends ConsumerStatefulWidget {
  const JoinRideScreen({super.key});

  @override
  ConsumerState<JoinRideScreen> createState() => _JoinRideScreenState();
}

class _JoinRideScreenState extends ConsumerState<JoinRideScreen> {
  final _inviteCodeController = TextEditingController();

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(joinRideViewModelProvider);

    ref.listen<AsyncValue<Ride?>>(joinRideViewModelProvider, (previous, next) {
      final ride = next.value;
      if (ride != null) {
        context.go('/rides/${ride.id}/home');
      }
    });

    final isSubmitting = state.isLoading;
    final errorText = state.hasError ? "Couldn't join that ride: ${state.error}" : null;

    final field = isCupertino
        ? CupertinoTextField(controller: _inviteCodeController, placeholder: 'Invite code')
        : TextField(
            controller: _inviteCodeController,
            decoration: const InputDecoration(labelText: 'Invite code'),
          );

    void submit() {
      final inviteCode = _inviteCodeController.text.trim();
      if (inviteCode.isEmpty) return;
      ref.read(joinRideViewModelProvider.notifier).submit(inviteCode: inviteCode);
    }

    final submitButton = isCupertino
        ? CupertinoButton.filled(
            onPressed: isSubmitting ? null : submit,
            child: isSubmitting ? const CupertinoActivityIndicator() : const Text('Join ride'),
          )
        : FilledButton(
            onPressed: isSubmitting ? null : submit,
            child: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Join ride'),
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
        navigationBar: const CupertinoNavigationBar(middle: Text('Join ride')),
        child: SafeArea(child: content),
      );
    }

    return Scaffold(appBar: AppBar(title: const Text('Join ride')), body: content);
  }
}

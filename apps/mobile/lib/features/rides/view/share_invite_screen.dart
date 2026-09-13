import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../theme/theme.dart';
import '../models/ride.dart';

/// Shown right after a ride is created — the only way for other riders
/// to find it is the invite code/link, so this is the one screen
/// dedicated to getting it in front of them before landing on the map.
///
/// A plain [StatelessWidget], not a `ConsumerWidget`: nothing here reads
/// Riverpod state (share/copy/navigate don't need a ViewModel), matching
/// `AboutScreen`'s own precedent of skipping Consumer* when there's
/// nothing to consume.
class ShareInviteScreen extends StatelessWidget {
  const ShareInviteScreen({super.key, required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final titleStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.navTitleTextStyle
              .copyWith(fontSize: 22)
        : Theme.of(context).textTheme.titleLarge;
    final bodyStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.bodyMedium;

    final content = SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  'assets/icons/app_mark.png',
                  width: 64,
                  height: 64,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '${ride.name} is live',
                textAlign: TextAlign.center,
                style: titleStyle,
              ),
              const SizedBox(height: 8),
              Text(
                "Share this so riders can find you. It's the only way in.",
                textAlign: TextAlign.center,
                style: bodyStyle?.copyWith(
                  color: bodyStyle.color?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              _InviteCodeChip(code: ride.inviteCode),
              const SizedBox(height: 32),
              _PrimaryButton(
                label: 'Share invite',
                onPressed: () => _shareInvite(),
              ),
              const SizedBox(height: 12),
              _SecondaryButton(
                label: 'Copy code',
                onPressed: () => _copyCode(context),
              ),
              const SizedBox(height: 12),
              _SkipButton(onPressed: () => _goHome(context)),
            ],
          ),
        ),
      ),
    );

    if (isCupertino) {
      return CupertinoPageScaffold(child: content);
    }
    return Scaffold(body: content);
  }

  Future<void> _shareInvite() {
    return SharePlus.instance.share(
      ShareParams(
        text: buildInviteMessage(ride),
        subject: 'Join my ride on Raa Podham',
      ),
    );
  }

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: ride.inviteCode));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Invite code copied')));
  }

  // `go`, not `push`: this screen (and CreateRideScreen under it) should
  // never be back-navigable to once you've landed on the ride — there's
  // nothing to come back and redo.
  void _goHome(BuildContext context) => context.go('/home');
}

class _InviteCodeChip extends StatelessWidget {
  const _InviteCodeChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final background = isCupertino
        ? CupertinoColors.systemGrey5
        : Theme.of(context).colorScheme.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        code,
        style: AppTextTheme.monospace(
          fontSize: 26,
          fontWeight: FontWeight.w700,
        ).copyWith(letterSpacing: 6),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isCupertino) {
      return SizedBox(
        width: double.infinity,
        child: CupertinoButton.filled(onPressed: onPressed, child: Text(label)),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: FilledButton(onPressed: onPressed, child: Text(label)),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isCupertino) {
      return SizedBox(
        width: double.infinity,
        child: CupertinoButton(onPressed: onPressed, child: Text(label)),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isCupertino) {
      return CupertinoButton(
        onPressed: onPressed,
        child: const Text('Skip for now'),
      );
    }
    return TextButton(onPressed: onPressed, child: const Text('Skip for now'));
  }
}

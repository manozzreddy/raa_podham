import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// One reason a permission is worth granting: a small icon chip plus a
/// line of copy. [PermissionRationaleScaffold] stacks these under its
/// headline so the case reads as short and concrete rather than one
/// dense paragraph.
class PermissionReason {
  const PermissionReason({
    required this.icon,
    required this.cupertinoIcon,
    required this.text,
  });

  final IconData icon;
  final IconData cupertinoIcon;
  final String text;
}

/// The shared shell behind every permission-rationale screen in the app
/// (`LocationPermissionScreen`, `BackgroundSharingPermissionScreen`):
/// badge, title, body copy, a short list of reasons, an optional warning
/// line, a primary button that shows a spinner while [onPrimaryPressed]
/// is pending, an optional "Not now" skip action, and a footer note.
///
/// Deliberately owns none of the *behavior* those two screens differ
/// on — whether skipping is even possible, what the button requests,
/// whether the screen re-shows on denial — only the visual shape they
/// share. Each screen stays its own widget, under its own name, so
/// their differing semantics (one blocks navigation and re-checks on
/// every route change, the other shows once per ride and is always
/// skippable) don't get blurred into one generic "permission screen".
class PermissionRationaleScaffold extends StatefulWidget {
  const PermissionRationaleScaffold({
    super.key,
    required this.badgeIcon,
    required this.badgeCupertinoIcon,
    required this.title,
    required this.body,
    required this.reasons,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    required this.footer,
    this.warning,
    this.onSkip,
  });

  final IconData badgeIcon;
  final IconData badgeCupertinoIcon;
  final String title;
  final String body;
  final List<PermissionReason> reasons;
  final String primaryLabel;

  /// Awaited with a busy spinner shown on the primary button meanwhile.
  final Future<void> Function() onPrimaryPressed;

  /// Shown in place of [body] size/spacing, above the primary button, in
  /// the destructive color — e.g. after a denial. Null (the common case)
  /// renders nothing extra.
  final String? warning;

  /// Shows a "Not now" text button below the primary button when given.
  /// Omitted entirely (null) for a mandatory screen with no skip path.
  final VoidCallback? onSkip;

  final String footer;

  @override
  State<PermissionRationaleScaffold> createState() =>
      _PermissionRationaleScaffoldState();
}

class _PermissionRationaleScaffoldState
    extends State<PermissionRationaleScaffold> {
  bool _isBusy = false;

  Future<void> _handlePrimaryTap() async {
    setState(() => _isBusy = true);
    try {
      await widget.onPrimaryPressed();
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  TextStyle? _titleStyle(BuildContext context) => isCupertino
      ? CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle
      : Theme.of(context).textTheme.headlineSmall;

  TextStyle? _bodyStyle(BuildContext context) => isCupertino
      ? CupertinoTheme.of(context).textTheme.textStyle
      : Theme.of(context).textTheme.bodyLarge;

  TextStyle? _captionStyle(BuildContext context) => isCupertino
      ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
      : Theme.of(context).textTheme.bodySmall;

  @override
  Widget build(BuildContext context) {
    final mutedColor = (_bodyStyle(context)?.color ?? AppColors.asphaltInk)
        .withValues(alpha: 0.72);
    final onSkip = widget.onSkip;

    final content = SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 3),
            Center(
              child: _Badge(icon: widget.badgeIcon, cupertinoIcon: widget.badgeCupertinoIcon),
            ),
            const SizedBox(height: 28),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: _titleStyle(context)?.copyWith(fontSize: 26),
            ),
            const SizedBox(height: 12),
            Text(
              widget.body,
              textAlign: TextAlign.center,
              style: _bodyStyle(context)?.copyWith(color: mutedColor),
            ),
            const SizedBox(height: 32),
            for (final reason in widget.reasons) ...[
              _ReasonRow(
                icon: reason.icon,
                cupertinoIcon: reason.cupertinoIcon,
                text: reason.text,
              ),
              const SizedBox(height: 16),
            ],
            const Spacer(flex: 4),
            if (widget.warning case final warning?) ...[
              Text(
                warning,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isCupertino
                      ? CupertinoColors.destructiveRed
                      : Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
            ],
            _PrimaryButton(
              label: widget.primaryLabel,
              isBusy: _isBusy,
              onPressed: _handlePrimaryTap,
            ),
            if (onSkip != null) ...[
              const SizedBox(height: 4),
              _SkipButton(onPressed: _isBusy ? null : onSkip),
            ],
            const SizedBox(height: 12),
            Text(
              widget.footer,
              textAlign: TextAlign.center,
              style: _captionStyle(context)?.copyWith(color: mutedColor),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    if (isCupertino) {
      return CupertinoPageScaffold(child: content);
    }
    return Scaffold(body: content);
  }
}

/// The large circular icon badge topping the screen — same rounded-badge
/// language as the sign-in screen's app mark, but a plain icon rather
/// than an image, since these screens have no logo to show.
class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.cupertinoIcon});

  final IconData icon;
  final IconData cupertinoIcon;

  static const double _size = 96;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: AppColors.sunriseAmber,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.sunriseAmber.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        isCupertino ? cupertinoIcon : icon,
        color: Colors.white,
        size: 46,
      ),
    );
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.icon,
    required this.cupertinoIcon,
    required this.text,
  });

  final IconData icon;
  final IconData cupertinoIcon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final textStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.textStyle
        : Theme.of(context).textTheme.bodyMedium;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.sunriseAmber.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCupertino ? cupertinoIcon : icon,
            color: AppColors.sunriseAmber,
            size: 18,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(text, style: textStyle?.copyWith(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.isBusy,
    required this.onPressed,
  });

  final String label;
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final child = isBusy
        ? SizedBox(
            width: 20,
            height: 20,
            child: isCupertino
                ? const CupertinoActivityIndicator(color: Colors.white)
                : const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
          )
        : Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          );

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: isCupertino
          ? CupertinoButton.filled(
              onPressed: isBusy ? null : onPressed,
              borderRadius: BorderRadius.circular(26),
              child: child,
            )
          : FilledButton(
              onPressed: isBusy ? null : onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.sunriseAmber,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: child,
            ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (isCupertino) {
      return CupertinoButton(onPressed: onPressed, child: const Text('Not now'));
    }
    return TextButton(onPressed: onPressed, child: const Text('Not now'));
  }
}

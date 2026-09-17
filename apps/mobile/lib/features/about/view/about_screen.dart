import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/theme.dart';
import '../../../widgets/made_with_love_footer.dart';
import '../../../widgets/sheet_drag_handle.dart';

/// Only Android has a `upi://` scheme any installed app will actually
/// answer to — there's no equivalent universal UPI intent on iOS/web, so
/// [_SupportSection] shows the UPI ID as copyable text everywhere but
/// only offers the one-tap "pay" shortcut here.
bool get _canOpenUpiApp =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// What Raa Podham is, and where its name comes from — reached from the
/// home screen's left-side menu.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            children: const [
              _AppMark(),
              SizedBox(height: 20),
              _NameSection(),
              SizedBox(height: 24),
              _DescriptionSection(),
              SizedBox(height: 28),
              _ContactSection(),
              SizedBox(height: 12),
              _SupportSection(),
            ],
          ),
        ),
        const MadeWithLoveFooter(),
      ],
    );

    if (isCupertino) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('About')),
        child: content,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: content,
    );
  }
}

class _AppMark extends StatelessWidget {
  const _AppMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset('assets/icons/app_mark.png', width: 72, height: 72),
      ),
    );
  }
}

/// The wordmark, its Telugu original, and the one-line translation that
/// gives the app its name.
class _NameSection extends StatelessWidget {
  const _NameSection();

  @override
  Widget build(BuildContext context) {
    final nameStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle
        : Theme.of(context).textTheme.headlineSmall;
    final teluguStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.navTitleTextStyle
        : Theme.of(context).textTheme.titleMedium;
    final meaningStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.bodyMedium;

    return Column(
      children: [
        Text('Raa Podham', textAlign: TextAlign.center, style: nameStyle),
        const SizedBox(height: 6),
        Text('రా పోదాం', textAlign: TextAlign.center, style: teluguStyle),
        const SizedBox(height: 6),
        Text(
          'Telugu for "Come on, let\'s go!"',
          textAlign: TextAlign.center,
          style: meaningStyle?.copyWith(
            fontStyle: FontStyle.italic,
            color: meaningStyle.color?.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection();

  @override
  Widget build(BuildContext context) {
    final bodyStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.textStyle
        : Theme.of(context).textTheme.bodyLarge;

    return Text(
      'Raa Podham is a free, live location overlay for group rides. '
      'Everyone in your group shows up on one shared map in real time, '
      'with no in-app navigation and no extra noise.',
      textAlign: TextAlign.center,
      style: bodyStyle?.copyWith(height: 1.4),
    );
  }
}

/// Opens the device's mail composer addressed at the maintainer, with a
/// fixed subject line — a single action, so it launches directly rather
/// than opening a sheet first (unlike [_SupportSection], which has an
/// actual choice to offer: pay vs. copy).
class _ContactSection extends StatelessWidget {
  const _ContactSection();

  static const String _contactEmail = 'manojreddygangarapu@gmail.com';

  @override
  Widget build(BuildContext context) {
    if (isCupertino) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _sendEmail(context),
        child: const _ContactLabel(),
      );
    }
    return TextButton(
      onPressed: () => _sendEmail(context),
      child: const _ContactLabel(),
    );
  }

  Future<void> _sendEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _contactEmail,
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open an email app. Try again.")),
      );
    }
  }
}

class _ContactLabel extends StatelessWidget {
  const _ContactLabel();

  @override
  Widget build(BuildContext context) {
    final style = isCupertino
        ? CupertinoTheme.of(context).textTheme.actionTextStyle
        : Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: AppColors.sunriseAmber);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isCupertino ? CupertinoIcons.mail : Icons.mail_outline,
          size: 18,
          color: AppColors.sunriseAmber,
        ),
        const SizedBox(width: 8),
        Text('Contact me', style: style),
      ],
    );
  }
}

/// A UPI ID as copyable plain text — not a payment flow the app takes
/// part in. No checkout, no card details, no gated feature: as safe for
/// app-store review as showing a contact email.
class _SupportSection extends StatelessWidget {
  const _SupportSection();

  static const String _upiId = 'manojreddygangarapu@okaxis';

  @override
  Widget build(BuildContext context) {
    if (isCupertino) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _openSheet(context),
        child: const _SupportLabel(),
      );
    }
    return TextButton(
      onPressed: () => _openSheet(context),
      child: const _SupportLabel(),
    );
  }

  Future<void> _openSheet(BuildContext context) {
    if (isCupertino) {
      return showCupertinoModalPopup<void>(
        context: context,
        builder: (sheetContext) => CupertinoActionSheet(
          title: const Text('Support Raa Podham'),
          message: const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Column(
              children: [
                Text(
                  "If you're enjoying the app, you're welcome to send anything you like to this UPI ID.",
                ),
                SizedBox(height: 12),
                _CopyableUpiId(upiId: _upiId),
              ],
            ),
          ),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(sheetContext),
            child: const Text('Done'),
          ),
        ),
      );
    }

    return showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetDragHandle(),
              const SizedBox(height: 16),
              Text(
                'Support Raa Podham',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                "If you're enjoying the app, you're welcome to send anything you like to this UPI ID.",
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              const _CopyableUpiId(upiId: _upiId),
              if (_canOpenUpiApp) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _openUpiApp(sheetContext),
                  child: const Text('Pay with a UPI app'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUpiApp(BuildContext context) async {
    final uri = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {'pa': _upiId, 'pn': 'Manoj Reddy', 'cu': 'INR'},
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No UPI app found — copy the UPI ID instead.'),
        ),
      );
    }
  }
}

class _SupportLabel extends StatelessWidget {
  const _SupportLabel();

  @override
  Widget build(BuildContext context) {
    final style = isCupertino
        ? CupertinoTheme.of(context).textTheme.actionTextStyle
        : Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: AppColors.sunriseAmber);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isCupertino ? CupertinoIcons.heart : Icons.favorite_border,
          size: 18,
          color: AppColors.sunriseAmber,
        ),
        const SizedBox(width: 8),
        Text('Support this project', style: style),
      ],
    );
  }
}

/// The UPI ID, tap-to-copy — flips to a brief "Copied!" confirmation
/// instead of relying on a platform-specific snackbar/toast, so it looks
/// and behaves the same on both platforms.
class _CopyableUpiId extends StatefulWidget {
  const _CopyableUpiId({required this.upiId});

  final String upiId;

  @override
  State<_CopyableUpiId> createState() => _CopyableUpiIdState();
}

class _CopyableUpiIdState extends State<_CopyableUpiId> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.upiId));
    HapticFeedback.selectionClick();
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final background = isCupertino
        ? CupertinoColors.systemGrey5
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final icon = _copied
        ? (isCupertino ? CupertinoIcons.check_mark : Icons.check)
        : (isCupertino ? CupertinoIcons.doc_on_doc : Icons.copy_rounded);

    return GestureDetector(
      onTap: _copy,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _copied ? 'Copied!' : widget.upiId,
              style: AppTextTheme.monospace(fontSize: 14),
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 16),
          ],
        ),
      ),
    );
  }
}

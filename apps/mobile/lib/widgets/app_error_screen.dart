import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// The one error screen every screen in the app should reach for when
/// its whole content depends on a failed API/network call, rather than
/// each screen inventing its own — logs the real [error] (and
/// [stackTrace], if given) to the debug console, debug builds only, and
/// never surfaces that raw, technical detail to the user, who just sees
/// a generic, friendly [message] instead.
class AppErrorScreen extends StatelessWidget {
  AppErrorScreen({
    super.key,
    required Object error,
    StackTrace? stackTrace,
    this.message = "Something went wrong. Please try again.",
    this.onRetry,
  }) {
    if (kDebugMode) {
      debugPrint('AppErrorScreen: $error');
      if (stackTrace != null) debugPrint('$stackTrace');
    }
  }

  final String message;

  /// Shown as a button below the message when given, e.g.
  /// `() => ref.invalidate(someProvider)`. Omitted for a screen with no
  /// sensible way to retry on its own.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final textStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.textStyle
        : Theme.of(context).textTheme.bodyMedium;
    final onRetry = this.onRetry;

    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCupertino
                  ? CupertinoIcons.exclamationmark_triangle
                  : Icons.error_outline,
              size: 40,
              color: textStyle?.color?.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: textStyle),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              isCupertino
                  ? CupertinoButton.filled(
                      onPressed: onRetry,
                      child: const Text('Try again'),
                    )
                  : FilledButton(
                      onPressed: onRetry,
                      child: const Text('Try again'),
                    ),
            ],
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

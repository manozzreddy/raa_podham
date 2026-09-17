import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// The shared "still loading" scaffold every screen's `AsyncValue.when`'s
/// `loading:` branch should reach for instead of inventing its own — the
/// same pairing [AppErrorScreen] (this file's sibling) already provides
/// for the `error:` branch. [title] is for a screen that has its own nav
/// bar title even before data arrives (e.g. "Past rides"); omitted, it's
/// just a bare spinner in an untitled scaffold.
class LoadingScaffold extends StatelessWidget {
  const LoadingScaffold({super.key, this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    final indicator = isCupertino
        ? const CupertinoActivityIndicator()
        : const CircularProgressIndicator();
    final title = this.title;

    if (isCupertino) {
      return CupertinoPageScaffold(
        navigationBar: title == null
            ? null
            : CupertinoNavigationBar(middle: Text(title)),
        child: Center(child: indicator),
      );
    }
    return Scaffold(
      appBar: title == null ? null : AppBar(title: Text(title)),
      body: Center(child: indicator),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/theme.dart';
import '../../../widgets/made_with_love_footer.dart';

/// The app's left-side menu: brand header, "About", and a credit footer.
///
/// [Scaffold.drawer] renders this natively (slide-in with scrim, closed
/// via [Navigator.pop]) on Material. [CupertinoPageScaffold] has no
/// drawer slot at all — [openCupertinoAppMenu] shows the same content in
/// a custom slide-from-left overlay for that platform instead, still
/// closed the same way since a `showGeneralDialog` route responds to
/// [Navigator.pop] exactly like a Material drawer does.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    const content = _AppDrawerContent();
    return isCupertino ? content : const Drawer(child: content);
  }
}

Future<void> openCupertinoAppMenu(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierLabel: 'Menu',
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      // Both dimensions matter here, not just width: AppDrawer's Column
      // uses a Spacer to pin the footer, which needs a bounded height to
      // expand into — Align alone only bounds this to the screen's full
      // height when its child does too.
      return const Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 300,
          height: double.infinity,
          child: AppDrawer(),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final offset = Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);
      return SlideTransition(position: offset, child: child);
    },
  );
}

class _AppDrawerContent extends StatelessWidget {
  const _AppDrawerContent();

  @override
  Widget build(BuildContext context) {
    final background = isCupertino
        ? CupertinoTheme.of(context).scaffoldBackgroundColor
        : Theme.of(context).colorScheme.surface;

    // Material, not ColoredBox: `_AboutTile`'s ListTile paints its ripple
    // onto the nearest Material ancestor, then this widget's own opaque
    // background would paint over (and hide) that ripple if it weren't
    // one itself.
    return Material(
      color: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DrawerHeader(),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  _AboutTile(
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/about');
                    },
                  ),
                  const Spacer(),
                  Container(height: 1, color: AppColors.hairline),
                  const MadeWithLoveFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The drawer's brand moment — the app mark on its own cream card and the
/// Unbounded wordmark — a single fixed design like the sign-in screen's,
/// not the app's usual Material/Cupertino split, with the gradient
/// running full-bleed under the status bar.
class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.predawnIndigo,
            AppColors.sunriseAmber,
            AppColors.sunRimGold,
          ],
          stops: [0.0, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Row(
            children: [
              const _DrawerAppMark(),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Raa Podham',
                  style: GoogleFonts.unbounded(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.firstLightCream,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerAppMark extends StatelessWidget {
  const _DrawerAppMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.firstLightCream,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // app_mark.png's actual glyph only fills ~46% of its own canvas
      // (a lot of baked-in transparent margin) — padding alone can't
      // fix that, so this zooms in instead of just shrinking further.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Transform.scale(
          scale: 1.5,
          child: Image.asset('assets/icons/app_mark.png'),
        ),
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (isCupertino) {
      return CupertinoListTile(
        leading: const Icon(CupertinoIcons.info),
        title: const Text('About'),
        trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
        onTap: onTap,
      );
    }
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('About'),
      onTap: onTap,
    );
  }
}

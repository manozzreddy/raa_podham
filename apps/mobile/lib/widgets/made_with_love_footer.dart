import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/theme.dart';

/// The small credit line pinned to the bottom of [AppDrawer] and
/// `AboutScreen` — the first widget under `lib/widgets/`, needed by both
/// of those at once rather than promoted here later from a single
/// feature's own `widgets/`.
class MadeWithLoveFooter extends StatelessWidget {
  const MadeWithLoveFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final mutedColor = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle.color
        : Theme.of(context).textTheme.labelMedium?.color;

    // Two tiers, not one flat sentence: a quiet tracked-caps lead-in,
    // then the name in Unbounded (same one-off treatment as the sign-in
    // wordmark) so it reads as a signature, not fine print.
    final introStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
      color: mutedColor?.withValues(alpha: 0.5),
    );
    final nameStyle = GoogleFonts.unbounded(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColors.sunriseAmber,
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('MADE WITH', style: introStyle),
            const SizedBox(width: 6),
            Icon(
              isCupertino ? CupertinoIcons.heart_fill : Icons.favorite,
              size: 15,
              color: AppColors.sunriseAmber,
            ),
            const SizedBox(width: 6),
            Text('BY', style: introStyle),
            const SizedBox(width: 6),
            Text('Manoj Reddy', style: nameStyle),
          ],
        ),
      ),
    );
  }
}

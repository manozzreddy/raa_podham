import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../theme/theme.dart';
import '../view_model/sign_in_view_model.dart';

/// The sign-in screen — the root of the unauthenticated route tree. No
/// back button, no way to dismiss without signing in.
///
/// This is a single fixed brand design per the identity doc's mockup,
/// not a place for the app's usual Material/Cupertino split — Google's
/// and Apple's own sign-in buttons are cross-platform by design and must
/// not be reskinned per platform either.
///
/// Note: displays no Telugu text, by standing instruction — the identity
/// doc's mockup also calls for a "రా పోదాం" tagline under the wordmark,
/// which is deliberately omitted here.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signInViewModelProvider);

    ref.listen<AsyncValue<void>>(signInViewModelProvider, (previous, next) {
      if (next.hasError) {
        _messengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Sign-in failed: ${next.error}')),
        );
      }
    });

    final isLoading = state.isLoading;
    final notifier = ref.read(signInViewModelProvider.notifier);

    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.predawnIndigo,
                AppColors.sunriseAmber,
                AppColors.sunRimGold,
              ],
              stops: [0.0, 0.62, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                const _Badge(),
                const SizedBox(height: 24),
                Text(
                  'Raa Podham',
                  style: GoogleFonts.unbounded(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.firstLightCream,
                  ),
                ),
                const Spacer(flex: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _SignInButtons(
                    isLoading: isLoading,
                    onGoogleTap: notifier.signInWithGoogle,
                    onAppleTap: notifier.signInWithApple,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    "By continuing, you're agreeing to ride together safely.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.firstLightCream.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge();

  static const double _size = 72;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: AppColors.firstLightCream,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Image.asset('assets/icons/app_mark.png'),
    );
  }
}

class _SignInButtons extends StatelessWidget {
  const _SignInButtons({
    required this.isLoading,
    required this.onGoogleTap,
    required this.onAppleTap,
  });

  final bool isLoading;
  final VoidCallback onGoogleTap;
  final VoidCallback onAppleTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            _GoogleSignInButton(onPressed: isLoading ? null : onGoogleTap),
            if (isCupertino) ...[
              const SizedBox(height: 12),
              SignInWithAppleButton(onPressed: isLoading ? () {} : onAppleTap),
            ],
          ],
        ),
        if (isLoading)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(26),
            ),
            padding: const EdgeInsets.all(8),
            child: const CircularProgressIndicator(color: Colors.white),
          ),
      ],
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.asphaltInk,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(
              image: AssetImage('assets/icons/google_g.png'),
              width: 20,
              height: 20,
            ),
            SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

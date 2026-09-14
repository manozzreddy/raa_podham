import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../services/providers.dart';
import '../../../theme/theme.dart';

/// Plays the animated app mark once at launch, then hands off to
/// whichever route the router's own auth redirect would otherwise pick.
///
/// `assets/lottie/app_mark_animated.json` is a one-shot draw-in/hold/
/// fade-out sequence (72 frames at 30fps = 2.4s), not a loop — played
/// exactly once here rather than reused as a persistent badge anywhere.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _animationDuration = Duration(milliseconds: 2400);

  @override
  void initState() {
    super.initState();
    unawaited(_navigateWhenReady());
  }

  Future<void> _navigateWhenReady() async {
    User? user;
    try {
      final results = await Future.wait([
        Future<void>.delayed(_animationDuration),
        ref.read(authStateProvider.future),
      ]);
      user = results[1] as User?;
    } catch (_) {
      user = null;
    }
    if (!mounted) return;
    context.go(user != null ? '/home' : '/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    // A single fixed design regardless of platform, same reasoning as
    // SignInScreen: this is a brand moment, not the app's usual chrome.
    return Scaffold(
      backgroundColor: AppColors.firstLightCream,
      body: Center(
        child: Lottie.asset(
          'assets/lottie/app_mark_animated.json',
          width: 200,
          height: 200,
          repeat: false,
        ),
      ),
    );
  }
}

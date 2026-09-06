import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'api_client.dart';
import 'firebase_auth_service.dart';

part 'providers.g.dart';

/// Cross-feature singletons. `keepAlive: true` because these back the
/// router's auth redirect and every feature's repositories — they must
/// outlive any single screen.
@Riverpod(keepAlive: true)
FirebaseAuthService firebaseAuthService(Ref ref) => FirebaseAuthService();

@Riverpod(keepAlive: true)
Stream<User?> authState(Ref ref) => ref.watch(firebaseAuthServiceProvider).authStateChanges();

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) => ApiClient(ref.watch(firebaseAuthServiceProvider));

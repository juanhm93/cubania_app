import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(),
);

final apiClientProvider = Provider<Dio>((ref) {
  return buildApiClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    onUnauthorized: () =>
        ref.read(authControllerProvider.notifier).handleUnauthorized(),
  );
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Owns the student's session: restores it on launch, signs in and out, and
/// drops it when the API says the token is no longer valid.
class AuthController extends Notifier<AuthState> {
  static const String expiredSessionMessage =
      'Tu sesión venció. Vuelve a entrar.';

  TokenStorage get _tokenStorage => ref.read(tokenStorageProvider);

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    Future.microtask(restoreSession);
    return const AuthChecking();
  }

  /// Validates the stored token by loading the profile.
  Future<void> restoreSession() async {
    state = const AuthChecking();

    final token = await _tokenStorage.read();
    if (!ref.mounted) return;

    if (token == null || token.isEmpty) {
      state = const AuthSignedOut();
      return;
    }

    try {
      final student = await _repository.fetchMe();
      if (!ref.mounted) return;
      state = AuthSignedIn(student);
    } on ApiException catch (exception) {
      if (!ref.mounted) return;

      if (exception.isUnauthenticated || exception.isForbidden) {
        await _tokenStorage.delete();
        if (!ref.mounted) return;
        state = const AuthSignedOut();
      } else {
        state = AuthRestoreFailed(exception.message);
      }
    }
  }

  /// Stores the token from a successful code verification.
  Future<void> signIn(AuthSession session) async {
    await _tokenStorage.write(session.token);
    if (!ref.mounted) return;
    state = AuthSignedIn(session.student);
  }

  /// Reloads the profile. Throws [ApiException] so the screen can show it,
  /// except for auth errors, which already send the student back to login.
  Future<void> refreshProfile() async {
    try {
      final student = await _repository.fetchMe();
      if (!ref.mounted) return;
      state = AuthSignedIn(student);
    } on ApiException catch (exception) {
      if (exception.isUnauthenticated) return;
      rethrow;
    }
  }

  /// Revokes the token on the server when possible, and always forgets it locally.
  Future<void> signOut() async {
    try {
      await _repository.logout();
    } on ApiException {
      // Signing out must work offline too; the token expires on its own.
    }

    await _tokenStorage.delete();
    if (!ref.mounted) return;
    state = const AuthSignedOut();
  }

  /// Called by the API client when an authenticated request returns 401.
  Future<void> handleUnauthorized() async {
    if (state is AuthSignedOut) return;

    await _tokenStorage.delete();
    if (!ref.mounted) return;
    state = const AuthSignedOut(message: expiredSessionMessage);
  }
}

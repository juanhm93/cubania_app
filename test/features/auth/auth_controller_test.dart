import 'package:cubania_app/core/network/api_exception.dart';
import 'package:cubania_app/core/storage/token_storage.dart';
import 'package:cubania_app/features/auth/application/auth_controller.dart';
import 'package:cubania_app/features/auth/application/auth_state.dart';
import 'package:cubania_app/features/auth/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  late InMemoryTokenStorage tokenStorage;
  late FakeAuthRepository repository;

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(tokenStorage),
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    container.listen(authControllerProvider, (_, _) {});
    return container;
  }

  /// Lets the restore started in build() finish.
  Future<AuthState> settledState(ProviderContainer container) async {
    for (var i = 0; i < 20; i++) {
      final state = container.read(authControllerProvider);
      if (state is! AuthChecking) return state;
      await Future<void>.delayed(Duration.zero);
    }
    return container.read(authControllerProvider);
  }

  setUp(() {
    tokenStorage = InMemoryTokenStorage();
    repository = FakeAuthRepository();
  });

  test('starts signed out when there is no stored token', () async {
    final container = createContainer();

    expect(await settledState(container), isA<AuthSignedOut>());
  });

  test('restores the session when the stored token is valid', () async {
    await tokenStorage.write('12|secret');
    final container = createContainer();

    final state = await settledState(container);

    expect(state, isA<AuthSignedIn>());
    expect((state as AuthSignedIn).student.id, 42);
  });

  test('drops an expired token', () async {
    await tokenStorage.write('12|expired');
    repository.meError = const ApiException(
      message: 'Tu sesión venció.',
      statusCode: 401,
    );
    final container = createContainer();

    expect(await settledState(container), isA<AuthSignedOut>());
    expect(await tokenStorage.read(), isNull);
  });

  test('keeps the token when the server cannot be reached', () async {
    await tokenStorage.write('12|secret');
    repository.meError = const ApiException(
      message: ApiException.connectionErrorMessage,
    );
    final container = createContainer();

    expect(await settledState(container), isA<AuthRestoreFailed>());
    expect(await tokenStorage.read(), '12|secret');
  });

  test('signIn stores the token and exposes the student', () async {
    final container = createContainer();
    await settledState(container);

    await container
        .read(authControllerProvider.notifier)
        .signIn(
          AuthSession(
            token: '12|new',
            expiresAt: DateTime(2026, 12, 5),
            student: sampleStudent(),
          ),
        );

    expect(container.read(authControllerProvider), isA<AuthSignedIn>());
    expect(await tokenStorage.read(), '12|new');
  });

  test('signOut forgets the token even if the server call fails', () async {
    await tokenStorage.write('12|secret');
    repository.logoutError = const ApiException(
      message: ApiException.connectionErrorMessage,
    );
    final container = createContainer();
    await settledState(container);

    await container.read(authControllerProvider.notifier).signOut();

    expect(repository.logoutCalls, 1);
    expect(container.read(authControllerProvider), isA<AuthSignedOut>());
    expect(await tokenStorage.read(), isNull);
  });

  test('handleUnauthorized sends a signed-in student back to login', () async {
    await tokenStorage.write('12|secret');
    final container = createContainer();
    await settledState(container);

    await container.read(authControllerProvider.notifier).handleUnauthorized();

    final state = container.read(authControllerProvider);
    expect(state, isA<AuthSignedOut>());
    expect((state as AuthSignedOut).message, isNotNull);
    expect(await tokenStorage.read(), isNull);
  });
}

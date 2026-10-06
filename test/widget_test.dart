import 'package:cubania_app/app.dart';
import 'package:cubania_app/core/storage/token_storage.dart';
import 'package:cubania_app/features/auth/application/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

Widget _app({String? storedToken, FakeAuthRepository? repository}) {
  return ProviderScope(
    overrides: [
      tokenStorageProvider.overrideWithValue(InMemoryTokenStorage(storedToken)),
      authRepositoryProvider.overrideWithValue(
        repository ?? FakeAuthRepository(),
      ),
    ],
    child: const CubaniaApp(),
  );
}

void main() {
  testWidgets('shows the login screen when there is no session', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Enviarme el código'), findsOneWidget);
    expect(find.text('Correo'), findsWidgets);
  });

  testWidgets('validates the email before asking for a code', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enviarme el código'));
    await tester.pump();
    expect(find.text('Ingresa tu correo.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('identifierField')), 'ana@');
    await tester.tap(find.text('Enviarme el código'));
    await tester.pump();
    expect(find.text('Ese correo no parece válido.'), findsOneWidget);
  });

  testWidgets('asks for the code after a valid email', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('identifierField')),
      'ana@example.com',
    );
    await tester.tap(find.text('Enviarme el código'));
    await tester.pumpAndSettle();

    expect(find.text('Revisa tu correo'), findsOneWidget);
    expect(find.byKey(const Key('codeField')), findsOneWidget);
  });

  testWidgets('opens the profile when a valid token is stored', (tester) async {
    await tester.pumpWidget(_app(storedToken: '12|secret'));
    await tester.pumpAndSettle();

    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.text('Básico 1'), findsOneWidget);
    expect(find.text('Salsa casino'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/presentation/profile_screen.dart';
import '../application/auth_controller.dart';
import '../application/auth_state.dart';
import 'login_screen.dart';

/// Shows the right screen for the current session state.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return switch (authState) {
      AuthChecking() => const _SplashScreen(),
      AuthSignedOut(:final message) => LoginScreen(initialMessage: message),
      AuthSignedIn(:final student) => ProfileScreen(student: student),
      AuthRestoreFailed(:final message) => _RestoreFailedScreen(
        message: message,
        onRetry: () =>
            ref.read(authControllerProvider.notifier).restoreSession(),
        onSignOut: () => ref.read(authControllerProvider.notifier).signOut(),
      ),
    };
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _RestoreFailedScreen extends StatelessWidget {
  const _RestoreFailedScreen({
    required this.message,
    required this.onRetry,
    required this.onSignOut,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
              const SizedBox(height: 8),
              TextButton(onPressed: onSignOut, child: const Text('Salir')),
            ],
          ),
        ),
      ),
    );
  }
}

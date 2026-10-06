import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/student_profile.dart';

/// "Mi perfil": the student's data and current level.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, required this.student});

  final StudentProfile student;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isSigningOut = false;

  Future<void> _refresh() async {
    try {
      await ref.read(authControllerProvider.notifier).refreshProfile();
    } on ApiException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(exception.message)));
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'Para volver a entrar te enviaremos un código a tu correo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSigningOut = true);
    await ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final student = widget.student;
    final level = student.currentLevel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _isSigningOut ? null : _confirmSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              '¡Hola, ${student.firstName}! 💃',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            _LevelCard(level: level),
            const SizedBox(height: 24),
            Text('Tus datos', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.person_outline,
                    label: 'Nombre',
                    value: student.name,
                  ),
                  _InfoTile(
                    icon: Icons.alternate_email,
                    label: 'Correo',
                    value: student.email,
                  ),
                  _InfoTile(
                    icon: Icons.badge_outlined,
                    label: 'Cédula',
                    value: student.dni,
                  ),
                  _InfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Teléfono',
                    value: student.phone,
                  ),
                  _InfoTile(
                    icon: Icons.cake_outlined,
                    label: 'Cumpleaños',
                    value: student.birthday == null
                        ? null
                        : _formatDate(student.birthday!),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level});

  final Level? level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: level == null
            ? Text(
                'No tienes un curso activo en este momento.',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level!.danceType?.name ?? 'Tu nivel',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    level!.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(
        (value == null || value!.isEmpty) ? 'No registrado' : value!,
      ),
    );
  }
}

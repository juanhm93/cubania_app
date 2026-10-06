import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../application/auth_controller.dart';
import '../domain/student_identifier.dart';
import 'verify_code_screen.dart';

enum IdentifierType { email, dni }

/// Step 1: the student enters their email or cédula and asks for a code.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.initialMessage});

  /// Shown above the form, for example when the session expired.
  final String? initialMessage;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();

  IdentifierType _type = IdentifierType.email;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.initialMessage;
  }

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final trimmed = value?.trim() ?? '';

    if (trimmed.isEmpty) {
      return _type == IdentifierType.email
          ? 'Ingresa tu correo.'
          : 'Ingresa tu cédula.';
    }

    if (_type == IdentifierType.email && !_emailPattern.hasMatch(trimmed)) {
      return 'Ese correo no parece válido.';
    }

    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    final value = _identifierController.text.trim();
    final identifier = _type == IdentifierType.email
        ? StudentIdentifier.email(value.toLowerCase())
        : StudentIdentifier.dni(value);

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final request = await ref
          .read(authRepositoryProvider)
          .requestCode(identifier);
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              VerifyCodeScreen(identifier: identifier, codeRequest: request),
        ),
      );
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            exception.fieldErrors[identifier.isEmail ? 'email' : 'dni'] ??
            exception.message;
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmail = _type == IdentifierType.email;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Cubanía',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entra con el correo o la cédula con que te inscribiste. '
                    'Te enviaremos un código a tu correo.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  SegmentedButton<IdentifierType>(
                    segments: const [
                      ButtonSegment(
                        value: IdentifierType.email,
                        label: Text('Correo'),
                        icon: Icon(Icons.alternate_email),
                      ),
                      ButtonSegment(
                        value: IdentifierType.dni,
                        label: Text('Cédula'),
                        icon: Icon(Icons.badge_outlined),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: _isSubmitting
                        ? null
                        : (selection) => setState(() {
                            _type = selection.first;
                            _identifierController.clear();
                            _errorMessage = null;
                            _formKey.currentState?.reset();
                          }),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('identifierField'),
                    controller: _identifierController,
                    enabled: !_isSubmitting,
                    keyboardType: isEmail
                        ? TextInputType.emailAddress
                        : TextInputType.text,
                    autocorrect: false,
                    textInputAction: TextInputAction.send,
                    autofillHints: isEmail
                        ? const [AutofillHints.email]
                        : const <String>[],
                    decoration: InputDecoration(
                      labelText: isEmail ? 'Correo' : 'Cédula',
                      hintText: isEmail ? 'tu@correo.com' : 'V-12345678',
                    ),
                    validator: _validate,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text('Enviarme el código'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

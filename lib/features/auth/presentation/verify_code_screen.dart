import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../application/auth_controller.dart';
import '../data/auth_repository.dart';
import '../domain/student_identifier.dart';

/// Step 2: the student types the code from their email.
class VerifyCodeScreen extends ConsumerStatefulWidget {
  const VerifyCodeScreen({
    super.key,
    required this.identifier,
    required this.codeRequest,
  });

  final StudentIdentifier identifier;
  final LoginCodeRequest codeRequest;

  @override
  ConsumerState<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends ConsumerState<VerifyCodeScreen> {
  static const int resendCooldownSeconds = 60;

  final _codeController = TextEditingController();

  late LoginCodeRequest _codeRequest = widget.codeRequest;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _infoMessage;
  int _resendSecondsLeft = resendCooldownSeconds;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _resendTimer = _countDown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSecondsLeft = resendCooldownSeconds);
    _resendTimer = _countDown();
  }

  Timer _countDown() {
    return Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendSecondsLeft--);
      if (_resendSecondsLeft <= 0) {
        timer.cancel();
      }
    });
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (_isVerifying) return;

    if (code.length != _codeRequest.codeLength) {
      setState(
        () => _errorMessage =
            'El código tiene ${_codeRequest.codeLength} dígitos.',
      );
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final session = await ref
          .read(authRepositoryProvider)
          .verifyCode(
            identifier: widget.identifier,
            code: code,
            deviceName: AppConfig.deviceName,
          );
      await ref.read(authControllerProvider.notifier).signIn(session);
      if (!mounted) return;

      // The gate underneath now shows the profile; drop the login screens.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (exception) {
      if (!mounted) return;
      _codeController.clear();
      setState(() {
        _errorMessage = exception.fieldErrors['code'] ?? exception.message;
      });
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resend() async {
    if (_isResending || _resendSecondsLeft > 0) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final request = await ref
          .read(authRepositoryProvider)
          .requestCode(widget.identifier);
      if (!mounted) return;

      _codeController.clear();
      setState(() {
        _codeRequest = request;
        _infoMessage = 'Te enviamos un código nuevo. El anterior ya no sirve.';
      });
      _startResendCooldown();
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _errorMessage = exception.message);
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destination = widget.identifier.isEmail
        ? widget.identifier.value
        : 'el correo asociado a tu cédula';

    return Scaffold(
      appBar: AppBar(title: const Text('Revisa tu correo')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Si tienes una inscripción activa, enviamos un código de '
                '${_codeRequest.codeLength} dígitos a $destination. '
                'Vence en ${_codeRequest.expiresInMinutes} minutos.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '¿No te llega? Revisa la carpeta de spam.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                key: const Key('codeField'),
                controller: _codeController,
                enabled: !_isVerifying,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: _codeRequest.codeLength,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: theme.textTheme.headlineMedium?.copyWith(
                  letterSpacing: 12,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '······',
                ),
                onChanged: (value) {
                  if (value.length == _codeRequest.codeLength) {
                    _verify();
                  }
                },
                onSubmitted: (_) => _verify(),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              if (_infoMessage != null) ...[
                const SizedBox(height: 16),
                Text(_infoMessage!, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isVerifying ? null : _verify,
                child: _isVerifying
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Entrar'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: (_resendSecondsLeft > 0 || _isResending)
                    ? null
                    : _resend,
                child: Text(
                  _resendSecondsLeft > 0
                      ? 'Reenviar código en $_resendSecondsLeft s'
                      : 'Reenviar código',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

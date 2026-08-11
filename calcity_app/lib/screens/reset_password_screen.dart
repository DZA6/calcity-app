import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';

/// Password reset, entirely in-app:
///   step 1 — enter email, we send a 6-digit code
///   step 2 — enter the code + a new password
/// No browser, no links — the user never leaves the app.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _newPass = TextEditingController();
  final _confirmPass = TextEditingController();

  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _newPass.dispose();
    _confirmPass.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = 'Enter the email on your account.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final msg = await ApiService().requestPasswordReset(_email.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _codeSent = true;
      _error = msg; // "check your email" info, or an error to show
    });
  }

  Future<void> _confirmReset() async {
    final code = _code.text.trim();
    final pw = _newPass.text;
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code from your email.');
      return;
    }
    if (pw.length < 10) {
      setState(() => _error = 'New password must be at least 10 characters.');
      return;
    }
    if (pw != _confirmPass.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await ApiService().confirmPasswordReset(
      email: _email.text,
      code: code,
      newPassword: pw,
    );
    if (!mounted) return;
    if (err == null) {
      // Success — back to sign in.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset! You can now sign in.')),
      );
      Navigator.pop(context);
    } else {
      setState(() {
        _busy = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_codeSent ? 'Reset Password' : 'Forgot Password?')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(_codeSent ? Icons.pin_rounded : Icons.lock_reset_rounded,
                  color: cs.primary, size: 56),
              const SizedBox(height: 12),
              Text(
                _codeSent
                    ? 'Enter the code from your email'
                    : 'We\'ll email you a reset code',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                _codeSent
                    ? 'A 6-digit code was sent to ${_email.text.trim()}. It expires in 30 minutes.'
                    : 'Enter the email on your account and we\'ll send a 6-digit code. You can pick a new password right here in the app.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              if (_error != null && !_codeSent) ...[
                _errorBox(cs, _error!),
                const SizedBox(height: 14),
              ],
              if (_codeSent) ...[
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 6),
                  decoration: const InputDecoration(
                    labelText: '6-digit code',
                    prefixIcon: Icon(Icons.pin_outlined),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _newPass,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New password',
                    prefixIcon: Icon(Icons.lock_outline),
                    helperText: 'At least 10 characters with upper, lower, number & symbol',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _confirmPass,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  onSubmitted: (_) {
                    if (!_busy) _confirmReset();
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  // In this phase _error holds the "check your email" info message.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_error!,
                        style: TextStyle(fontSize: 13, color: cs.primary)),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _busy ? null : _confirmReset,
                    child: _busy
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Set New Password', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  onSubmitted: (_) {
                    if (!_busy) _requestCode();
                  },
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _busy ? null : _requestCode,
                    child: _busy
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Send Reset Code', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorBox(ColorScheme cs, String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(msg, style: TextStyle(color: cs.onErrorContainer, fontSize: 13)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_strings.dart';
import '../../services/auth_service.dart';
import '../../services/settings_service.dart';

/// Kept simple on purpose — a personal app doesn't need an enterprise
/// password policy, just enough to rule out trivially weak passwords.
/// Only enforced at signup; an existing password at login isn't re-judged.
String? _passwordValidationError(String password, AppStrings strings) {
  if (password.length < 8) return strings.passwordAlmeno8Caratteri;
  final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
  final hasDigitOrSpecial = RegExp(r'[0-9!@#$%^&*(),.?":{}|<>_\-+=\[\]~`/\\;]').hasMatch(password);
  if (!hasLetter || !hasDigitOrSpecial) {
    return strings.passwordRequisiti;
  }
  return null;
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();

  bool _isSignUp = false;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSignUp) {
      final passwordError = _passwordValidationError(_passwordController.text, AppStrings.of(context));
      if (passwordError != null) {
        setState(() => _errorMessage = passwordError);
        return;
      }
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        final nickname = _nicknameController.text.trim();
        if (nickname.isNotEmpty) {
          try {
            await SettingsService().saveNickname(nickname);
          } catch (_) {
            // No active session yet (email confirmation pending) — the
            // user can still set it later from Profilo.
          }
        }
      } else {
        await _authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Pura',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: strings.email),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  onChanged: _isSignUp ? (_) => setState(() {}) : null,
                  decoration: InputDecoration(labelText: strings.password),
                ),
                if (_isSignUp && _passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Builder(builder: (context) {
                    final error = _passwordValidationError(_passwordController.text, strings);
                    return Text(
                      error ?? strings.passwordValida,
                      style: TextStyle(
                        fontSize: 12,
                        color: error == null
                            ? Colors.green
                            : Theme.of(context).colorScheme.error,
                      ),
                    );
                  }),
                ],
                if (_isSignUp) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nicknameController,
                    decoration: InputDecoration(labelText: strings.nicknameOpzionale),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: Text(_loading ? '...' : (_isSignUp ? strings.registrati : strings.accedi)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp ? strings.haiGiaUnAccountAccedi : strings.nonHaiUnAccountRegistrati,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

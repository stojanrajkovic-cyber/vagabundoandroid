import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../app/theme/spacing.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/primary_button.dart';

/// Ekvivalent SignInSignUpView.swift.
/// Prikazuje se u /profile tabu kad `session.isAuthenticated == false`.
class SignInSignUpScreen extends ConsumerStatefulWidget {
  const SignInSignUpScreen({super.key});

  @override
  ConsumerState<SignInSignUpScreen> createState() =>
      _SignInSignUpScreenState();
}

class _SignInSignUpScreenState extends ConsumerState<SignInSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = ref.read(authServiceProvider);

    try {
      if (_isSignUp) {
        await authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      // Uspješna prijava -> authStateProvider emitira novog usera ->
      // router se re-evaluira -> /profile prikazuje ProfileScreen automatski.
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _mapAuthError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email adresa nije valjana.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Pogrešan email ili lozinka.';
      case 'email-already-in-use':
        return 'Račun s ovim emailom već postoji.';
      case 'weak-password':
        return 'Lozinka je preslaba.';
      default:
        return e.message ?? 'Došlo je do greške. Pokušaj ponovno.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  _isSignUp ? 'Kreiraj račun' : 'Dobrodošao natrag',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Prijavi se da spremiš svoje planove puta.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Unesi valjan email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Lozinka',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Lozinka mora imati barem 6 znakova';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: _isSignUp ? 'Registriraj se' : 'Prijavi se',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp
                        ? 'Već imaš račun? Prijavi se'
                        : 'Nemaš račun? Registriraj se',
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

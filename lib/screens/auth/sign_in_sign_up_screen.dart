import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
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
  bool _acceptedTos = false;
  bool _acceptedPrivacy = false;
  bool _obscurePassword = true;
  bool _isGoogleLoading = false;
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

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    try {
      await ref.read(authServiceProvider).sendPasswordReset(email);
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reset email sent'),
          content: Text('We sent a password reset link to $email.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapAuthError(e))),
      );
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      // Uspješna prijava -> authStateProvider emitira novog usera -> router
      // redirect logic vodi na Profile, isto kao email/password submit.
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorMessage = _mapAuthError(e));
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address is invalid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'That password is too weak.';
      case 'sign-in-cancelled':
        return ''; // korisnik otkazao — ne prikazuj kao grešku
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _acceptedTos && _acceptedPrivacy;

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
                  _isSignUp ? 'Create account' : 'Welcome back',
                  style: AppTypography.heroTitle.copyWith(color: Theme.of(context).colorScheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Sign in to save your travel plans.',
                  style: AppTypography.body.copyWith(color: Theme.of(context).colorScheme.onSurface),
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
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed:
                        _emailController.text.trim().isEmpty ? null : _forgotPassword,
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _LegalCheckRow(
                  value: _acceptedTos,
                  onChanged: (v) => setState(() => _acceptedTos = v ?? false),
                  prefixText: 'I accept the ',
                  linkText: 'Terms of Service',
                  url: 'https://vagabundo.app/terms-of-service-tos/',
                ),
                _LegalCheckRow(
                  value: _acceptedPrivacy,
                  onChanged: (v) => setState(() => _acceptedPrivacy = v ?? false),
                  prefixText: 'I accept the ',
                  linkText: 'Privacy Policy',
                  url: 'https://vagabundo.app/privacy-policy/',
                ),
                if (!canSubmit) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'You must accept the Terms of Service and Privacy Policy to continue.',
                    style: AppTypography.bodySecondary.copyWith(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _errorMessage!,
                    style: AppTypography.body.copyWith(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: _isSignUp ? 'Sign up' : 'Sign in',
                  isLoading: _isLoading,
                  onPressed: canSubmit ? _submit : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign in'
                        : "Don't have an account? Sign up",
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(child: Divider(color: context.cardStroke)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Text(
                        'or',
                        style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
                      ),
                    ),
                    Expanded(child: Divider(color: context.cardStroke)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  icon: _isGoogleLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.g_mobiledata),
                  label: const Text('Continue with Google'),
                  onPressed: canSubmit && !_isGoogleLoading ? _continueWithGoogle : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Checkbox + podvučen link ("I accept the Terms of Service") — tap na link
/// otvara URL preko url_launcher, tap na checkbox toggluje prihvatanje.
class _LegalCheckRow extends StatelessWidget {
  const _LegalCheckRow({
    required this.value,
    required this.onChanged,
    required this.prefixText,
    required this.linkText,
    required this.url,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String prefixText;
  final String linkText;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Expanded(
          child: GestureDetector(
            onTap: () => launchUrl(Uri.parse(url)),
            child: Text.rich(
              TextSpan(
                style: AppTypography.bodySecondary.copyWith(color: context.textPrimary),
                children: [
                  TextSpan(text: prefixText),
                  TextSpan(
                    text: linkText,
                    style: TextStyle(
                      color: context.accent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

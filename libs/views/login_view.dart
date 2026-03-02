import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/constants.dart';
import '../utils/validators.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'widgets/custom_button.dart';
import 'widgets/custom_textfield.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  bool _didAutoPrompt = false;
  bool _checkingBiometric = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBiometricGate());
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _checkBiometricGate() async {
    if (_didAutoPrompt) return;
    _didAutoPrompt = true;

    if (mounted) setState(() => _checkingBiometric = true);

    final pvm = context.read<ProfileViewModel>();
    await pvm.loadProfile();
    if (!mounted) return;

    // No Firebase session OR biometric not enabled -> show password login UI
    if (pvm.user == null || !pvm.biometricEnabled) {
      setState(() => _checkingBiometric = false);
      return;
    }

    // Try biometric unlock
    final ok = await pvm.biometricUnlock();
    if (!mounted) return;

    setState(() => _checkingBiometric = false);

    if (ok) {
      Navigator.pushReplacementNamed(context, AppRoutes.profile);
    } else {
      _snack(pvm.errorMessage ?? 'Biometric authentication failed.');
      // stay on password form as fallback
    }
  }

  Future<void> _goProfile() async {
    final pvm = context.read<ProfileViewModel>();
    await pvm.loadProfile();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.profile);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthViewModel, ProfileViewModel>(
      builder: (context, authVm, profileVm, _) {
        // Show "fingerprint gate" loader while checking
        if (_checkingBiometric) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final err = authVm.errorMessage ?? profileVm.errorMessage;
        if (err != null && err.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _snack(err);
            authVm.errorMessage = null;
            profileVm.errorMessage = null;
          });
        }

        return Scaffold(
          appBar: AppBar(title: const Text('SecureVault Login')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _email,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _pass,
                        label: 'Password',
                        obscureText: true,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Password is required'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Email/Password Login
                      CustomButton(
                        text: 'Login',
                        loading: authVm.isLoading,
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;

                          final ok = await authVm.login(
                            email: _email.text,
                            password: _pass.text,
                          );
                          if (!mounted) return;
                          if (ok) await _goProfile();
                        },
                      ),

                      const SizedBox(height: 12),

                      // Google Sign-In
                      CustomButton(
                        text: 'Sign in with Google',
                        loading: authVm.isLoading,
                        onPressed: () async {
                          final ok = await authVm.signInWithGoogle();
                          if (!mounted) return;
                          if (ok) await _goProfile();
                        },
                      ),

                      const SizedBox(height: 12),

                      // Manual biometric unlock (optional button)
                      CustomButton(
                        text: 'Unlock with Fingerprint',
                        loading: profileVm.isLoading,
                        onPressed: () async {
                          final ok = await profileVm.biometricUnlock();
                          if (!mounted) return;
                          if (ok) await _goProfile();
                          else {
                            _snack(profileVm.errorMessage ??
                                'Biometric authentication failed.');
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.register);
                        },
                        child: const Text('Create an account'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
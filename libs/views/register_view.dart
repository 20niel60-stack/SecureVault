import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/constants.dart';
import '../utils/validators.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'widgets/custom_button.dart';
import 'widgets/custom_textfield.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _goProfile() async {
    final pvm = context.read<ProfileViewModel>();
    await pvm.loadProfile();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.profile);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authVm, _) {
        final err = authVm.errorMessage;
        if (err != null && err.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _snack(err);
            authVm.errorMessage = null;
          });
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Register')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _name,
                        label: 'Full Name',
                        validator: Validators.fullName,
                      ),
                      const SizedBox(height: 12),
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
                        validator: Validators.password,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _confirm,
                        label: 'Confirm Password',
                        obscureText: true,
                        validator: (v) =>
                            Validators.confirmPassword(_pass.text, v),
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Create Account',
                        loading: authVm.isLoading,
                        onPressed: () async {
                          if (authVm.isLoading) return;
                          if (!_formKey.currentState!.validate()) return;

                          final ok = await authVm.register(
                            fullName: _name.text.trim(),
                            email: _email.text.trim(),
                            password: _pass.text,
                          );

                          if (!mounted) return;

                          if (ok) {
                            // optional clear
                            _name.clear();
                            _email.clear();
                            _pass.clear();
                            _confirm.clear();

                            await _goProfile();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.login,
                          );
                        },
                        child: const Text('Back to Login'),
                      )
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
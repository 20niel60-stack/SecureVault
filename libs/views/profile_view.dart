import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/constants.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _editName(ProfileViewModel vm) async {
    final controller = TextEditingController(text: vm.user?.displayName ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter new name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final success = await vm.updateDisplayName(controller.text);
      if (!mounted) return;
      _snack(success ? 'Profile updated!' : (vm.errorMessage ?? 'Failed'));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ProfileViewModel>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProfileViewModel, AuthViewModel>(
      builder: (context, vm, authVm, _) {
        final u = vm.user;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: authVm.isLoading
                    ? null
                    : () async {
                  await authVm.logout();
                  if (!mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                        (_) => false,
                  );
                },
              )
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Display Name: ${u?.displayName ?? '-'}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Email: ${u?.email ?? '-'}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _editName(vm),
                  child: const Text('Edit Profile'),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Enable Fingerprint Login'),
                  subtitle: Text(vm.biometricSupported
                      ? 'Use biometrics on next app open'
                      : 'Biometrics not supported'),
                  value: vm.biometricEnabled,
                  onChanged: (v) async {
                    final ok = await vm.setBiometricEnabled(v);
                    if (!mounted) return;
                    if (!ok) _snack(vm.errorMessage ?? 'Cannot enable');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
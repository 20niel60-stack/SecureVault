import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/biometric_service.dart';

import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';

import 'views/login_view.dart';
import 'views/register_view.dart';
import 'views/profile_view.dart';

import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SecureVaultApp());
}

class SecureVaultApp extends StatefulWidget {
  const SecureVaultApp({super.key});

  @override
  State<SecureVaultApp> createState() => _SecureVaultAppState();
}

class _SecureVaultAppState extends State<SecureVaultApp> {
  final _storage = StorageService();
  String _initialRoute = AppRoutes.login;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _decideInitialRoute();
  }

  Future<void> _decideInitialRoute() async {
    final token = await _storage.getToken();
    final biometricEnabled = await _storage.isBiometricEnabled();

    if (token != null && token.isNotEmpty) {
      _initialRoute = biometricEnabled ? AppRoutes.login : AppRoutes.profile;
    } else {
      _initialRoute = AppRoutes.login;
    }

    setState(() => _checked = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      // ✅ give loading screen the same theme too
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0D47A1),
          ),
        ),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final authService = AuthService();
    final biometricService = BiometricService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(
            authService: authService,
            storageService: _storage,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileViewModel(
            authService: authService,
            storageService: _storage,
            biometricService: biometricService,
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,

        // ✅ THIS is the magic: consistent modern look everywhere
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0D47A1),
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),

          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),

        initialRoute: _initialRoute,
        routes: {
          AppRoutes.login: (_) => const LoginView(),
          AppRoutes.register: (_) => const RegisterView(),
          AppRoutes.profile: (_) => const ProfileView(),
        },
      ),
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/providers/auth_provider.dart';
import 'package:sipatka/utils/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    // Tunda eksekusi agar build selesai
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNavigation();
    });
  }

  void _handleNavigation() {
    bool hasRedirected = false;

    // Dengarkan event otentikasi
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      if (hasRedirected) return; // Mencegah navigasi ganda

      // Jika ada event reset password, langsung arahkan
      if (data.event == AuthChangeEvent.passwordRecovery) {
        hasRedirected = true;
        Navigator.of(context).pushReplacementNamed('/change-password');
      }
    });

    // Tambahkan jeda singkat untuk memberi waktu pada listener untuk menangkap event deep link
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || hasRedirected) return;

      // Jika tidak ada event khusus, lanjutkan dengan alur login normal
      _redirectBasedOnSession();
    });
  }

  Future<void> _redirectBasedOnSession() async {
    final authProvider = context.read<AuthProvider>();

    // Tunggu hingga provider selesai memuat sesi awal
    while (authProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    if (!mounted) return;

    if (authProvider.isLoggedIn) {
      if (authProvider.userRole == 'admin') {
        Navigator.of(context).pushReplacementNamed('/admin_dashboard');
      } else {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel(); // Selalu batalkan subscription
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/logo-nobg.png", width: 80, fit: BoxFit.contain),
            // const Icon(Icons.school, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              'SIPATKA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

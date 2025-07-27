// lib/screens/auth/verify_otp_screen.dart

import 'package:flutter/material.dart';
import 'package:sipatka/screens/profile/change_password_screen.dart';
import 'package:sipatka/utils/error_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.recovery,
        token: _otpController.text.trim(),
        email: widget.email,
      );

      if (response.user != null && mounted) {
        // Jika OTP benar, arahkan ke halaman ubah password
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
          (route) => false,
        );
      } else {
        throw 'OTP tidak valid atau telah kedaluwarsa.';
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context: context,
          title: 'Verifikasi Gagal',
          message: e is AuthException ? e.message : e.toString(),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi Kode')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Masukkan Kode Verifikasi',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Kode 6 digit telah dikirim ke email:\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 16),
                decoration: const InputDecoration(
                  hintText: '______',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.length != 6) {
                    return 'Masukkan 6 digit kode OTP';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Verifikasi & Lanjutkan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

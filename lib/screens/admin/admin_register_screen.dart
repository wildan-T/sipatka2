// lib/screens/admin/admin_register_screen.dart

import 'package:flutter/material.dart';
import 'package:sipatka/utils/error_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sipatka/main.dart'; // Untuk akses client supabase

class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({super.key});
  @override
  State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _studentNameController = TextEditingController();
  String? _selectedClass;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _classes = ['TK A1', 'TK B1'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _studentNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrasi Akun oleh Admin')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap Orang Tua',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator:
                      (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator:
                      (v) =>
                          (v == null || !v.contains('@'))
                              ? 'Email tidak valid'
                              : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed:
                          () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    ),
                  ),
                  validator:
                      (v) =>
                          (v == null || v.length < 6)
                              ? 'Minimal 6 karakter'
                              : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _studentNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap Anak',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.child_care_outlined),
                  ),
                  validator:
                      (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedClass,
                  decoration: const InputDecoration(
                    labelText: 'Kelas',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.class_outlined),
                  ),
                  hint: const Text('Pilih Kelas'),
                  items:
                      _classes.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedClass = newValue;
                    });
                  },
                  validator:
                      (value) => value == null ? 'Kelas wajib dipilih' : null,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            )
                            : const Text(
                              'Daftarkan Siswa',
                              style: TextStyle(fontSize: 16),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Panggil Edge Function 'register-new-user'
      final response = await supabase.functions.invoke(
        'register-new-user',
        body: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'parentName': _nameController.text.trim(),
          'studentName': _studentNameController.text.trim(),
          'className': _selectedClass, // Gunakan variabel dari dropdown
        },
      );

      // Cek jika ada data dan tidak ada error
      if (response.data != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.data['message'] ?? 'Pendaftaran berhasil!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Kembali ke halaman admin dashboard
        }
      } else {
        throw 'Respons dari server kosong.';
      }
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Terjadi kesalahan tidak diketahui.';
      if (e is FunctionException) {
        if (e.details is Map<String, dynamic>) {
          final details = e.details as Map<String, dynamic>;
          errorMessage = 'Error dari Server: ${details['error']}';
        } else {
          errorMessage = 'Error dari Server: ${e.details.toString()}';
        }
      }

      showErrorDialog(
        context: context,
        title: 'Registrasi Gagal',
        message: errorMessage,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

extension on FunctionException {
  get message => null;
}

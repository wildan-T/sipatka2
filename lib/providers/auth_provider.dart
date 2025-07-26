// lib/providers/auth_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sipatka/models/user_model.dart';
import 'package:sipatka/main.dart'; // Untuk akses 'supabase' client

class AuthProvider with ChangeNotifier {
  StreamSubscription<AuthState>? _authSubscription;
  UserModel? _userModel;
  bool _isLoading = true;
  String? _errorMessage;

  // --- GETTER (Tidak ada perubahan) ---
  UserModel? get userModel => _userModel;
  bool get isLoggedIn => supabase.auth.currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get userName => _userModel?.parentName ?? 'Wali Murid';
  String get userEmail => _userModel?.email ?? '';
  String get studentName => _userModel?.studentName ?? '';
  String get className => _userModel?.className ?? '';
  String get userRole => _userModel?.role ?? 'user';

  AuthProvider() {
    _recoverSession();
    // Dengarkan perubahan status login (login, logout, token refresh)
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final Session? session = data.session;
      if (session != null) {
        _fetchProfile();
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _recoverSession() async {
    // Saat aplikasi pertama kali dibuka, coba pulihkan sesi
    final session = supabase.auth.currentSession;
    if (session != null) {
      await _fetchProfile();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchProfile() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      // --- PANGGIL FUNGSI RPC BARU ---
      final data = await supabase.rpc(
        'get_user_details',
        params: {'p_user_id': userId},
      );

      if (data != null) {
        // Buat UserModel dari data JSON yang dikembalikan RPC
        final studentData = data['student'] as Map<String, dynamic>?;
        _userModel = UserModel(
          uid: data['id'] ?? '',
          email: data['email'] ?? '',
          parentName: data['parent_name'] ?? '',
          role: data['role'] ?? 'user',
          saldo: (data['saldo'] as num?)?.toDouble() ?? 0.0,
          studentName: studentData?['student_name'] ?? '',
          className: studentData?['class_name'] ?? '',
        );
      } else {
        _userModel = null;
      }
    } catch (e) {
      print("Error fetching profile with RPC: $e");
      _userModel = null;
    }
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // 1. Lakukan proses sign in seperti biasa
      final AuthResponse res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // 2. JIKA login berhasil dan user ada, panggil _fetchProfile SECARA LANGSUNG
      //    dan tunggu (await) sampai selesai.
      if (res.user != null) {
        await _fetchProfile();
      } else {
        _errorMessage = 'Login Gagal. Pengguna tidak ditemukan.';
      }
    } on AuthException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan tidak terduga.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- FUNGSI BARU: REGISTER UNTUK USER BIASA (WALI MURID) ---
  Future<void> register({
    required String email,
    required String password,
    required String parentName,
    required String studentName,
    required String className,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await supabase.auth.signUp(
        email: email,
        password: password,
        // 'data' ini akan 'ditangkap' oleh Trigger di database untuk mengisi profil
        data: {
          'parent_name': parentName,
          'student_name': studentName,
          'class_name': className,
        },
      );
      // Setelah sign up, Supabase akan otomatis login dan onAuthStateChange akan terpicu
      // yang kemudian akan memanggil _fetchProfile.
    } on AuthException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan tidak terduga.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  Future<void> resetPassword({required String email}) async {
    _isLoading = true;
    _errorMessage = null; // Bersihkan pesan error lama
    notifyListeners();

    try {
      // Panggil fungsi bawaan Supabase untuk reset password
      await supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage =
          'Terjadi kesalahan tidak terduga saat mengirim email reset.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- FUNGSI UNTUK UBAH PASSWORD ---
  Future<bool> changePassword(String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan tidak terduga saat mengubah password.';
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }
}

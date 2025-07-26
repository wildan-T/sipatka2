// lib/providers/admin_provider.dart

import 'package:flutter/material.dart';
import 'package:sipatka/main.dart';
import 'package:sipatka/models/payment_model.dart'; // Pastikan import ini ada jika digunakan di fungsi lain

class AdminProvider with ChangeNotifier {
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // --- FUNGSI getStudents() DIPERBAIKI DI SINI ---
  Stream<List<Map<String, dynamic>>> getStudents() {
    // Memanggil fungsi RPC yang sudah kita buat sebelumnya
    return supabase
        .rpc('get_all_students_with_parents')
        .asStream()
        .map((response) => (response as List).cast<Map<String, dynamic>>());
  }

  // --- KODE LAINNYA DI DALAM CLASS TETAP SAMA ---
  // Pastikan fungsi-fungsi lain yang mungkin Anda miliki di sini tetap ada.
  Stream<List<Payment>> getPendingPayments() {
    return supabase
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .order('created_at', ascending: true)
        .map((maps) => maps.map((map) => Payment.fromSupabase(map)).toList());
  }

  Future<Map<String, dynamic>>? getFinancialReport(
    DateTime startDate,
    DateTime endDate,
  ) {}

  // --- FUNGSI BARU UNTUK KONFIRMASI & PENOLAKAN ---

  Future<String> confirmPayment(String paymentId) async {
    try {
      final result = await supabase.rpc(
        'confirm_payment',
        params: {'p_payment_id': paymentId},
      );
      return result as String;
    } catch (e) {
      print("Error confirming payment: $e");
      throw 'Gagal mengonfirmasi pembayaran: $e';
    }
  }

  Future<String> rejectPayment(String paymentId) async {
    try {
      final result = await supabase.rpc(
        'reject_payment',
        params: {'p_payment_id': paymentId},
      );
      return result as String;
    } catch (e) {
      print("Error rejecting payment: $e");
      throw 'Gagal menolak pembayaran: $e';
    }
  }
}

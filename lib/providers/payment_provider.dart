import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sipatka/models/payment_model.dart';
import 'package:sipatka/main.dart';

class PaymentProvider with ChangeNotifier {
  List<Payment> _payments = [];
  bool _isLoading = false;

  List<Payment> get payments => _payments;
  bool get isLoading => _isLoading;

  // Getter untuk mendapatkan semua tagihan yang belum lunas (termasuk terlambat)
  List<Payment> get unpaidPayments =>
      _payments
          .where(
            (p) =>
                p.status == PaymentStatus.unpaid ||
                p.status == PaymentStatus.overdue,
          )
          .toList();

  // Getter untuk menghitung jumlah tagihan yang belum lunas
  int get unpaidPaymentsCount => unpaidPayments.length;

  // Getter untuk menghitung total nominal yang harus dibayar
  double get totalUnpaidAmount =>
      unpaidPayments.fold(0.0, (sum, item) => sum + item.amount);

  double get totalPaidAmount => _payments
      .where((p) => p.status == PaymentStatus.paid)
      .fold(0.0, (sum, item) => sum + item.amount);

  Future<bool> submitMultiplePayments({
    required List<Payment> selectedPayments,
    required File proofImage,
    required String paymentMethod,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null || selectedPayments.isEmpty) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final fileExtension = proofImage.path.split('.').last;
      final fileName =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      await supabase.storage
          .from('payment-proofs')
          .upload(
            fileName,
            proofImage,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final proofImageUrl = supabase.storage
          .from('payment-proofs')
          .getPublicUrl(fileName);

      // --- AWAL PERBAIKAN PENTING ---
      // Siapkan data update. Pastikan semua kolom NOT NULL disertakan.
      final updates =
          selectedPayments.map((p) {
            // Ambil bulan dari nama bulan (e.g., "Juli" -> 7)
            final monthMap = {
              'Januari': 1,
              'Februari': 2,
              'Maret': 3,
              'April': 4,
              'Mei': 5,
              'Juni': 6,
              'Juli': 7,
              'Agustus': 8,
              'September': 9,
              'Oktober': 10,
              'November': 11,
              'Desember': 12,
            };

            return {
              // Kolom yang di-update
              'id': p.id,
              'status': 'pending',
              'proof_of_payment_url': proofImageUrl,
              'payment_method': paymentMethod,
              'paid_date': DateTime.now().toIso8601String(),
              'is_verified': false,

              // Kolom WAJIB yang harus disertakan kembali (tidak boleh null)
              'student_id':
                  p.userId, // Ingat, userId di model kita adalah student_id
              'month': monthMap[p.month] ?? 1, // Konversi nama bulan ke angka
              'year': p.year,
              'amount': p.amount,
              'due_date': DateFormat('yyyy-MM-dd').format(p.dueDate),
            };
          }).toList();
      // --- AKHIR PERBAIKAN ---

      await supabase.from('payments').upsert(updates);

      await fetchPayments();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print("Error submitting multiple payments: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchPayments() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      // Jika tidak ada user yang login, pastikan daftar pembayaran kosong.
      _payments = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // --- AWAL KODE BARU YANG EKSPLISIT DAN AMAN ---

      // 1. Dapatkan dulu ID siswa berdasarkan parent_id (user.id yang login)
      //    Kita menggunakan .maybeSingle() untuk menangani kasus jika siswa belum ada.
      final studentResponse =
          await supabase
              .from('students')
              .select('id')
              .eq('parent_id', user.id)
              .maybeSingle();

      // 2. Jika data siswa tidak ditemukan, jangan lakukan apa-apa.
      //    Pastikan daftar pembayaran kosong.
      if (studentResponse == null || studentResponse.isEmpty) {
        print(
          "Sipatka Log: Tidak ada data siswa ditemukan untuk wali dengan ID: ${user.id}",
        );
        _payments = [];
      } else {
        final studentId = studentResponse['id'];
        print(
          "Sipatka Log: Ditemukan siswa dengan ID: $studentId. Mengambil tagihan...",
        );

        // 3. Gunakan studentId untuk mengambil data dari tabel payments.
        //    Ini adalah filter yang hilang sebelumnya.
        final data = await supabase
            .from('payments')
            .select()
            .eq('student_id', studentId) // <-- FILTER EKSPLISIT
            .order('year', ascending: true) // Urutkan berdasarkan tahun
            .order('month', ascending: true); // Lalu urutkan berdasarkan bulan

        _payments = data.map((item) => Payment.fromSupabase(item)).toList();
        print("Sipatka Log: Berhasil mengambil ${_payments.length} tagihan.");
      }

      // --- AKHIR KODE BARU ---
    } catch (e) {
      print("Sipatka Log: Terjadi error saat fetchPayments: $e");
      _payments = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Future<void> fetchPayments() async {
  //   final user = supabase.auth.currentUser;
  //   if (user == null) return;
  //   _isLoading = true;
  //   notifyListeners();

  //   try {
  //     // --- AWAL KODE BARU ---
  //     // RLS policy akan secara otomatis mengurus keamanan dan filter.
  //     // Kita hanya perlu mengambil semua data dari tabel 'payments'.
  //     final data = await supabase
  //         .from('payments')
  //         .select()
  //         .order('created_at', ascending: false);

  //     _payments = data.map((item) => Payment.fromSupabase(item)).toList();
  //     // --- AKHIR KODE BARU ---
  //   } catch (e) {
  //     print("Error fetching payments: $e");
  //     _payments = [];
  //   }

  //   _isLoading = false;
  //   notifyListeners();
  // }

  // Future<bool> submitMultiplePayments({
  //   required List<Payment> selectedPayments,
  //   required File proofImage,
  //   required String paymentMethod,
  // }) async {
  //   final user = supabase.auth.currentUser;
  //   if (user == null || selectedPayments.isEmpty) return false;
  //   _isLoading = true;
  //   notifyListeners();
  //   try {
  //     final fileName =
  //         'proofs/${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
  //     await supabase.storage.from('proofs').upload(fileName, proofImage);
  //     final proofImageUrl = supabase.storage
  //         .from('proofs')
  //         .getPublicUrl(fileName);

  //     final updates =
  //         selectedPayments.map((p) {
  //           return {
  //             'id': p.id,
  //             'status': 'pending',
  //             'proof_of_payment_url': proofImageUrl,
  //             'payment_method': paymentMethod,
  //             'paid_date': DateTime.now().toIso8601String(),
  //             'is_verified': false,
  //           };
  //         }).toList();

  //     await supabase.from('payments').upsert(updates);
  //     await fetchPayments();
  //     _isLoading = false;
  //     notifyListeners();
  //     return true;
  //   } catch (e) {
  //     print("Error submitting multiple payments: $e");
  //     _isLoading = false;
  //     notifyListeners();
  //     return false;
  //   }
  // }
}

import 'package:flutter/material.dart';
import 'package:sipatka/models/user_model.dart'; // Import UserModel

enum PaymentStatus { paid, pending, unpaid, overdue }

class Payment {
  final String id;
  final String userId;
  final String month;
  final int year;
  final double amount;
  final DateTime dueDate;
  PaymentStatus status;
  final DateTime createdAt;
  final DateTime? paidDate;
  final String? paymentMethod;
  final String? proofOfPaymentUrl;
  final bool isVerified;
  final UserModel?
  studentProfile; // <-- TAMBAHAN: untuk menyimpan data profil siswa

  Payment({
    required this.id,
    required this.userId,
    required this.month,
    required this.year,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.createdAt,
    this.paidDate,
    this.paymentMethod,
    this.proofOfPaymentUrl,
    this.isVerified = false,
    this.studentProfile, // <-- Tambahkan di constructor
  });

  factory Payment.fromSupabase(Map<String, dynamic> data) {
    PaymentStatus status = PaymentStatus.values.firstWhere(
      (e) => e.name == data['status'],
      orElse: () => PaymentStatus.unpaid,
    );

    // --- AWAL PERBAIKAN LOGIKA TANGGAL & ZONA WAKTU ---

    // 1. Parse dueDate dari string. Ini akan menghasilkan objek DateTime dalam UTC.
    final dueDateUtc = DateTime.parse(data['due_date']);

    // 2. Konversi dueDate ke tanggal lokal tanpa informasi waktu.
    // Ini memastikan kita hanya membandingkan tanggal, bukan jam atau zona waktu.
    final dueDateLocal = DateTime(
      dueDateUtc.year,
      dueDateUtc.month,
      dueDateUtc.day,
    );

    // 3. Dapatkan tanggal hari ini, juga tanpa informasi waktu.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 4. Lakukan perbandingan yang akurat.
    // Hanya set 'overdue' jika statusnya masih 'unpaid' DAN hari ini sudah lewat dari tanggal jatuh tempo.
    if (status == PaymentStatus.unpaid && today.isAfter(dueDateLocal)) {
      status = PaymentStatus.overdue;
    }
    // --- AKHIR PERBAIKAN ---

    final int monthInt = data['month'] ?? 1;
    final Map<int, String> monthMap = {
      1: 'Januari',
      2: 'Februari',
      3: 'Maret',
      4: 'April',
      5: 'Mei',
      6: 'Juni',
      7: 'Juli',
      8: 'Agustus',
      9: 'September',
      10: 'Oktober',
      11: 'November',
      12: 'Desember',
    };

    return Payment(
      id: data['id'] ?? '',
      userId: data['student_id'] ?? '',
      month: monthMap[monthInt] ?? monthInt.toString(),
      year: data['year'] ?? DateTime.now().year,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: dueDateUtc, // Simpan versi asli UTC
      status: status, // Status yang sudah diperbaiki
      createdAt: DateTime.parse(
        data['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      paidDate:
          data['paid_date'] != null ? DateTime.parse(data['paid_date']) : null,
      paymentMethod: data['payment_method'],
      proofOfPaymentUrl: data['proof_of_payment_url'],
      isVerified: data['is_verified'] ?? false,
      studentProfile:
          data['profiles'] != null
              ? UserModel.fromSupabase(data['profiles'])
              : null,
    );
  }
}

extension PaymentStatusInfo on Payment {
  Map<String, dynamic> getStatusInfo() {
    switch (status) {
      case PaymentStatus.paid:
        return {
          'text': 'Lunas',
          'color': Colors.green,
          'icon': Icons.check_circle,
        };
      case PaymentStatus.pending:
        return {
          'text': 'Menunggu Verifikasi',
          'color': Colors.orange,
          'icon': Icons.pending,
        };
      case PaymentStatus.unpaid:
        return {
          'text': 'Belum Bayar',
          'color': Colors.red,
          'icon': Icons.error,
        };
      case PaymentStatus.overdue:
        return {
          'text': 'Terlambat',
          'color': Colors.red.shade800,
          'icon': Icons.warning,
        };
    }
  }
}

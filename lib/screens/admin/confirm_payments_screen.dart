// lib/screens/admin/confirm_payments_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sipatka/main.dart';
import 'package:sipatka/models/payment_model.dart';
import 'package:sipatka/screens/admin/confirm_payment_detail_screen.dart';

class ConfirmPaymentsScreen extends StatefulWidget {
  const ConfirmPaymentsScreen({super.key});

  @override
  State<ConfirmPaymentsScreen> createState() => _ConfirmPaymentsScreenState();
}

class _ConfirmPaymentsScreenState extends State<ConfirmPaymentsScreen> {
  // --- Mengubah dari Stream ke Future ---
  late Future<List<Map<String, dynamic>>> _pendingPaymentsFuture;

  @override
  void initState() {
    super.initState();
    _pendingPaymentsFuture = _getPendingPayments();
  }

  // --- Fungsi ini sekarang mengembalikan Future, bukan Stream ---
  Future<List<Map<String, dynamic>>> _getPendingPayments() async {
    try {
      // Menggunakan join untuk mengambil data siswa dan wali sekaligus
      final response = await supabase
          .from('payments')
          .select(
            '*, students:student_id(full_name, profiles:parent_id(full_name))',
          )
          .eq('status', 'pending')
          .order('created_at', ascending: true);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      // Memberikan pesan error yang lebih jelas jika gagal
      throw 'Gagal memuat data pembayaran. Pastikan RLS Policy untuk admin sudah benar.';
    }
  }

  // --- Fungsi untuk Refresh ---
  Future<void> _refreshData() async {
    setState(() {
      _pendingPaymentsFuture = _getPendingPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Pembayaran')),
      body: RefreshIndicator(
        // Menambahkan fitur "Tarik untuk Refresh"
        onRefresh: _refreshData,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _pendingPaymentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Error: ${snapshot.error}\n\nTarik ke bawah untuk mencoba lagi.",
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('Tidak ada pembayaran untuk dikonfirmasi.'),
              );
            }

            final payments = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final paymentData = payments[index];
                return _buildPaymentCard(context, paymentData);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPaymentCard(
    BuildContext context,
    Map<String, dynamic> paymentData,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
    );
    final payment = Payment.fromSupabase(paymentData);

    // Mengambil data siswa dan wali dari hasil join yang efisien
    final studentData = paymentData['students'] as Map<String, dynamic>?;
    final profileData = studentData?['profiles'] as Map<String, dynamic>?;

    final studentName = studentData?['full_name'] as String? ?? 'Siswa Dihapus';
    final parentName = profileData?['full_name'] as String? ?? 'Wali Dihapus';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(studentName.isNotEmpty ? studentName[0] : 'S'),
        ),
        title: Text(
          studentName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Tagihan: ${payment.month} ${payment.year}'),
        trailing: Text(
          currencyFormat.format(payment.amount),
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => ConfirmPaymentDetailScreen(
                    payment: payment,
                    studentName: studentName,
                    parentName: parentName,
                  ),
            ),
          );

          // Jika halaman detail mengirim sinyal sukses, refresh daftar
          if (result == true) {
            _refreshData();
          }
        },
      ),
    );
  }
}

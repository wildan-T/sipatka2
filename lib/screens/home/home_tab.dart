// lib/screens/home/home_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sipatka/models/payment_model.dart';
import 'package:sipatka/providers/auth_provider.dart';
import 'package:sipatka/providers/payment_provider.dart';
import 'package:sipatka/utils/app_theme.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, PaymentProvider>(
      builder: (context, auth, paymentProvider, _) {
        final currencyFormat = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
        );

        if (paymentProvider.isLoading && paymentProvider.payments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Mengambil tagihan untuk bulan ini
        final now = DateTime.now();
        final currentMonthName = DateFormat('MMMM', 'id_ID').format(now);
        final currentYear = now.year;
        Payment? currentMonthPayment;
        try {
          currentMonthPayment = paymentProvider.payments.firstWhere(
            (p) =>
                p.month.toLowerCase() == currentMonthName.toLowerCase() &&
                p.year == currentYear,
          );
        } catch (e) {
          currentMonthPayment = null;
        }

        return RefreshIndicator(
          onRefresh: () => paymentProvider.fetchPayments(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- KARTU SELAMAT DATANG ---
                _buildWelcomeCard(auth),
                const SizedBox(height: 24),

                // --- KARTU RINGKASAN TAGIHAN ---
                _buildSummaryCard(
                  paymentProvider.unpaidPaymentsCount,
                  currencyFormat.format(paymentProvider.totalUnpaidAmount),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Tagihan Bulan Ini',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // --- TAMPILAN TAGIHAN BULAN INI ---
                if (currentMonthPayment != null)
                  _buildPaymentItem(currentMonthPayment, currencyFormat)
                else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 40.0,
                        horizontal: 20.0,
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text("Tidak ada tagihan untuk bulan ini."),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget untuk kartu selamat datang
  Widget _buildWelcomeCard(AuthProvider auth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat datang,',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            auth.userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Siswa: ${auth.studentName} (${auth.className})',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Widget untuk kartu ringkasan tagihan
  Widget _buildSummaryCard(int unpaidCount, String totalAmount) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              // Tambahkan Expanded
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Total Tagihan Belum Lunas",
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    "$unpaidCount Bulan",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              // Tambahkan Expanded
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Jumlah",
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    totalAmount,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk menampilkan item tagihan
  Widget _buildPaymentItem(Payment payment, NumberFormat currencyFormat) {
    final statusInfo = payment.getStatusInfo();
    final totalAmount = payment.amount;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: statusInfo['color'],
          width: 1.5,
        ), // Garis tepi berwarna sesuai status
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: Icon(statusInfo['icon'], color: statusInfo['color'], size: 36),
        title: Text(
          '${payment.month} ${payment.year}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Jatuh tempo: ${DateFormat('dd MMM yyyy').format(payment.dueDate)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(totalAmount),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusInfo['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusInfo['text'],
                style: TextStyle(
                  color: statusInfo['color'],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

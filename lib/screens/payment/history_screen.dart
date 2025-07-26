// lib/screens/payment/history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sipatka/models/payment_model.dart';
import '../../providers/payment_provider.dart';
import '../../utils/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // State untuk melacak filter yang aktif
  PaymentStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PaymentProvider>(
        builder: (context, payment, _) {
          if (payment.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter daftar pembayaran berdasarkan status yang dipilih
          final filteredPayments =
              _selectedStatus == null
                  ? payment.payments
                  : payment.payments
                      .where((p) => p.status == _selectedStatus)
                      .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER DAN FILTER ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Riwayat Pembayaran',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFilterChips(),
                  ],
                ),
              ),
              // --- DAFTAR RIWAYAT ---
              Expanded(
                child:
                    filteredPayments.isEmpty
                        ? const Center(
                          child: Text("Tidak ada riwayat untuk filter ini."),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredPayments.length,
                          itemBuilder: (context, index) {
                            return _buildHistoryItem(filteredPayments[index]);
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Widget untuk membuat chip filter
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('Semua'),
            selected: _selectedStatus == null,
            onSelected: (selected) {
              setState(() => _selectedStatus = null);
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Lunas'),
            selected: _selectedStatus == PaymentStatus.paid,
            onSelected: (selected) {
              setState(() => _selectedStatus = PaymentStatus.paid);
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Tertunda'),
            selected: _selectedStatus == PaymentStatus.pending,
            onSelected: (selected) {
              setState(() => _selectedStatus = PaymentStatus.pending);
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Terlambat'),
            selected: _selectedStatus == PaymentStatus.overdue,
            onSelected: (selected) {
              setState(() => _selectedStatus = PaymentStatus.overdue);
            },
          ),
        ],
      ),
    );
  }

  // Widget untuk menampilkan item riwayat
  Widget _buildHistoryItem(Payment payment) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
    );
    final statusInfo = payment.getStatusInfo();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (statusInfo['color'] as Color).withOpacity(0.1),
          child: Icon(
            statusInfo['icon'] as IconData,
            color: statusInfo['color'],
          ),
        ),
        title: Text('${payment.month} ${payment.year}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jatuh tempo: ${DateFormat('dd MMM yyyy').format(payment.dueDate)}',
            ),
            if (payment.paidDate != null)
              Text(
                'Dibayar: ${DateFormat('dd MMM yyyy').format(payment.paidDate!)}',
              ),
            if (payment.paymentMethod != null)
              Text('Metode: ${payment.paymentMethod}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(payment.amount),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              statusInfo['text'],
              style: TextStyle(
                color: statusInfo['color'],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

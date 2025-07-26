// lib/screens/payment/payment_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // <-- PERBAIKAN: Import ditambahkan
import 'package:sipatka/screens/payment/upload_proof_screen.dart';
import 'package:sipatka/utils/app_theme.dart';
import '../../providers/payment_provider.dart';
import '../../models/payment_model.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final List<Payment> _selectedPayments = [];
  double _totalSelectedAmount = 0.0;

  void _onPaymentSelected(bool? isSelected, Payment payment) {
    setState(() {
      if (isSelected == true) {
        _selectedPayments.add(payment);
      } else {
        _selectedPayments.remove(payment);
      }
      _totalSelectedAmount = _selectedPayments.fold(
        0.0,
        (sum, item) => sum + item.amount,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PaymentProvider>(
        builder: (context, paymentProvider, child) {
          if (paymentProvider.isLoading && paymentProvider.payments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final unpaidPayments =
              paymentProvider.payments
                  .where(
                    (p) =>
                        p.status == PaymentStatus.unpaid ||
                        p.status == PaymentStatus.overdue,
                  )
                  .toList();

          return Column(
            children: [
              // Tambahkan header agar lebih jelas
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.of(context).padding.top + 16,
                  16,
                  16,
                ),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: const Text(
                  'Pilih Tagihan untuk Dibayar',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child:
                    unpaidPayments.isEmpty
                        ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 80,
                                color: Colors.green,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Semua tagihan sudah lunas!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                        : RefreshIndicator(
                          onRefresh: () async {
                            // Kosongkan daftar pilihan dan reset totalnya terlebih dahulu
                            setState(() {
                              _selectedPayments.clear();
                              _totalSelectedAmount = 0.0;
                            });

                            // Kemudian, baru ambil data tagihan yang baru dari server
                            await context
                                .read<PaymentProvider>()
                                .fetchPayments();
                          },

                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              150,
                            ), // Padding bawah untuk tombol
                            itemCount: unpaidPayments.length,
                            itemBuilder: (context, index) {
                              final payment = unpaidPayments[index];
                              final isSelected = _selectedPayments.contains(
                                payment,
                              );
                              return _buildPaymentCard(
                                context,
                                payment,
                                isSelected,
                              );
                            },
                          ),
                        ),
              ),
            ],
          );
        },
      ),
      bottomSheet:
          _selectedPayments.isNotEmpty ? _buildPaymentButton(context) : null,
    );
  }

  Widget _buildPaymentCard(
    BuildContext context,
    Payment payment,
    bool isSelected,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
    );
    final isOverdue = payment.status == PaymentStatus.overdue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (bool? value) => _onPaymentSelected(value, payment),
        title: Text(
          '${payment.month} ${payment.year}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jatuh tempo: ${DateFormat('dd MMM yyyy').format(payment.dueDate)}',
            ),
          ],
        ),
        secondary: Text(
          currencyFormat.format(payment.amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isOverdue ? Colors.red : AppTheme.textPrimary,
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildPaymentButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(
        16,
      ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Dipilih (${_selectedPayments.length} bulan)',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp ',
                ).format(_totalSelectedAmount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _showPaymentDialog(context),
              child: const Text('Lanjutkan Pembayaran'),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => PaymentDialog(
            selectedPayments: _selectedPayments,
            totalAmount: _totalSelectedAmount,
            onPaymentSuccess: () {
              setState(() {
                _selectedPayments.clear();
                _totalSelectedAmount = 0.0;
              });
            },
          ),
    );
  }
}

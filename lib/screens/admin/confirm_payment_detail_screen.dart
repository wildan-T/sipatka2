// lib/screens/admin/confirm_payment_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/models/payment_model.dart';
import 'package:sipatka/providers/admin_provider.dart';
import 'package:sipatka/utils/app_theme.dart';
import 'package:sipatka/utils/error_dialog.dart';

class ConfirmPaymentDetailScreen extends StatefulWidget {
  final Payment payment;
  final String studentName;
  final String parentName;

  const ConfirmPaymentDetailScreen({
    super.key,
    required this.payment,
    required this.studentName,
    required this.parentName,
  });

  @override
  State<ConfirmPaymentDetailScreen> createState() =>
      _ConfirmPaymentDetailScreenState();
}

class _ConfirmPaymentDetailScreenState
    extends State<ConfirmPaymentDetailScreen> {
  final _rejectionReasonController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    setState(() => _isProcessing = true);
    try {
      final message = await context.read<AdminProvider>().confirmPayment(
        widget.payment.id,
      );
      if (mounted) {
        Navigator.pop(context, true); // Kirim sinyal sukses untuk refresh
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context: context,
          title: 'Konfirmasi Gagal',
          message:
              'Terjadi kesalahan saat mencoba mengonfirmasi pembayaran.\n\nDetail: $e',
        );
      }
    }
    if (mounted) setState(() => _isProcessing = false);
  }

  Future<void> _onReject() async {
    setState(() => _isProcessing = true);
    try {
      final message = await context.read<AdminProvider>().rejectPayment(
        widget.payment.id,
      ); // Panggil tanpa alasan
      if (mounted) {
        Navigator.pop(context, true); // Kirim sinyal sukses untuk refresh
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context: context,
          title: 'Penolakan Gagal',
          message:
              'Terjadi kesalahan saat mencoba menolak pembayaran.\n\nDetail: $e',
        );
      }
    }
    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Konfirmasi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- KARTU DETAIL PEMBAYARAN ---
            _buildDetailCard(
              currencyFormat.format(widget.payment.amount),
              widget.payment.month,
              widget.payment.year.toString(),
              widget.studentName,
              widget.parentName,
            ),

            const SizedBox(height: 24),

            // --- TAMPILAN BUKTI BAYAR ---
            const Text(
              'Bukti Pembayaran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (widget.payment.proofOfPaymentUrl != null &&
                widget.payment.proofOfPaymentUrl!.isNotEmpty)
              GestureDetector(
                onTap: () {
                  // Dialog untuk melihat gambar lebih besar
                  showDialog(
                    context: context,
                    builder:
                        (_) => Dialog(
                          child: InteractiveViewer(
                            child: Image.network(
                              widget.payment.proofOfPaymentUrl!,
                            ),
                          ),
                        ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.payment.proofOfPaymentUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder:
                        (ctx, child, progress) =>
                            progress == null
                                ? child
                                : const SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                    errorBuilder:
                        (ctx, err, st) => const SizedBox(
                          height: 200,
                          child: Center(
                            child: Text(
                              'Gagal memuat gambar.',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                  ),
                ),
              )
            else
              const Text('Tidak ada bukti pembayaran.'),

            const SizedBox(height: 20),
          ],
        ),
      ),
      // --- Tombol Aksi di Bawah ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(
          16.0,
        ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child:
            _isProcessing
                ? const Center(child: CircularProgressIndicator())
                : Row(
                  children: [
                    // Tombol Tolak
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.thumb_down_alt_outlined,
                          color: Colors.white,
                        ),
                        label: const Text('Tolak'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, // Warna ikon dan teks
                          backgroundColor:
                              Colors.red.shade600, // Warna latar belakang
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _onReject,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Tombol Konfirmasi
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.thumb_up_alt_outlined,
                          color: Colors.white,
                        ),
                        label: const Text('Konfirmasi'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, // Warna ikon dan teks
                          backgroundColor:
                              AppTheme.primaryColor, // Warna latar belakang
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _onConfirm,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
      ),
    );
  }

  // --- Widget Helper untuk Kartu Detail ---
  Widget _buildDetailCard(
    String amount,
    String month,
    String year,
    String studentName,
    String parentName,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jumlah Pembayaran',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.calendar_today,
              'Tagihan Bulan',
              '$month $year',
            ),
            _buildInfoRow(Icons.child_care, 'Siswa', studentName),
            _buildInfoRow(Icons.person, 'Wali Murid', parentName),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text('$label:'),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

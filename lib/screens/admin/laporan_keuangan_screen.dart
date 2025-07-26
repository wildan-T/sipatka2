// lib/screens/admin/laporan_keuangan_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sipatka/main.dart'; // Untuk akses client supabase
import 'package:sipatka/utils/app_theme.dart';
import 'package:sipatka/utils/pdf_generator.dart'; // Import file baru kita

class LaporanKeuanganScreen extends StatefulWidget {
  const LaporanKeuanganScreen({super.key});
  @override
  State<LaporanKeuanganScreen> createState() => _LaporanKeuanganScreenState();
}

class _LaporanKeuanganScreenState extends State<LaporanKeuanganScreen> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  Future<Map<String, dynamic>>? _reportFuture;
  Map<String, dynamic>? _lastReportData;

  @override
  void initState() {
    super.initState();
    _getReportData();
  }

  void _getReportData() {
    setState(() {
      _reportFuture = supabase
          .rpc(
            'get_financial_report',
            params: {
              'p_start_date': _startDate.toIso8601String(),
              'p_end_date': _endDate.toIso8601String(),
            },
          )
          .then((response) {
            final responseData = response as Map<String, dynamic>?;

            // Jika respons dari server adalah null, kita lempar error
            // yang akan ditangkap oleh FutureBuilder.
            if (responseData == null) {
              throw 'Tidak ada data yang dikembalikan dari server.';
            }

            // Simpan data ke _lastReportData
            _lastReportData = responseData;

            // Kembalikan data yang sudah pasti tidak null
            return responseData;
          });
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      _getReportData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        actions: [
          // Tombol Print/Export
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: "Print atau Export ke PDF",
            onPressed:
                (_lastReportData == null)
                    ? null
                    : () => PdfGenerator.generateAndPrintReport(
                      startDate: _startDate,
                      endDate: _endDate,
                      reportData: _lastReportData!,
                    ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateFilter(),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _reportFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Terjadi error: ${snapshot.error}"),
                  );
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                    child: Text("Tidak ada data untuk periode ini."),
                  );
                }

                final report = snapshot.data!;
                final double totalIncome =
                    (report['total_income'] as num?)?.toDouble() ?? 0.0;
                final transactions =
                    (report['transactions'] as List?)
                        ?.cast<Map<String, dynamic>>() ??
                    [];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(
                        title: 'Total Pendapatan (Sesuai Filter)',
                        value: NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                        ).format(totalIncome),
                        icon: Icons.account_balance_wallet_rounded,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Daftar Transaksi Lunas",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      if (transactions.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text("Tidak ada transaksi."),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionTile(transactions[index]);
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    return Card(
      margin: const EdgeInsets.all(16).copyWith(bottom: 0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: _buildDatePickerField("Dari Tanggal", _startDate, true),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDatePickerField("Sampai Tanggal", _endDate, false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerField(String label, DateTime date, bool isStart) {
    return InkWell(
      onTap: () => _selectDate(context, isStart),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18),
            const SizedBox(width: 8),
            Text(DateFormat('dd MMM yy', 'id_ID').format(date)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> transaction) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
    );
    final paidDate = DateTime.parse(transaction['paid_date']);
    final monthName = DateFormat(
      'MMMM',
      'id_ID',
    ).format(DateTime(transaction['year'], transaction['month']));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.receipt_long, color: AppTheme.primaryColor),
        title: Text(transaction['student_name'] ?? 'Siswa Dihapus'),
        subtitle: Text(
          "Tagihan: $monthName ${transaction['year']}\nDibayar pada: ${DateFormat('dd MMM yyyy').format(paidDate)}",
        ),
        isThreeLine: true,
        trailing: Text(
          currencyFormat.format(transaction['amount']),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// lib/utils/pdf_generator.dart

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfGenerator {
  static Future<void> generateAndPrintReport({
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> reportData,
  }) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
    );

    // Load logo dari assets
    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/logo.jpg')).buffer.asUint8List(),
    );

    // Ambil data dari Map
    final totalIncome = reportData['total_income'] ?? 0;
    final totalTransactions = reportData['total_transactions'] ?? 0;
    final transactions =
        (reportData['transactions'] as List?)?.cast<Map<String, dynamic>>() ??
        [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader(logoImage, startDate, endDate),
        footer: (context) => _buildFooter(context),
        build:
            (context) => [
              _buildSummary(
                currencyFormat.format(totalIncome),
                totalTransactions.toString(),
              ),
              pw.SizedBox(height: 20),
              _buildTransactionTable(transactions, currencyFormat),
            ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildHeader(
    pw.MemoryImage logo,
    DateTime start,
    DateTime end,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 15),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Image(logo, width: 50, height: 50),
              pw.SizedBox(width: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Laporan Keuangan',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'TK AN-NAAFI\'NUR',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Periode Laporan'),
              pw.Text(
                '${DateFormat('dd MMM yyyy').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummary(String totalIncome, String totalTransactions) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          pw.Column(
            children: [
              pw.Text('Total Pendapatan'),
              pw.Text(
                totalIncome,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          pw.Column(
            children: [
              pw.Text('Jumlah Transaksi'),
              pw.Text(
                totalTransactions,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTransactionTable(
    List<Map<String, dynamic>> transactions,
    NumberFormat currencyFormat,
  ) {
    final headers = ['Tanggal Bayar', 'Siswa', 'Tagihan Bulan', 'Jumlah'];

    final data =
        transactions.map((tx) {
          final monthName = DateFormat(
            'MMMM',
            'id_ID',
          ).format(DateTime(tx['year'], tx['month']));
          return [
            DateFormat('dd-MM-yyyy').format(DateTime.parse(tx['paid_date'])),
            tx['student_name'],
            '$monthName ${tx['year']}',
            currencyFormat.format(tx['amount']),
          ];
        }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Halaman ${context.pageNumber} dari ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
      ),
    );
  }
}

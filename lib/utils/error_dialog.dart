// lib/utils/error_dialog.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Fungsi ini akan menjadi satu-satunya cara kita menampilkan error di aplikasi
void showErrorDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? errorDetail, // Parameter opsional untuk detail teknis
}) {
  showDialog(
    context: context,
    builder: (context) {
      // Tentukan pesan yang akan ditampilkan
      String displayMessage = message;

      // Jika BUKAN mode rilis (yaitu mode debug) dan ada detail error,
      // tampilkan detailnya untuk membantu proses debugging.
      if (!kReleaseMode && errorDetail != null) {
        displayMessage += '\n\nDetail: $errorDetail';
      }

      return AlertDialog(
        // Gunakan ikon yang sesuai untuk error
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        // Tampilkan pesan error yang diterima
        content: Text(displayMessage),
        actions: [
          // Tombol untuk menutup dialog
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      );
    },
  );
}

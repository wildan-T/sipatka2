// lib/utils/error_dialog.dart

import 'package:flutter/material.dart';

// Fungsi ini akan menjadi satu-satunya cara kita menampilkan error di aplikasi
void showErrorDialog({
  required BuildContext context,
  required String title,
  required String message,
}) {
  showDialog(
    context: context,
    builder: (context) {
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
        content: Text(message),
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

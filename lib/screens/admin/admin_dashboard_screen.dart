import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/providers/auth_provider.dart';
import 'package:sipatka/providers/notification_provider.dart';
import 'package:sipatka/screens/admin/manage_students_screen.dart';
import 'package:sipatka/screens/admin/confirm_payments_screen.dart';
import 'package:sipatka/screens/admin/laporan_keuangan_screen.dart';
import 'package:sipatka/screens/admin/admin_register_screen.dart';
import 'package:sipatka/utils/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notification, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: "Keluar",
                onPressed: () => _showLogoutDialog(context),
              ),
            ],
          ),
          body: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(16),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildMenuCard(
                context,
                title: 'Manajemen Siswa & Pesan',
                icon: Icons.people_outline,
                // Tampilkan notifikasi jika ada pesan baru
                hasNotification: notification.hasAnyUnreadMessages,
                onTap: () {
                  // Hapus notifikasi saat halaman dibuka
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageStudentsScreen(),
                    ),
                  );
                },
              ),
              _buildMenuCard(
                context,
                title: 'Konfirmasi Pembayaran',
                icon: Icons.check_circle_outline,
                // Tampilkan notifikasi jika ada pembayaran baru
                hasNotification: notification.hasNewPayment,
                onTap: () {
                  // Hapus notifikasi saat halaman dibuka
                  notification.clearPaymentNotification();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConfirmPaymentsScreen(),
                    ),
                  );
                },
              ),
              _buildMenuCard(
                context,
                title: 'Laporan Keuangan',
                icon: Icons.bar_chart_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LaporanKeuanganScreen(),
                    ),
                  );
                },
              ),
              _buildMenuCard(
                context,
                title: 'Registrasi Akun Siswa',
                icon: Icons.person_add_alt_1_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminRegisterScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Keluar'),
            content: const Text('Apakah Anda yakin ingin keluar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  }
                },
                child: const Text(
                  'Keluar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool hasNotification = false, // Tambahkan parameter ini
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          // Gunakan Stack untuk menumpuk ikon notifikasi
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 50, color: Theme.of(context).primaryColor),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            // Tampilkan titik merah jika ada notifikasi
            if (hasNotification)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

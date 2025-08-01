import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/providers/auth_provider.dart';
import 'package:sipatka/providers/payment_provider.dart';
import 'home_tab.dart';
import '../payment/payment_screen.dart';
import '../payment/history_screen.dart';
import '../school/school_info_screen.dart';
import '../communication/chat_screen.dart';
import 'package:sipatka/providers/notification_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // Tambahkan observer untuk lifecycle
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      // Sync timestamp saat pertama kali buka app
      await notifProvider.syncInitialTimestamps();
      // Fetch payments
      Provider.of<PaymentProvider>(context, listen: false).fetchPayments();
    });
  }

  @override
  void dispose() {
    // Hapus observer saat dispose
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Ketika app kembali ke foreground dari background
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final notifProvider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );

        // Refresh timestamp untuk mencegah notifikasi palsu
        await notifProvider.refreshTimestamps();

        // Sync ulang timestamp untuk memastikan konsistensi
        await notifProvider.syncInitialTimestamps();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeTab(),
      const PaymentScreen(),
      const HistoryScreen(),
      const SchoolInfoScreen(),
      const ChatScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SIPATKA'),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.account_circle),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout, color: Colors.red),
                      title: Text('Keluar'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: pages,
      ),
      bottomNavigationBar: Consumer<NotificationProvider>(
        builder: (context, notification, child) {
          return BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: (index) {
              // Hapus notifikasi saat tab yang relevan diklik
              if (index == 2) {
                // Index 2 adalah 'Riwayat'
                notification.clearPaymentStatusUpdateNotification();
              }
              if (index == 4) {
                // Index 4 adalah 'Chat'
                notification.clearAdminMessageNotification();
              }
              setState(() => _currentIndex = index);
              _pageController.jumpToPage(index);
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Beranda',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.payment),
                label: 'Bayar',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  // Gunakan Badge di sini
                  isLabelVisible: notification.hasPaymentStatusUpdate,
                  child: const Icon(Icons.history),
                ),
                label: 'Riwayat',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.school),
                label: 'Sekolah',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  // <-- Tambahkan Badge di sini
                  isLabelVisible: notification.hasNewAdminMessage,
                  child: const Icon(Icons.chat),
                ),
                label: 'Chat',
              ),
            ],
          );
        },
      ),
    );
  }

  void _logout() {
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
                  if (mounted) {
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
}

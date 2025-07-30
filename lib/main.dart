import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/providers/notification_provider.dart';
import 'package:sipatka/screens/profile/change_password_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sipatka/providers/admin_provider.dart';
import 'package:sipatka/providers/auth_provider.dart';
import 'package:sipatka/providers/payment_provider.dart';
import 'package:sipatka/screens/admin/admin_dashboard_screen.dart';
import 'package:sipatka/screens/auth/login_screen.dart';
import 'package:sipatka/screens/home/dashboard_screen.dart';
import 'package:sipatka/screens/splash_screen.dart';
import 'package:sipatka/utils/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final supabase = Supabase.instance.client;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale untuk format tanggal dan mata uang Indonesia
  await initializeDateFormatting('id_ID', null);

  await dotenv.load(fileName: ".env");

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create:
              (context) => NotificationProvider(context.read<AuthProvider>()),
          update: (context, auth, previous) => NotificationProvider(auth),
        ),
        // ChangeNotifierProxyProvider2<
        //   AuthProvider,
        //   PaymentProvider,
        //   NotificationProvider
        // >(
        //   create:
        //       (context) => NotificationProvider(
        //         context.read<AuthProvider>(),
        //         context.read<PaymentProvider>(),
        //       ),
        //   update:
        //       (context, auth, payment, previous) =>
        //           NotificationProvider(auth, payment),
        // ),
      ],
      child: MaterialApp(
        title: 'SIPATKA',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/admin_dashboard': (context) => const AdminDashboardScreen(),
          '/change-password': (context) => const ChangePasswordScreen(),
        },
      ),
    );
  }
}

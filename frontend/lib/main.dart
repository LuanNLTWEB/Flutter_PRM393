import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/admin/presentation/providers/admin_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/review/presentation/providers/review_provider.dart';
import 'features/quotations/presentation/providers/quotation_provider.dart';
import 'features/repair_request/presentation/providers/repair_request_provider.dart';
import 'features/technician/presentation/providers/technician_provider.dart';
import 'features/order_history/presentation/providers/order_history_provider.dart';
import 'features/completion/presentation/providers/completion_provider.dart';
import 'features/payment/presentation/providers/payment_provider.dart';
import 'features/notification/presentation/providers/notification_provider.dart';
import 'features/notification/services/local_notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(
          create: (_) => ReviewProvider()
            ..loadTechnicians()
            ..loadTags(),
        ),
        ChangeNotifierProvider(create: (_) => TechnicianProvider()),
        ChangeNotifierProvider(create: (_) => RepairRequestProvider()),
        ChangeNotifierProvider(create: (_) => OrderHistoryProvider()),
        ChangeNotifierProvider(create: (_) => QuotationProvider()),
        ChangeNotifierProvider(create: (_) => CompletionProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],

      child: MaterialApp(
        title: 'HomeFix',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorKey: LocalNotificationService.navigatorKey,
        home: const HomeScreen(),
      ),
    );
  }
}

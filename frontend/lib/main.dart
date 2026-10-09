import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/presentation/providers/admin_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/review/presentation/providers/review_provider.dart';
import 'features/repair_request/presentation/providers/repair_request_provider.dart';
import 'features/technician/presentation/providers/technician_provider.dart';

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
        ChangeNotifierProvider(create: (_) => ReviewProvider()..loadTechnicians()..loadTags()),
        ChangeNotifierProvider(create: (_) => TechnicianProvider()),
        ChangeNotifierProvider(create: (_) => RepairRequestProvider()),
      ],

      child: MaterialApp(
        title: 'HomeFix',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }
}

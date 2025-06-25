import 'package:flutter/material.dart';
import 'package:kreisel_frontend/pages/login_page.dart';
import 'package:kreisel_frontend/services/admin_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize admin service
  if (await AdminService.hasAdminToken()) {
    if (!await AdminService.verifyAdminAccess()) {
      await AdminService.logout();
    }
  }

  runApp(KreiselApp());
}

class KreiselApp extends StatelessWidget {
  const KreiselApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HM Sportsgear',
      theme: ThemeData.dark().copyWith(
        primaryColor: Color(0xFF007AFF),
        scaffoldBackgroundColor: Colors.black,
        cardColor: Color(0xFF1C1C1E),
        dividerColor: Color(0xFF38383A),
        // Add these to ensure text is visible
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
        ),
      ),
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

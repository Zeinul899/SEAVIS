import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'pages/seavis_landing_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SeavisApp());
}

class SeavisApp extends StatelessWidget {
  const SeavisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SEAVIS - Portal Nelayan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SeaVisLandingPage(),
    );
  }
}

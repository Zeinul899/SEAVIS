import 'package:flutter/material.dart';
import 'screens/report_wizard_screen.dart';
import 'screens/realtime_carbon_map_screen.dart';
import 'screens/esp32_water_checker_screen.dart';
import 'screens/sheets_history_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SeagrassGuardApp());
}

class SeagrassGuardApp extends StatelessWidget {
  const SeagrassGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seagrass Guard (SEAVIS)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F4C81),
          primary: const Color(0xFF0F4C81),
          secondary: const Color(0xFF059669),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF0F4C81), width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _activeTabIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      ReportWizardScreen(
        onReportSubmitted: () {
          setState(() {
            _activeTabIndex = 3; // Pindah ke tab Riwayat Data Sheets saat berhasil
          });
        },
      ),
      const RealtimeCarbonMapScreen(),
      const Esp32WaterCheckerScreen(),
      const SheetsHistoryScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _activeTabIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: BottomNavigationBar(
          currentIndex: _activeTabIndex,
          onTap: (index) {
            setState(() {
              _activeTabIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0F4C81),
          unselectedItemColor: const Color(0xFF64748B),
          selectedFontSize: 10,
          unselectedFontSize: 10,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.add_photo_alternate_outlined),
              activeIcon: Icon(Icons.add_photo_alternate_rounded),
              label: 'Lapor Lamun',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map_rounded),
              label: 'Real-Time Maps',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sensors_outlined),
              activeIcon: Icon(Icons.sensors_rounded),
              label: 'ESP32 Air & C',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.table_chart_outlined),
              activeIcon: Icon(Icons.table_chart_rounded),
              label: 'Data Sheets',
            ),
          ],
        ),
      ),
    );
  }
}

// Alias SeavisApp untuk kompatibilitas smoke test lama
typedef SeavisApp = SeagrassGuardApp;

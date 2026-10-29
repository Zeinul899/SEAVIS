import 'package:flutter_test/flutter_test.dart';
import 'package:seavis/main.dart';

void main() {
  testWidgets('Seagrass Guard (SEAVIS) smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SeagrassGuardApp());
    await tester.pumpAndSettle();

    // Pastikan 4 tab navigasi utama Seagrass Guard tampil
    expect(find.text('Lapor Lamun'), findsOneWidget);
    expect(find.text('Real-Time Maps'), findsOneWidget);
    expect(find.text('ESP32 Air & C'), findsOneWidget);
    expect(find.text('Data Sheets'), findsOneWidget);

    // Pastikan tahap 1 stepper pelaporan nelayan aktif
    expect(find.text('Tahap 1: Foto Lamun & Info Pantai'), findsOneWidget);
  });
}

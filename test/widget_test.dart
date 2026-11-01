import 'package:flutter_test/flutter_test.dart';
import 'package:seavis/main.dart';

void main() {
  testWidgets('SEAVIS Simple Transparent Login Page smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SeagrassGuardApp());
    await tester.pumpAndSettle();

    // 1. Verifikasi Header Brand & UI Kaca Transparan
    expect(find.text('SEAVIS'), findsOneWidget);
    expect(find.text('Portal Nelayan & Observasi Laut'), findsOneWidget);

    // 2. Verifikasi Tab Masuk & Buat Akun
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Buat Akun'), findsOneWidget);

    // 3. Verifikasi Tombol Masuk Awal
    expect(find.text('Masuk ke SeaVis'), findsOneWidget);

    // 4. Uji perpindahan ke Tab Buat Akun
    await tester.tap(find.text('Buat Akun'));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Akun ke Database'), findsOneWidget);
    expect(find.text('Nama Lengkap Nelayan'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:seavis/main.dart';
import 'package:seavis/services/network_service.dart';

void main() {
  setUp(() {
    NetworkService.setMockStatus(true);
  });

  tearDown(() {
    NetworkService.setMockStatus(null);
  });

  testWidgets('SEAVIS Simple Transparent Login Page smoke test (Logo removed, Real Network)',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SeagrassGuardApp());
    await tester.pumpAndSettle();

    // 1. Verifikasi Logo SeaVis telah dihapus sesuai permintaan
    expect(find.text('Portal Nelayan & Observasi Laut'), findsNothing);

    // 2. Verifikasi Indikator Koneksi Riil
    expect(find.textContaining('Online'), findsWidgets);

    // 3. Verifikasi Tab Masuk & Buat Akun
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Buat Akun'), findsOneWidget);

    // 4. Verifikasi Tombol Masuk Awal
    expect(find.text('Masuk ke SeaVis'), findsOneWidget);

    // 5. Uji perpindahan ke Tab Buat Akun
    await tester.tap(find.text('Buat Akun'));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Akun ke Database'), findsOneWidget);
    expect(find.text('Nama Lengkap Nelayan'), findsOneWidget);
  });
}

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

  testWidgets('SEAVIS Login Page smoke test (Title, Tagline, Labels & Hints)',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SeagrassGuardApp());
    await tester.pumpAndSettle();

    // 1. Verifikasi Judul & Tagline di Luar Card
    expect(find.text('Mulailah Bersama SeaVis'), findsOneWidget);
    expect(find.text('Sistem Monitoring Ekosistem Lamun & Karbon Biru Pesisir'), findsOneWidget);

    // 2. Verifikasi Indikator Koneksi Riil
    expect(find.textContaining('Online'), findsWidgets);

    // 3. Verifikasi Tab Masuk & Buat Akun
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Buat Akun'), findsOneWidget);

    // 4. Verifikasi Label & Hint Input Kolom 1 & 2
    expect(find.text('Email Nelayan / ID Pengguna atau Nomor HP / Email'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('contoh: nelayan@seavis.id atau 08xxxxxxxxxx'), findsOneWidget);
    expect(find.text('Masukkan kata sandi akun'), findsOneWidget);

    // 5. Verifikasi Tombol Masuk Awal
    expect(find.text('Masuk ke SeaVis'), findsOneWidget);

    // 6. Uji perpindahan ke Tab Buat Akun
    await tester.tap(find.text('Buat Akun'));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Akun ke Database'), findsOneWidget);
    expect(find.text('Nama Lengkap Nelayan'), findsOneWidget);
  });
}

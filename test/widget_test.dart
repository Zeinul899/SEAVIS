import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seavis/main.dart';
import 'package:seavis/models/user_model.dart';
import 'package:seavis/pages/profile_page.dart';
import 'package:seavis/pages/seavis_landing_page.dart';
import 'package:seavis/services/network_service.dart';

void main() {
  setUp(() {
    NetworkService.setMockStatus(true);
  });

  tearDown(() {
    NetworkService.setMockStatus(null);
  });

  testWidgets('SEAVIS Login Page smoke test (Title, Tagline, Labels & Password Guidance)',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SeagrassGuardApp());
    await tester.pumpAndSettle();

    // 1. Verifikasi Judul & Tagline di Luar Card
    expect(find.text('Mulailah Bersama SeaVis'), findsOneWidget);
    expect(find.text('Sistem Monitoring Ekosistem Lamun & Karbon Biru Pesisir'), findsOneWidget);

    // 2. Verifikasi Indikator Tulisan Online Dihapus Sesuai Permintaan
    expect(find.textContaining('Online (Terhubung)'), findsNothing);

    // 3. Verifikasi Tab Masuk & Buat Akun
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Buat Akun'), findsOneWidget);

    // 4. Verifikasi Label & Hint Input Kolom 1 & 2
    expect(find.text('Email Nelayan / ID Pengguna atau Nomor HP / Email'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('contoh: nelayan@seavis.id atau 08xxxxxxxxxx'), findsOneWidget);
    expect(find.text('Masukkan kata sandi akun'), findsOneWidget);

    // 5. Uji perpindahan ke Tab Buat Akun & Panduan Password
    await tester.tap(find.text('Buat Akun'));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Akun ke Database'), findsOneWidget);
    expect(find.text('Panduan Kata Sandi Aman:'), findsOneWidget);
    expect(find.text('Minimal 8 karakter'), findsOneWidget);
    expect(find.text('Mengandung huruf besar (A-Z)'), findsOneWidget);
  });

  testWidgets('SEAVIS Dashboard Landing Page matches Canva wireframe (Greeting, Saldo, Cash Out, Tata Cara)',
      (WidgetTester tester) async {
    const testUser = UserModel(
      name: 'Pak Anto',
      email: 'Anto@mail.com',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: SeaVisLandingPage(user: testUser),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verifikasi Header Profil (Nama & Email sesuai login)
    expect(find.textContaining('Pak Anto'), findsWidgets);
    expect(find.text('Email: Anto@mail.com'), findsOneWidget);

    // 2. Verifikasi Banner Saldo & Tombol Cash Out
    expect(find.text('Rp 540.000'), findsOneWidget);
    expect(find.text('Cash Out'), findsOneWidget);

    // 3. Verifikasi Card Upload Foto Padang Lamun & Tata Cara
    expect(find.text('Upload Foto Padang Lamun'), findsOneWidget);
    expect(find.text('Tata Cara Pengambilan Foto yang Benar:'), findsOneWidget);
    expect(find.text('Rp 25.000 / Foto'), findsOneWidget);
    expect(find.text('Ambil Foto Lamun Sekarang'), findsOneWidget);
  });

  testWidgets('SEAVIS Profile Page shows complete partnership info & duration',
      (WidgetTester tester) async {
    const testUser = UserModel(
      name: 'Pak Anto',
      email: 'Anto@mail.com',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfilePage(user: testUser, currentBalance: 540000),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verifikasi Data Nelayan
    expect(find.text('Pak Anto'), findsOneWidget);
    expect(find.text('Email: Anto@mail.com'), findsOneWidget);

    // 2. Verifikasi Lama Kerja Sama & Kemitraan
    expect(find.text('Lama Kerja Sama'), findsOneWidget);
    expect(find.textContaining('1 Tahun 4 Bulan'), findsOneWidget);
    expect(find.text('SV-NL-2025-0849'), findsOneWidget);

    // 3. Verifikasi Saldo & Rekening Pencairan
    expect(find.text('Rp 540.000'), findsOneWidget);
    expect(find.text('Bank BRI'), findsOneWidget);
    expect(find.text('E-Wallet DANA'), findsOneWidget);
  });
}

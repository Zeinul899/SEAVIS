import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:seavis/main.dart';
import 'package:seavis/models/user_model.dart';
import 'package:seavis/pages/profile_page.dart';
import 'package:seavis/pages/seavis_landing_page.dart';
import 'package:seavis/screens/esp32_water_checker_screen.dart';
import 'package:seavis/screens/realtime_carbon_map_screen.dart';
import 'package:seavis/services/esp32_support_service.dart';
import 'package:seavis/services/location_map_service.dart';
import 'package:seavis/services/network_service.dart';

void main() {
  setUp(() {
    NetworkService.setMockStatus(true);
    LocationMapService.mockPosition = Position(
      latitude: -6.5528,
      longitude: 110.6508,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  });

  tearDown(() {
    NetworkService.setMockStatus(null);
    LocationMapService.mockPosition = null;
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

  testWidgets('SEAVIS Dashboard Landing Page matches reference design (Profile Card, Map, GPS, Guidelines, Photo/AI Cards & Bottom Nav)',
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

    // 1. Verifikasi Header Profil Card (Role, Nama, Email, Status Online, Saldo, Sisa Kuota)
    expect(find.text('FIELD SURVEYOR'), findsOneWidget);
    expect(find.text('PAK ANTO'), findsOneWidget);
    expect(find.text('Anto@mail.com'), findsOneWidget);
    expect(find.text('ONLINE'), findsOneWidget);
    expect(find.text('Hari Pertama'), findsOneWidget);
    expect(find.text('SALDO SURVEYOR'), findsOneWidget);
    expect(find.text('Rp 540.000'), findsOneWidget);
    expect(find.text('SISA KUOTA HARI INI'), findsOneWidget);
    expect(find.text('Tanggal Tugas: 30 Mei 2026'), findsOneWidget);

    // 2. Verifikasi Live Coastal Map Card
    expect(find.text('LIVE COASTAL MAP'), findsOneWidget);
    expect(find.text('Click to view seagrass distribution area'), findsOneWidget);

    // 3. Verifikasi GPS Coordinate Card
    expect(find.textContaining('X8GH+6Q8, Parangtritis'), findsOneWidget);

    // 4. Verifikasi Panduan 4 Sudut Foto (Angle)
    expect(find.text('PANDUAN 4 SUDUT FOTO (ANGLE)'), findsOneWidget);
    expect(find.textContaining('1. Atas (Tegak lurus menghadap objek)'), findsOneWidget);

    // 5. Verifikasi Dual Action Cards: Ambil Foto 1 & AI Scan Result
    expect(find.text('Ambil Foto 1: Tampak Atas'), findsOneWidget);
    expect(find.text('AI SCAN RESULT:'), findsOneWidget);
    expect(find.text('Belum ada foto'), findsOneWidget);

    // 6. Verifikasi Conservation Gallery & Bottom Navigation Bar
    expect(find.text('CONSERVATION GALLERY'), findsOneWidget);
    expect(find.text('SEAGRASS GUARD v1.0'), findsOneWidget);
    expect(find.text('Form'), findsOneWidget);
    expect(find.text('Saldo'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('AI Chat'), findsOneWidget);
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

  testWidgets('SEAVIS Live Coastal Map renders Indonesian Archipelago & Real Seagrass Sites',
      (WidgetTester tester) async {
    RealtimeCarbonMapScreen.enableInfiniteAnimation = false;

    // 1. Verifikasi Database Sebaran Padang Lamun Nasional Valid (Bukan Simulasi)
    expect(LocationMapService.verifiedIndonesianSites.length, 17);
    final jeparaSite = LocationMapService.verifiedIndonesianSites.first;
    expect(jeparaSite.name, 'Pantai Bandengan, Jepara');
    expect(jeparaSite.dominantSpecies, 'Enhalus acoroides');
    expect(jeparaSite.estimatedCarbonTonHa, 148.5);

    // 2. Render Screen RealtimeCarbonMapScreen
    await tester.pumpWidget(
      const MaterialApp(
        home: RealtimeCarbonMapScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 3. Verifikasi Header & Peta Indonesia Offline
    expect(find.text('Live Coastal Map Indonesia'), findsOneWidget);
    expect(find.text('Map Offline • Data Ilmiah BRIN / LIPI'), findsOneWidget);

    // 4. Verifikasi Filter Wilayah Kepulauan
    expect(find.textContaining('Seluruh Indonesia'), findsOneWidget);
    expect(find.textContaining('Jawa'), findsWidgets);

    // 5. Verifikasi Detail Card Padang Lamun Valid
    expect(find.text('Pantai Bandengan, Jepara'), findsWidgets);
    expect(find.text('ZONA KARBON TINGGI'), findsOneWidget);
    expect(find.text('Enhalus acoroides'), findsOneWidget);
    expect(find.textContaining('Pusat Riset Oseanografi BRIN'), findsOneWidget);
  });

  testWidgets('SEAVIS Photo Upload flow strictly enforces camera and blocks gallery',
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

    // Scroll sampai card Ambil Foto 1 terlihat
    await tester.ensureVisible(find.text('Ambil Foto 1: Tampak Atas'));
    await tester.pumpAndSettle();

    // Buka modal upload foto
    await tester.tap(find.text('Ambil Foto 1: Tampak Atas'));
    await tester.pumpAndSettle();

    // Verifikasi tombol Buka Kamera Langsung ada
    expect(find.text('Buka Kamera Langsung'), findsOneWidget);
    expect(find.text('Wajib foto real-time di pantai (Sudut 90° Tegak Lurus)'), findsOneWidget);

    // Verifikasi Galeri diblokir / dinonaktifkan
    expect(find.text('Galeri HP'), findsNothing);
    expect(find.textContaining('Akses Galeri Dinonaktifkan'), findsOneWidget);
  });

  testWidgets('SEAVIS ESP32 IoT Water Checker Connector & Full Screen Monitor works seamlessly',
      (WidgetTester tester) async {
    final esp32Service = Esp32SupportService();
    esp32Service.disconnectEsp32();

    const testUser = UserModel(
      name: 'Pak Anto',
      email: 'Anto@mail.com',
    );

    // 1. Render Landing Page dengan ESP32 Connector
    await tester.pumpWidget(
      const MaterialApp(
        home: SeaVisLandingPage(user: testUser),
      ),
    );
    await tester.pumpAndSettle();

    // Verifikasi Card ESP32 di Dashboard
    await tester.ensureVisible(find.text('ESP32 WATER CHECKER'));
    await tester.pumpAndSettle();
    expect(find.text('ESP32 WATER CHECKER'), findsOneWidget);
    expect(find.text('BLE AKTIF'), findsOneWidget);

    // 2. Hubungkan ESP32
    await tester.tap(find.text('Hubungkan').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();

    expect(find.text('TERHUBUNG'), findsOneWidget);
    expect(find.text('Putus'), findsOneWidget);
    expect(find.text('Suhu'), findsOneWidget);
    expect(find.text('pH'), findsOneWidget);

    // 3. Render Dedicated Screen Esp32WaterCheckerScreen
    await tester.pumpWidget(
      const MaterialApp(
        home: Esp32WaterCheckerScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cek Kualitas Air ESP32'), findsOneWidget);
    expect(find.textContaining('Suhu Air (DS18B20)'), findsOneWidget);
    expect(find.textContaining('Keasaman (pH)'), findsOneWidget);
    expect(find.textContaining('Salinitas / TDS'), findsOneWidget);
    expect(find.textContaining('Kekeruhan (Turbidity)'), findsOneWidget);
    expect(find.text('Indeks Karbon Perairan:'), findsOneWidget);
    expect(find.text('OPTIMAL'), findsOneWidget);

    esp32Service.disconnectEsp32();
  });

  testWidgets('SEAVIS Profile Page Cash Out flow handles presets and updates balance',
      (WidgetTester tester) async {
    const testUser = UserModel(
      name: 'Pak Anto',
      email: 'Anto@mail.com',
    );

    int updatedBalance = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ProfilePage(
          user: testUser,
          currentBalance: 540000,
          onBalanceUpdated: (newBal) {
            updatedBalance = newBal;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verifikasi Tombol Tarik Saldo
    expect(find.text('Tarik Saldo'), findsOneWidget);
    await tester.tap(find.text('Tarik Saldo'));
    await tester.pumpAndSettle();

    // 2. Verifikasi Modal Pencairan
    expect(find.text('Pencairan Saldo Insentif'), findsOneWidget);
    expect(find.text('Saldo Tersedia:'), findsOneWidget);
    expect(find.text('Rp 540.000'), findsWidgets);
    expect(find.text('Bank BRI'), findsWidgets);
    expect(find.text('E-Wallet DANA'), findsWidgets);

    // 3. Konfirmasi Pencairan Rp 50.000
    await tester.tap(find.text('Konfirmasi Tarik Saldo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    // Verifikasi Dialog Berhasil & Saldo Berkurang (540.000 - 50.000 = 490.000)
    expect(find.text('Pencairan Berhasil'), findsOneWidget);
    expect(updatedBalance, 490000);
  });
}

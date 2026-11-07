import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:seavis/main.dart';
import 'package:seavis/models/user_model.dart';
import 'package:seavis/pages/seavis_landing_page.dart';
import 'package:seavis/services/auth_service.dart';
import 'package:seavis/services/cloudinary_sheets_service.dart';
import 'package:seavis/services/esp32_support_service.dart';
import 'package:seavis/services/location_map_service.dart';
import 'package:seavis/services/network_service.dart';
import 'package:seavis/services/offline_sync_service.dart';

void main() {
  group('SEAVIS Security Audit & Penetration Test Suite', () {
    // -------------------------------------------------------------------------
    // TEST PENETRASI 1: PENGUJIAN INJEKSI SQL (SQLi) & XSS
    // -------------------------------------------------------------------------
    test('PEN-TEST 01: Sanitasi Vektor Serangan SQL Injection & XSS', () {
      final hostilePayloads = [
        "' OR '1'='1",
        "admin'--",
        "user'/*komentar*/",
        "<script>alert('xss')</script>budi@nelayan.id",
        "nelayan@laut.id\x00malicious",
        "javascript:alert(1)@domain.com",
      ];

      for (final payload in hostilePayloads) {
        final sanitized = AuthService.sanitizeInput(payload);

        // Pastikan null-bytes dieliminasi
        expect(sanitized.contains('\x00'), isFalse,
            reason: 'Null byte tidak boleh lolos');

        // Pastikan tag HTML / script dieliminasi
        expect(sanitized.contains('<script>'), isFalse,
            reason: 'Tag script wajib dibersihkan');

        // Pastikan komentar SQL berbahaya dibersihkan
        expect(sanitized.contains('--'), isFalse,
            reason: 'Komentar SQL -- wajib dibersihkan');
        expect(sanitized.contains('/*'), isFalse,
            reason: 'Komentar SQL /* wajib dibersihkan');
      }

      // Pastikan email dengan SQL injection langsung ditolak oleh validator email
      expect(AuthService.isValidEmail("' OR '1'='1"), isFalse);
      expect(AuthService.isValidEmail("admin'--@seavis.id"), isFalse);
    });

    // -------------------------------------------------------------------------
    // TEST PENETRASI 2: PENGUJIAN KEKUATAN & ENTROPI KATA SANDI
    // -------------------------------------------------------------------------
    test('PEN-TEST 02: Validasi Password Lemah vs Password Kuat (OWASP)', () {
      // Password lemah wajib ditolak
      expect(AuthService.validateStrongPassword('12345'), isNotNull,
          reason: 'Terlalu pendek');
      expect(AuthService.validateStrongPassword('hanyahurufkecil'), isNotNull,
          reason: 'Tidak ada huruf besar & angka');
      expect(AuthService.validateStrongPassword('HURUPBESARSEMUA'), isNotNull,
          reason: 'Tidak ada huruf kecil & angka');
      expect(AuthService.validateStrongPassword('TanpaAngkaDanSpesial'), isNotNull,
          reason: 'Tidak ada angka');

      // Password kuat wajib lolos
      expect(AuthService.validateStrongPassword('NelayanSeavis2026#'), isNull,
          reason: 'Password memenuhi kriteria kuat');
    });

    // -------------------------------------------------------------------------
    // TEST PENETRASI 3: PENGUJIAN INSECURE LOCAL STORAGE (Penyimpanan Offline)
    // -------------------------------------------------------------------------
    test('PEN-TEST 03: Keamanan Hash Kriptografis Salted HMAC-SHA256 di HP', () async {
      const testEmail1 = 'nelayan1@muarabaru.id';
      const testEmail2 = 'nelayan2@muarabaru.id';
      const sharedPassword = 'PasswordSama123#';

      // Daftarkan 2 akun dengan kata sandi yang sama persis
      final acc1 = await OfflineSyncService.saveAccountOffline(
        name: 'Nelayan Satu',
        email: testEmail1,
        password: sharedPassword,
      );

      final acc2 = await OfflineSyncService.saveAccountOffline(
        name: 'Nelayan Dua',
        email: testEmail2,
        password: sharedPassword,
      );

      // Verifikasi 1: Password TIDAK PERNAH disimpan sebagai plain-text
      expect(acc1.localEncryptedPassword?.contains(sharedPassword), isFalse);
      expect(acc2.localEncryptedPassword?.contains(sharedPassword), isFalse);

      // Verifikasi 2: Format menggunakan salted HMAC ($seavis-hmac$<salt>$<hash>)
      expect(acc1.localEncryptedPassword?.startsWith(r'$seavis-hmac$'), isTrue);
      expect(acc2.localEncryptedPassword?.startsWith(r'$seavis-hmac$'), isTrue);

      // Verifikasi 3: Kata sandi yang sama MENGHASILKAN HASH BERBEDA karena salt acak unik
      expect(acc1.localEncryptedPassword, isNot(equals(acc2.localEncryptedPassword)),
          reason: 'Salt kriptografis acak harus menghasilkan hash berbeda');

      // Verifikasi 4: Autentikasi offline berhasil dengan kata sandi yang benar
      final authSuccess = await OfflineSyncService.authenticateLocally(
        email: testEmail1,
        password: sharedPassword,
      );
      expect(authSuccess, isNotNull);
      expect(authSuccess?.email, equals(testEmail1));

      // Verifikasi 5: Autentikasi offline GAGAL dengan kata sandi salah
      final authFail = await OfflineSyncService.authenticateLocally(
        email: testEmail1,
        password: 'PasswordSalah999#',
      );
      expect(authFail, isNull);
    });

    // -------------------------------------------------------------------------
    // TEST PENETRASI 4: PENGUJIAN TIMING ATTACK MITIGATION
    // -------------------------------------------------------------------------
    test('PEN-TEST 04: Evaluasi Constant-Time String Comparison', () {
      const hashA = '9b73c66f316b0b2e35759ff5bb68c857755f70a1a51a8d1b11b5a5b512345678';
      const hashB = '9b73c66f316b0b2e35759ff5bb68c857755f70a1a51a8d1b11b5a5b512345678';
      const hashDiffFirstByte = '0b73c66f316b0b2e35759ff5bb68c857755f70a1a51a8d1b11b5a5b512345678';
      const hashDiffLastByte = '9b73c66f316b0b2e35759ff5bb68c857755f70a1a51a8d1b11b5a5b512345679';

      expect(AuthService.constantTimeEquals(hashA, hashB), isTrue);
      expect(AuthService.constantTimeEquals(hashA, hashDiffFirstByte), isFalse);
      expect(AuthService.constantTimeEquals(hashA, hashDiffLastByte), isFalse);
      expect(AuthService.constantTimeEquals(hashA, 'short'), isFalse);
    });

    // -------------------------------------------------------------------------
    // TEST PENETRASI 5: PENGUJIAN ANTI-USER ENUMERATION
    // -------------------------------------------------------------------------
    test('PEN-TEST 05: Pesan Kesalahan Netral Mencegah User Enumeration', () {
      // Pesan error tidak boleh membocorkan apakah email terdaftar atau tidak
      const genericMsg = AuthService.genericAuthErrorMessage;
      expect(genericMsg.contains('email tidak ditemukan'), isFalse);
      expect(genericMsg.contains('password salah'), isFalse);
      expect(genericMsg, equals('Email atau kata sandi yang Anda masukkan salah.'));
    });

    // -------------------------------------------------------------------------
    // TEST PENETRASI 6: PENGUJIAN SIMULASI SERANGAN BRUTE-FORCE PADA UI
    // -------------------------------------------------------------------------
    testWidgets('PEN-TEST 06: Simulasi Brute-Force Rate Limiting Lockout di UI',
        (WidgetTester tester) async {
      NetworkService.setMockStatus(false);
      addTearDown(() => NetworkService.setMockStatus(null));

      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const SeagrassGuardApp());
      await tester.pumpAndSettle();

      // Cari input email & password
      final emailFinder = find.byType(TextField).at(0);
      final passwordFinder = find.byType(TextField).at(1);
      final loginBtnFinder = find.byType(ElevatedButton);

      // Masukkan kredensial salah
      await tester.enterText(emailFinder, 'victim@seavis.id');
      await tester.enterText(passwordFinder, 'WrongPassword123#');
      await tester.pumpAndSettle();

      // Lakukan 5 kali percobaan gagal berturut-turut
      for (int i = 1; i <= 5; i++) {
        await tester.runAsync(() async {
          await tester.tap(loginBtnFinder);
          // Beri waktu bagi real file I/O dan delayed future
          await Future.delayed(const Duration(milliseconds: 650));
        });
        await tester.pump();
      }

      // Verifikasi: Tombol login harus beralih ke mode lockout "Terkunci"
      expect(find.textContaining('Terkunci'), findsOneWidget,
          reason: 'Mekanisme anti-brute force wajib mengunci form setelah 5 kali gagal');
    });

    // -------------------------------------------------------------------------
    // TEST PENETRASI 7: SIMULASI MANIPULASI INPUT FINANSIAL & UNDERFLOW (TARIK SALDO)
    // -------------------------------------------------------------------------
    test('PEN-TEST 07: Integritas Validasi Saldo & Anti-Tampering Finansial', () {
      const currentBalance = 540000;

      // Fungsi simulasi validasi nominal yang sama persis dengan UI
      bool isValidWithdrawal(String input, int balance) {
        final text = input.trim();
        if (!RegExp(r'^\d+$').hasMatch(text)) return false;
        final amount = int.tryParse(text) ?? 0;
        return amount >= 25000 && amount <= balance;
      }

      // Payload manipulasi nominal jahat
      final maliciousInputs = [
        "-50000",             // Nilai negatif
        "0",                  // Nilai nol
        "1000",               // Di bawah batas minimal 25.000
        "999999999",          // Melebihi saldo tersedia (Overdraw)
        "50000' OR '1'='1",   // SQL Injection pada field nominal
        "50000<script>",      // XSS injection
        "NaN",                // Not a Number
        "0xFF",               // Hexadecimal bypass attempt
        "1e10",               // Scientific notation
      ];

      for (final input in maliciousInputs) {
        final isAllowed = isValidWithdrawal(input, currentBalance);
        expect(isAllowed, isFalse,
            reason: 'Input manipulasi "$input" harus ditolak keras oleh sistem!');
      }

      // Input sah dalam batas saldo wajib diterima
      expect(isValidWithdrawal("50000", currentBalance), isTrue);
      expect(isValidWithdrawal("540000", currentBalance), isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST PENETRASI 8: VERIFIKASI PENEGAKAN KAMERA FISIK & BLOKIR AKSES GALERI
    // -------------------------------------------------------------------------
    testWidgets('PEN-TEST 08: Anti-Image Spoofing: Galeri HP Diblokir Total',
        (WidgetTester tester) async {
      const testUser = UserModel(name: 'Pak Anto', email: 'Anto@mail.com');

      await tester.pumpWidget(
        const MaterialApp(
          home: SeaVisLandingPage(user: testUser),
        ),
      );
      await tester.pumpAndSettle();

      // Buka modal upload
      await tester.ensureVisible(find.text('Ambil Foto 1: Tampak Atas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ambil Foto 1: Tampak Atas'));
      await tester.pumpAndSettle();

      // Pastikan tombol galeri tidak ada dan ada badge penegakan kamera
      expect(find.text('Pilih dari Galeri'), findsNothing,
          reason: 'Akses galeri wajib ditiadakan untuk mencegah foto rekayasa/spoofing');
      expect(find.textContaining('Akses Galeri Dinonaktifkan'), findsOneWidget);
      expect(find.text('Buka Kamera Langsung'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // TEST PENETRASI 9: VALIDASI BATAS MARITIM INDONESIA (ANTI-GPS SPOOFING)
    // -------------------------------------------------------------------------
    test('PEN-TEST 09: Mitigasi Serangan GPS Spoofing & Validasi Teritorial Maritim', () {
      // Koordinat sah dalam wilayah laut Indonesia
      expect(LocationMapService.isWithinIndonesianTerritory(-6.5528, 110.6508), isTrue,
          reason: 'Jepara, Jawa Tengah valid');
      expect(LocationMapService.isWithinIndonesianTerritory(-8.7523, 115.2215), isTrue,
          reason: 'Tanjung Benoa, Bali valid');
      expect(LocationMapService.isWithinIndonesianTerritory(-1.8894, 130.1583), isTrue,
          reason: 'Raja Ampat, Papua valid');

      // Koordinat palsu / spoofing di luar batas laut Indonesia
      expect(LocationMapService.isWithinIndonesianTerritory(35.6762, 139.6503), isFalse,
          reason: 'Tokyo, Jepang di luar wilayah');
      expect(LocationMapService.isWithinIndonesianTerritory(51.5074, -0.1278), isFalse,
          reason: 'London, UK di luar wilayah');
      expect(LocationMapService.isWithinIndonesianTerritory(999.0, 999.0), isFalse,
          reason: 'Koordinat overflow tidak valid');
      expect(LocationMapService.isWithinIndonesianTerritory(-90.0, 0.0), isFalse,
          reason: 'Kutub Selatan di luar wilayah');
    });

    // -------------------------------------------------------------------------
    // TEST PENETRASI 10: TRANSPORT SECURITY & ENFORCE HTTPS (ANTI-MITM)
    // -------------------------------------------------------------------------
    test('PEN-TEST 10: Penegakan Enkripsi Transport HTTPS (Anti-Cleartext HTTP Downgrade)', () {
      // Endpoint yang sah menggunakan HTTPS
      expect(CloudinarySheetsService.isSecureEndpoint('https://script.google.com/macros/s/exec'), isTrue);
      expect(CloudinarySheetsService.isSecureEndpoint('https://api.cloudinary.com/v1_1/seagrass/upload'), isTrue);

      // Endpoint tidak aman tanpa enkripsi wajib ditolak
      expect(CloudinarySheetsService.isSecureEndpoint('http://script.google.com/macros/s/exec'), isFalse,
          reason: 'Cleartext HTTP wajib ditolak');
      expect(CloudinarySheetsService.isSecureEndpoint('http://insecure-backend.com/api'), isFalse,
          reason: 'Cleartext HTTP wajib ditolak');
      expect(CloudinarySheetsService.isSecureEndpoint('ftp://malicious.org/payload'), isFalse,
          reason: 'Protokol non-HTTPS wajib ditolak');
    });

    // -------------------------------------------------------------------------
    // TEST PENETRASI 11: FUZZING & ANOMALI SENSOR ESP32 (OUT-OF-BOUNDS TELEMETRY)
    // -------------------------------------------------------------------------
    test('PEN-TEST 11: Fuzzing Validasi Data Sensor IoT ESP32 (Anti-Corrupted Data)', () {
      // Pembacaan fisik yang normal dan sah
      expect(
        Esp32SupportService.isValidSensorReading(
          waterTempC: 28.5,
          ph: 8.1,
          tdsPpm: 345,
          turbidityNtu: 3.4,
        ),
        isTrue,
      );

      // Fuzzing 1: pH di luar skala asam-basa alami (skala 0 - 14)
      expect(Esp32SupportService.isValidSensorReading(ph: -1.0), isFalse);
      expect(Esp32SupportService.isValidSensorReading(ph: 15.5), isFalse);
      expect(Esp32SupportService.isValidSensorReading(ph: double.nan), isFalse);

      // Fuzzing 2: Suhu air laut ekstrem yang tidak mungkin
      expect(Esp32SupportService.isValidSensorReading(waterTempC: -50.0), isFalse);
      expect(Esp32SupportService.isValidSensorReading(waterTempC: 150.0), isFalse);

      // Fuzzing 3: TDS & Turbidity negatif atau tak terhingga
      expect(Esp32SupportService.isValidSensorReading(tdsPpm: -100), isFalse);
      expect(Esp32SupportService.isValidSensorReading(turbidityNtu: -5.0), isFalse);
      expect(Esp32SupportService.isValidSensorReading(turbidityNtu: double.infinity), isFalse);
    });
  });
}

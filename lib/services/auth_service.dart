import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Model hasil autentikasi yang aman untuk UI layer
class AuthResponse {
  final bool isSuccess;
  final String? message;
  final String? token;
  final Map<String, dynamic>? userData;

  const AuthResponse({
    required this.isSuccess,
    this.message,
    this.token,
    this.userData,
  });

  factory AuthResponse.success({
    String? token,
    Map<String, dynamic>? userData,
    String? message,
  }) {
    return AuthResponse(
      isSuccess: true,
      token: token,
      userData: userData,
      message: message ?? 'Login berhasil',
    );
  }

  factory AuthResponse.failure(String message) {
    return AuthResponse(
      isSuccess: false,
      message: message,
    );
  }
}

/// Service Keamanan & Autentikasi Standar OWASP Mobile Top 10
class AuthService {
  // Timeout proteksi agar request tidak menggantung tanpa batas
  static const Duration requestTimeout = Duration(seconds: 15);

  /// Pesan error umum untuk mencegah serangan User Enumeration
  static const String genericAuthErrorMessage =
      'Email atau kata sandi yang Anda masukkan salah.';

  /// --------------------------------------------------------------------------
  /// 1. SANITASI INPUT & PENCEGAHAN SQL INJECTION / XSS
  /// --------------------------------------------------------------------------
  /// Menghapus karakter kontrol berbahaya, tag HTML/Script, dan pola SQLi umum
  static String sanitizeInput(String input) {
    var sanitized = input.trim();
    // Hilangkan null bytes
    sanitized = sanitized.replaceAll('\x00', '');
    // Netralkan tag HTML / Script sederhana
    sanitized = sanitized
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '');
    // Netralkan pola komentar SQL berbahaya di akhir string
    sanitized = sanitized.replaceAll(RegExp(r"(--|#|/\*|\*/)"), '');
    return sanitized;
  }

  /// Validasi format email menggunakan Regex standar RFC 5322
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  /// --------------------------------------------------------------------------
  /// 2. HASHING KRIPTOGRAFIS (SHA-256 + Per-User Salt + Constant-Time Comparison)
  /// --------------------------------------------------------------------------
  /// Mencegah reverse-engineering dari memori penyimpanan lokal HP
  static String generateCryptographicSalt([int length = 16]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64UrlEncode(values);
  }

  /// Membuat hash kata sandi menggunakan HMAC-SHA256 dengan salt unik
  static String hashPassword(String password, String salt) {
    final key = utf8.encode(salt);
    final bytes = utf8.encode(password);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  /// Verifikasi perbandingan string konstan (Constant-Time)
  /// Memitigasi serangan Timing Side-Channel Attack
  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// --------------------------------------------------------------------------
  /// 3. VALIDASI KEKUATAN KATA SANDI
  /// --------------------------------------------------------------------------
  static bool hasMinLength(String password) => password.length >= 8;
  static bool hasUppercase(String password) => RegExp(r'[A-Z]').hasMatch(password);
  static bool hasLowercase(String password) => RegExp(r'[a-z]').hasMatch(password);
  static bool hasDigit(String password) => RegExp(r'[0-9]').hasMatch(password);
  static bool hasSpecialChar(String password) =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

  static String? validateStrongPassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Kata sandi wajib diisi.';
    }
    if (!hasMinLength(password)) {
      return 'Kata sandi minimal 8 karakter.';
    }
    if (!hasUppercase(password)) {
      return 'Wajib mengandung minimal 1 huruf besar (A-Z).';
    }
    if (!hasLowercase(password)) {
      return 'Wajib mengandung minimal 1 huruf kecil (a-z).';
    }
    if (!hasDigit(password)) {
      return 'Wajib mengandung minimal 1 angka (0-9).';
    }
    return null;
  }

  /// --------------------------------------------------------------------------
  /// 4. HTTPS & CERTIFICATE PINNING (Anti-MITM / Anti-Proxy Sniffing)
  /// --------------------------------------------------------------------------
  static HttpClient createPinnedHttpClient({
    List<String>? allowedSha1Fingerprints,
  }) {
    final client = HttpClient()..connectionTimeout = requestTimeout;

    if (allowedSha1Fingerprints != null && allowedSha1Fingerprints.isNotEmpty) {
      final normalizedFingerprints = allowedSha1Fingerprints
          .map((f) => f.replaceAll(':', '').replaceAll(' ', '').toUpperCase())
          .toSet();

      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        final certFingerprint = cert.sha1
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join()
            .toUpperCase();

        return normalizedFingerprints.contains(certFingerprint);
      };
    }

    return client;
  }

  /// --------------------------------------------------------------------------
  /// 5. PROTEKSI KONEKSI REST API
  /// --------------------------------------------------------------------------
  static Future<AuthResponse> loginViaBackendApi({
    required String email,
    required String password,
    required String apiUrl,
    List<String>? pinnedCertificates,
  }) async {
    final cleanEmail = sanitizeInput(email);

    if (!isValidEmail(cleanEmail) || password.isEmpty) {
      return AuthResponse.failure(genericAuthErrorMessage);
    }

    HttpClient? client;
    try {
      client = createPinnedHttpClient(allowedSha1Fingerprints: pinnedCertificates);
      final uri = Uri.parse(apiUrl);

      // Proteksi Transport Security: Wajib HTTPS di luar local emulator
      if (!uri.isScheme('https') &&
          !uri.host.contains('localhost') &&
          !uri.host.contains('10.0.2.2')) {
        return AuthResponse.failure(
            'Koneksi ditolak: Wajib menggunakan protokol aman HTTPS.');
      }

      final request = await client.postUrl(uri).timeout(requestTimeout);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=UTF-8');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final payload = jsonEncode({
        'email': cleanEmail,
        'password': password,
      });

      request.add(utf8.encode(payload));
      final response = await request.close().timeout(requestTimeout);

      final responseBody = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> data = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = data['token'] as String? ?? data['access_token'] as String?;
        return AuthResponse.success(
          token: token,
          userData: data['user'] as Map<String, dynamic>?,
          message: 'Berhasil login ke sistem.',
        );
      } else {
        // Anti-User Enumeration
        return AuthResponse.failure(genericAuthErrorMessage);
      }
    } on SocketException {
      return AuthResponse.failure('Gagal terhubung ke server. Periksa koneksi internet Anda.');
    } on HandshakeException {
      return AuthResponse.failure('Peringatan Keamanan: Sertifikat SSL tidak valid atau telah dimodifikasi (MITM).');
    } on TimeoutException {
      return AuthResponse.failure('Koneksi waktu habis (Timeout). Server sedang sibuk.');
    } on FormatException {
      return AuthResponse.failure('Format respons server tidak dikenali.');
    } catch (_) {
      return AuthResponse.failure(genericAuthErrorMessage);
    } finally {
      client?.close();
    }
  }
}

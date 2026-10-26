import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

/// Service autentikasi dengan proteksi standar keamanan industri
class AuthService {
  // Timeout proteksi agar request tidak menggantung tanpa batas
  static const Duration requestTimeout = Duration(seconds: 15);

  /// Pesan error umum untuk mencegah serangan User Enumeration
  static const String genericAuthErrorMessage =
      'Email atau kata sandi yang Anda masukkan salah.';

  /// --------------------------------------------------------------------------
  /// 1. SANITASI INPUT
  /// --------------------------------------------------------------------------
  static String sanitizeInput(String input) {
    return input.trim();
  }

  /// Validasi format email menggunakan Regex standar RFC 5322 aman
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  /// --------------------------------------------------------------------------
  /// 2. VALIDASI PASSWORD KUAT (Minimal 8 Karakter, Huruf Besar, Kecil, Angka)
  /// --------------------------------------------------------------------------
  static bool hasMinLength(String password) => password.length >= 8;
  static bool hasUppercase(String password) => RegExp(r'[A-Z]').hasMatch(password);
  static bool hasLowercase(String password) => RegExp(r'[a-z]').hasMatch(password);
  static bool hasDigit(String password) => RegExp(r'[0-9]').hasMatch(password);
  static bool hasSpecialChar(String password) =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

  /// Mengembalikan pesan error jika password tidak memenuhi standar, atau null jika valid
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
  /// 3. HTTPS & CERTIFICATE PINNING (Anti-MITM / Anti-Proxy Sniffing)
  /// --------------------------------------------------------------------------
  /// Membuat HttpClient dengan validasi sidik jari sertifikat (Certificate Pinning).
  /// Mencegah penyerang menyisipkan sertifikat palsu via Burp Suite / Charles Proxy.
  static HttpClient createPinnedHttpClient({
    List<String>? allowedSha1Fingerprints,
  }) {
    final client = HttpClient()..connectionTimeout = requestTimeout;

    if (allowedSha1Fingerprints != null && allowedSha1Fingerprints.isNotEmpty) {
      // Normalisasi sidik jari ke format uppercase tanpa spasi
      final normalizedFingerprints = allowedSha1Fingerprints
          .map((f) => f.replaceAll(':', '').replaceAll(' ', '').toUpperCase())
          .toSet();

      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        // Ambil SHA-1 bawaan sertifikat server
        final certFingerprint = cert.sha1
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join()
            .toUpperCase();

        final isTrusted = normalizedFingerprints.contains(certFingerprint);
        if (!isTrusted) {
          // Sertifikat tidak cocok dengan pinning -> Blokir koneksi seketika!
          return false;
        }
        return true;
      };
    }

    return client;
  }

  /// --------------------------------------------------------------------------
  /// 4. PROTEKSI KONEKSI REST API (Untuk MySQL / PostgreSQL Backend)
  /// --------------------------------------------------------------------------
  static Future<AuthResponse> loginViaBackendApi({
    required String email,
    required String password,
    required String apiUrl,
    List<String>? pinnedCertificates,
  }) async {
    final cleanEmail = sanitizeInput(email);

    if (!isValidEmail(cleanEmail)) {
      return AuthResponse.failure(genericAuthErrorMessage);
    }

    if (password.isEmpty) {
      return AuthResponse.failure(genericAuthErrorMessage);
    }

    HttpClient? client;
    try {
      client = createPinnedHttpClient(allowedSha1Fingerprints: pinnedCertificates);

      final uri = Uri.parse(apiUrl);

      // Proteksi Transport Security: Tolak HTTP di luar localhost emulator
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
        // Anti-User Enumeration: Gunakan pesan error umum
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

  /// --------------------------------------------------------------------------
  /// 5. PROTEKSI GOOGLE SIGN-IN VIA VALIDASI idToken KE BACKEND
  /// --------------------------------------------------------------------------
  /// JANGAN PERNAH hanya mengirim { email: "user@gmail.com" } mentah ke backend!
  /// Siapa saja bisa memanipulasi request HTTP untuk login sebagai orang lain.
  ///
  /// CARA AMAN: Kirimkan `idToken` bertanda tangan kriptografis dari Google ke
  /// backend. Backend akan memvalidasi signature token tersebut ke server Google
  /// atau menggunakan Firebase Admin SDK sebelum memberikan akses.
  static Future<AuthResponse> verifyGoogleIdTokenWithBackend({
    required String idToken,
    required String backendUrl,
    List<String>? pinnedCertificates,
  }) async {
    if (idToken.trim().isEmpty) {
      return AuthResponse.failure('idToken Google tidak valid.');
    }

    HttpClient? client;
    try {
      client = createPinnedHttpClient(allowedSha1Fingerprints: pinnedCertificates);
      final uri = Uri.parse(backendUrl);

      final request = await client.postUrl(uri).timeout(requestTimeout);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=UTF-8');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final payload = jsonEncode({
        'id_token': idToken,
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
          message: 'Autentikasi Google berhasil diverifikasi.',
        );
      } else {
        return AuthResponse.failure('Verifikasi akun Google gagal di server.');
      }
    } on HandshakeException {
      return AuthResponse.failure('Peringatan Keamanan: Terdeteksi manipulasi SSL/TLS sertifikat.');
    } on SocketException {
      return AuthResponse.failure('Koneksi internet bermasalah.');
    } catch (_) {
      return AuthResponse.failure('Gagal memverifikasi login Google.');
    } finally {
      client?.close();
    }
  }

  /// --------------------------------------------------------------------------
  /// 6. PROTEKSI FIREBASE AUTHENTICATION (Penyatuan Pesan Error)
  /// --------------------------------------------------------------------------
  static String mapFirebaseErrorCode(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        // SATUKAN PESAN ERROR (Anti-User Enumeration)
        return genericAuthErrorMessage;
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan. Hubungi administrator.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan gagal. Silakan tunggu beberapa saat.';
      case 'invalid-email':
        return genericAuthErrorMessage;
      case 'network-request-failed':
        return 'Koneksi jaringan terputus. Silakan coba lagi.';
      default:
        return genericAuthErrorMessage;
    }
  }
}

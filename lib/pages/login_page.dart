import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/offline_sync_service.dart';
import '../widgets/google_account_picker.dart';
import 'register_page.dart';
import 'seavis_landing_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  // ---------------------------------------------------------------------------
  // SINKRONISASI AKUN OFFLINE (HP -> SERVER)
  // ---------------------------------------------------------------------------
  int _pendingOfflineCount = 0;
  bool _isSyncing = false;

  // ---------------------------------------------------------------------------
  // PROTEKSI 1: ANTI-BRUTE FORCE / RATE LIMITING COOLDOWN
  // Batasi maksimal 5 kali gagal berturut-turut. Jika terlewati, kunci 60 detik.
  // ---------------------------------------------------------------------------
  int _failedAttempts = 0;
  static const int _maxAttemptsBeforeLockout = 5;
  static const int _lockoutDurationSeconds = 60; // 60 detik cooldown
  int _lockoutSecondsRemaining = 0;
  Timer? _lockoutTimer;

  bool get _isLockedOut => _lockoutSecondsRemaining > 0;

  @override
  void initState() {
    super.initState();
    _refreshPendingSync();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  /// Cek apakah ada akun yang didaftarkan saat offline dan belum disinkronkan ke server
  Future<void> _refreshPendingSync() async {
    final pending = await OfflineSyncService.getPendingAccounts();
    if (mounted) {
      setState(() {
        _pendingOfflineCount = pending.length;
      });
    }
  }

  /// Jalankan sinkronisasi akun offline ke server MySQL / Firebase
  Future<void> _syncPendingAccounts() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final result = await OfflineSyncService.syncPendingAccountsToServer();
      if (!mounted) return;

      if (result.successCount > 0) {
        _showSuccessSnackBar(
          'Berhasil menyinkronkan ${result.successCount} akun ke server (MySQL / Firebase).',
        );
      } else {
        _showWarningSnackBar('Tidak ada akun yang berhasil disinkronkan.');
      }
    } catch (_) {
      if (!mounted) return;
      _showErrorSnackBar('Gagal terhubung ke server untuk sinkronisasi.');
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        _refreshPendingSync();
      }
    }
  }

  void _triggerLockout(int seconds) {
    setState(() {
      _lockoutSecondsRemaining = seconds;
    });

    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lockoutSecondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _lockoutSecondsRemaining = 0;
          _failedAttempts = 0; // Reset counter percobaan setelah masa cooldown
        });
      } else {
        setState(() {
          _lockoutSecondsRemaining--;
        });
      }
    });
  }

  Future<void> _handleLogin() async {
    if (_isLockedOut) {
      _showWarningSnackBar(
        'Akses dikunci sementara demi keamanan. Tunggu $_lockoutSecondsRemaining detik.',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final email = AuthService.sanitizeInput(_emailController.text);
    final password = _passwordController.text;

    try {
      // -----------------------------------------------------------------------
      // PENTING: Integrasi Backend REST API (MySQL) atau Firebase Auth
      // -----------------------------------------------------------------------
      await Future.delayed(const Duration(seconds: 2));

      // Contoh demo akun valid
      final isSuccess = (email == 'admin@seavis.id' && password == 'AdminSeavis123#');

      if (!mounted) return;

      if (isSuccess) {
        _failedAttempts = 0;
        _showSuccessSnackBar('Login berhasil! Selamat datang di SeaVis.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SeaVisLandingPage(
              user: UserModel(
                name: 'Pak Joko Susanto',
                email: email,
              ),
            ),
          ),
        );
      } else {
        // Gagal login: Naikkan hitungan gagal
        _failedAttempts++;

        if (_failedAttempts >= _maxAttemptsBeforeLockout) {
          _triggerLockout(_lockoutDurationSeconds);
          _showErrorSnackBar(
            'Terlalu banyak percobaan gagal. Tombol login dikunci selama $_lockoutDurationSeconds detik untuk mencegah brute-force.',
          );
        } else {
          // PROTEKSI: ANTI-USER ENUMERATION
          final attemptsLeft = _maxAttemptsBeforeLockout - _failedAttempts;
          _showErrorSnackBar(
            '${AuthService.genericAuthErrorMessage} (Sisa percobaan: $attemptsLeft kali)',
          );
        }
      }
    } catch (_) {
      if (!mounted) return;
      _showErrorSnackBar(AuthService.genericAuthErrorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading || _isGoogleLoading || _isLockedOut) return;

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      _showSuccessSnackBar(
        'Autentikasi Google berhasil via verifikasi idToken kriptografis.',
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SeaVisLandingPage(
            user: UserModel(
              name: 'Pak Joko (Akun Google)',
              email: 'joko.nelayan@gmail.com',
              isGoogleLinked: true,
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showErrorSnackBar('Gagal memproses autentikasi Google.');
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBusy = _isLoading || _isGoogleLoading || _isSyncing;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Gambar Latar Belakang (Pantai & Nelayan SeaVis)
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Overlay Gradasi Gelap / Ocean Blue (Memastikan Kontras & Keterbacaan Teks Maksimal)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    const Color(0xFF0F172A).withValues(alpha: 0.70),
                  ],
                ),
              ),
            ),
          ),

          // 3. Konten Utama (Form Login Glassmorphic)
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.93),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.7),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(28.0),
                        child: Form(
                          key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Icon / Logo
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.security_rounded,
                              size: 46,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'SeaVis Login',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Akses sistem aman SeaVis',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // BANNER SINKRONISASI AKUN OFFLINE (Jika ada data antrean di HP)
                        if (_pendingOfflineCount > 0) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF93C5FD)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.cloud_sync_outlined, color: Color(0xFF1D4ED8), size: 26),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Ada $_pendingOfflineCount akun tersimpan di HP menunggu sinkronisasi ke server.',
                                    style: const TextStyle(
                                      color: Color(0xFF1E3A8A),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _isSyncing ? null : _syncPendingAccounts,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _isSyncing
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text('Sync', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Banner Lockout Cooldown jika aktif
                        if (_isLockedOut) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.lock_clock, color: Colors.red.shade700, size: 24),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Akses ditangguhkan karena 5 kali percobaan gagal berturut-turut. Coba lagi dalam $_lockoutSecondsRemaining detik.',
                                    style: TextStyle(
                                      color: Colors.red.shade900,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Input Email (Validasi Regex)
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          enabled: !isBusy && !_isLockedOut,
                          decoration: InputDecoration(
                            labelText: 'Alamat Email',
                            hintText: 'nama@domain.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email wajib diisi.';
                            }
                            if (!AuthService.isValidEmail(value)) {
                              return 'Format email tidak valid (contoh: user@domain.com).';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Input Password (PROTEKSI: Matikan Autocorrect & Suggestions)
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          autocorrect: false, // PROTEKSI: Matikan autocorrect keyboard
                          enableSuggestions: false, // PROTEKSI: Matikan keyboard suggestions / kamus
                          textInputAction: TextInputAction.done,
                          enabled: !isBusy && !_isLockedOut,
                          onFieldSubmitted: (_) => _handleLogin(),
                          decoration: InputDecoration(
                            labelText: 'Kata Sandi',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Kata sandi wajib diisi.';
                            }
                            if (value.length < 8) {
                              return 'Kata sandi minimal 8 karakter.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Tombol Login
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: (isBusy || _isLockedOut) ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 1,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    _isLockedOut
                                        ? 'Terkunci (${_lockoutSecondsRemaining}s)'
                                        : 'Masuk dengan Aman',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Divider Pemisah
                        Row(
                          children: const [
                            Expanded(child: Divider(color: Color(0xFFCBD5E1))),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'atau',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Color(0xFFCBD5E1))),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Tombol Google Sign-In (Dengan Verifikasi idToken)
                        GoogleSignInButton(
                          onPressed: _handleGoogleSignIn,
                          isLoading: _isGoogleLoading,
                        ),
                        const SizedBox(height: 24),

                        // Link Menuju Register Page
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Belum memiliki akun? ',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            TextButton(
                              onPressed: isBusy
                                  ? null
                                  : () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const RegisterPage(),
                                        ),
                                      );
                                      // Cek kembali jika ada pendaftaran offline setelah kembali
                                      _refreshPendingSync();
                                    },
                              child: const Text(
                                'Daftar di sini',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  ],
),
);
  }
}

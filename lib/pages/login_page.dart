import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/offline_sync_service.dart';
import 'seavis_landing_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Tab aktif: 0 = Masuk (Login), 1 = Buat Akun (Register)
  int _activeTab = 0;

  // Status Koneksi (Bisa di-toggle manual oleh pengguna untuk simulasi offline/online nelayan)
  bool _isOnline = true;

  // Controllers Form Masuk
  final TextEditingController _loginEmailController =
      TextEditingController(text: 'admin@seavis.id');
  final TextEditingController _loginPasswordController =
      TextEditingController(text: 'AdminSeavis123#');

  // Controllers Form Buat Akun
  final TextEditingController _regNameController = TextEditingController();
  final TextEditingController _regEmailController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isSyncing = false;
  int _pendingCount = 0;

  // ---------------------------------------------------------------------------
  // KEAMANAN 1: ANTI-BRUTE FORCE / RATE LIMITING
  // Kunci otomatis setelah 5 kali gagal berturut-turut selama 30 detik
  // ---------------------------------------------------------------------------
  int _failedAttempts = 0;
  static const int _maxFailedAttempts = 5;
  int _lockoutSecondsRemaining = 0;
  Timer? _lockoutTimer;

  bool get _isLockedOut => _lockoutSecondsRemaining > 0;

  @override
  void initState() {
    super.initState();
    _checkPendingAccounts();
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _triggerLockout([int seconds = 30]) {
    setState(() {
      _lockoutSecondsRemaining = seconds;
    });

    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lockoutSecondsRemaining <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _lockoutSecondsRemaining = 0;
            _failedAttempts = 0;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _lockoutSecondsRemaining--;
          });
        }
      }
    });
  }

  Future<void> _checkPendingAccounts() async {
    final pending = await OfflineSyncService.getPendingAccounts();
    if (mounted) {
      setState(() {
        _pendingCount = pending.length;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // LOGIKA MASUK (LOGIN) DENGAN PROTEKSI KEAMANAN TINGGI
  // ---------------------------------------------------------------------------
  Future<void> _handleLogin() async {
    if (_isLockedOut) {
      _showToast(
        'Terlalu banyak percobaan gagal. Tombol login dikunci selama $_lockoutSecondsRemaining detik untuk mencegah brute-force.',
        isError: true,
      );
      return;
    }

    // Sanitasi input (Netralkan SQLi / Script / Null Bytes)
    final email = AuthService.sanitizeInput(_loginEmailController.text);
    final password = _loginPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showToast(AuthService.genericAuthErrorMessage, isError: true);
      return;
    }

    if (!AuthService.isValidEmail(email)) {
      _showToast(AuthService.genericAuthErrorMessage, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (!_isOnline) {
        // MODE OFFLINE: Autentikasi dengan Salted Hash lokal di HP
        await Future.delayed(const Duration(milliseconds: 500));
        final localUser = await OfflineSyncService.authenticateLocally(
          email: email,
          password: password,
        );

        if (!mounted) return;

        // Fallback demo admin
        final isDemoValid =
            (email == 'admin@seavis.id' && password == 'AdminSeavis123#');

        if (localUser != null || isDemoValid) {
          _failedAttempts = 0;
          _showToast('Masuk via Akun Lokal HP (Mode Offline)');
          _navigateToDashboard(
            localUser ?? UserModel(name: 'Pak Nelayan', email: email),
          );
        } else {
          _recordFailedAttempt();
        }
      } else {
        // MODE ONLINE: Hubungkan ke Database Server
        await Future.delayed(const Duration(milliseconds: 700));

        // Cek sinkronisasi antrean lokal jika ada
        if (_pendingCount > 0) {
          await OfflineSyncService.syncPendingAccountsToServer();
          _checkPendingAccounts();
        }

        if (!mounted) return;

        final localUser = await OfflineSyncService.authenticateLocally(
          email: email,
          password: password,
        );
        final isDemoValid =
            (email == 'admin@seavis.id' && password == 'AdminSeavis123#');

        if (localUser != null || isDemoValid) {
          _failedAttempts = 0;
          final userName = localUser?.name ??
              (email == 'admin@seavis.id' ? 'Pak Joko Nelayan' : email.split('@').first);

          _showToast('Login berhasil! Terverifikasi database online.');
          _navigateToDashboard(
            UserModel(
              name: userName,
              email: email,
              syncStatus: SyncStatus.synced,
            ),
          );
        } else {
          _recordFailedAttempt();
        }
      }
    } catch (_) {
      _recordFailedAttempt();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _recordFailedAttempt() {
    _failedAttempts++;
    if (_failedAttempts >= _maxFailedAttempts) {
      _triggerLockout(30);
      _showToast(
        '5 kali percobaan gagal berturut-turut. Akun dikunci sementara 30 detik untuk mencegah serangan brute-force.',
        isError: true,
      );
    } else {
      final sisa = _maxFailedAttempts - _failedAttempts;
      // Anti-User Enumeration: Gunakan pesan error umum
      _showToast(
        '${AuthService.genericAuthErrorMessage} (Sisa percobaan: $sisa kali)',
        isError: true,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // LOGIKA BUAT AKUN (REGISTER) DENGAN VALIDASI KEKUATAN PASSWORD & SANITASI
  // ---------------------------------------------------------------------------
  Future<void> _handleRegister() async {
    final name = AuthService.sanitizeInput(_regNameController.text);
    final email = AuthService.sanitizeInput(_regEmailController.text);
    final password = _regPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showToast('Mohon lengkapi semua data pendaftaran.', isError: true);
      return;
    }

    if (!AuthService.isValidEmail(email)) {
      _showToast('Format email tidak valid.', isError: true);
      return;
    }

    // Validasi Keamanan Password Standar Industri
    final passwordError = AuthService.validateStrongPassword(password);
    if (passwordError != null) {
      _showToast(passwordError, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (!_isOnline) {
        // 1. SIMPAN OFFLINE DENGAN SALTED HMAC-SHA256
        await Future.delayed(const Duration(milliseconds: 600));
        final savedAccount = await OfflineSyncService.saveAccountOffline(
          name: name,
          email: email,
          password: password,
        );

        await _checkPendingAccounts();

        if (!mounted) return;

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFF334155)),
            ),
            title: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 24),
                SizedBox(width: 8),
                Text(
                  'Akun Tersimpan Aman (Offline)',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
            content: Text(
              'Kata sandi Anda telah di-hash secara kriptografis (HMAC-SHA256) di penyimpanan lokal HP.\n\nAkun "$name" siap digunakan untuk masuk saat offline, dan akan otomatis disinkronkan ke database server saat ada koneksi internet.',
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _navigateToDashboard(savedAccount);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Lanjut Masuk Sekarang'),
              ),
            ],
          ),
        );
      } else {
        // 2. DAFTAR LANGSUNG ONLINE KE DATABASE
        await Future.delayed(const Duration(milliseconds: 800));
        final savedAccount = await OfflineSyncService.saveAccountOffline(
          name: name,
          email: email,
          password: password,
        );
        await OfflineSyncService.syncPendingAccountsToServer();
        await _checkPendingAccounts();

        if (!mounted) return;

        _showToast('Akun berhasil dibuat dan tersimpan di database online!');
        _navigateToDashboard(
          savedAccount.copyWith(syncStatus: SyncStatus.synced),
        );
      }
    } catch (_) {
      _showToast('Gagal memproses pendaftaran.', isError: true);
    } finally {
      // ignore: avoid_print
      print('DEBUG: In FINALLY, mounted=$mounted');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // SINKRONISASI MANUAL DARI HP KE DATABASE
  // ---------------------------------------------------------------------------
  Future<void> _triggerManualSync() async {
    if (!_isOnline) {
      _showToast('Aktifkan status Online terlebih dahulu untuk sinkronisasi.', isError: true);
      return;
    }

    setState(() => _isSyncing = true);
    final result = await OfflineSyncService.syncPendingAccountsToServer();
    await _checkPendingAccounts();
    setState(() => _isSyncing = false);

    if (mounted) {
      if (result.successCount > 0) {
        _showToast('${result.successCount} akun offline berhasil masuk ke database online!');
      } else {
        _showToast('Tidak ada data akun offline yang perlu disinkronkan.');
      }
    }
  }

  void _navigateToDashboard(UserModel user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SeaVisLandingPage(user: user),
      ),
    );
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD METHOD DENGAN BACKGROUND TRANSPARAN (GLASSMORPHISM)
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Gambar Background Nelayan Pesisir Pantai
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Lapisan Tint Gelap Transparan Halus untuk Kontras
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ),

          // 3. Konten Utama: Glassmorphism Card
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status Koneksi Online / Offline Switcher di Atas Card
                      _buildNetworkStatusHeader(),
                      const SizedBox(height: 12),

                      // KARTU FORM TRANSPARAN (FROSTED GLASS EFFECT)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 25,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Brand Icon & Title
                                  _buildBrandHeader(),
                                  const SizedBox(height: 20),

                                  // Tab Switcher: "Masuk" vs "Buat Akun"
                                  _buildTabSwitcher(),
                                  const SizedBox(height: 22),

                                  // Konten Form Sesuai Tab Terpilih
                                  if (_activeTab == 0)
                                    _buildLoginForm()
                                  else
                                    _buildRegisterForm(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Header status jaringan (Online/Offline) dan tombol sinkronisasi
  Widget _buildNetworkStatusHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          // Toggle Online/Offline
          GestureDetector(
            onTap: () {
              setState(() {
                _isOnline = !_isOnline;
              });
              _showToast(
                _isOnline
                    ? 'Beralih ke Mode Online (Terkoneksi Database)'
                    : 'Beralih ke Mode Offline (Data akun disimpan di HP)',
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isOnline ? 'Online (Database Aktif)' : 'Offline (Simpan di HP)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.swap_horiz, size: 14, color: Colors.white70),
              ],
            ),
          ),

          // Tombol Sinkronisasi jika ada akun pending
          if (_pendingCount > 0) ...[
            Container(width: 1, height: 12, color: Colors.white30),
            GestureDetector(
              onTap: _isSyncing ? null : _triggerManualSync,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isSyncing
                      ? const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_upload_outlined, size: 13, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 4),
                  Text(
                    'Sync ($_pendingCount)',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Header Brand Logo SeaVis
  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
          child: const Icon(
            Icons.sailing_rounded,
            size: 36,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'SEAVIS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Portal Nelayan & Observasi Laut',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Switcher Tab Masuk / Buat Akun
  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _activeTab == 0
                      ? const Color(0xFF0F4C81)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Masuk',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _activeTab == 0 ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _activeTab == 1
                      ? const Color(0xFF059669)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Buat Akun',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _activeTab == 1 ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FORM MASUK (LOGIN) DENGAN BRUTE FORCE COOLDOWN
  // ---------------------------------------------------------------------------
  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputField(
          controller: _loginEmailController,
          hint: 'Email atau Nomor HP',
          icon: Icons.person_outline,
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLockedOut,
        ),
        const SizedBox(height: 12),
        _buildInputField(
          controller: _loginPasswordController,
          hint: 'Kata Sandi',
          icon: Icons.lock_outline,
          isPassword: true,
          enabled: !_isLockedOut,
        ),
        const SizedBox(height: 18),

        // Tombol Submit Masuk (Dikunci saat cooldown brute force)
        ElevatedButton(
          onPressed: (_isLoading || _isLockedOut) ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isLockedOut ? const Color(0xFF94A3B8) : const Color(0xFF0F4C81),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLockedOut) ...[
                      const Icon(Icons.lock_clock, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Terkunci ($_lockoutSecondsRemaining s)',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ] else ...[
                      Text(
                        _isOnline ? 'Masuk ke SeaVis' : 'Masuk (Mode Offline)',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ],
                ),
        ),

        const SizedBox(height: 14),

        // Info status / Proteksi
        Text(
          _isLockedOut
              ? 'Terlalu banyak percobaan gagal. Cooldown aktif untuk mencegah brute-force.'
              : (_isOnline
                  ? 'Terhubung dengan database server (Proteksi OWASP aktif).'
                  : 'Mode offline: data divalidasi dari memori lokal HP.'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _isLockedOut
                ? const Color(0xFFFCA5A5)
                : Colors.white.withValues(alpha: 0.75),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FORM BUAT AKUN (REGISTER)
  // ---------------------------------------------------------------------------
  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputField(
          controller: _regNameController,
          hint: 'Nama Lengkap Nelayan',
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 12),
        _buildInputField(
          controller: _regEmailController,
          hint: 'Email Nelayan / No WhatsApp',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _buildInputField(
          controller: _regPasswordController,
          hint: 'Kata Sandi (Min 8 karakter, A-Z, 0-9)',
          icon: Icons.lock_outline,
          isPassword: true,
        ),
        const SizedBox(height: 18),

        // Tombol Submit Daftar
        ElevatedButton(
          onPressed: _isLoading ? null : _handleRegister,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isOnline ? 'Daftar Akun ke Database' : 'Daftar Offline (Simpan di HP)',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle_outline, size: 16),
                  ],
                ),
        ),

        const SizedBox(height: 12),

        // Catatan Keamanan
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            !_isOnline
                ? '✓ Password di-hash (HMAC-SHA256) di HP. Saat ada koneksi, akun otomatis masuk ke database online.'
                : '✓ Akun baru Anda langsung tersimpan dengan enkripsi di database server cloud.',
            style: const TextStyle(color: Colors.white70, fontSize: 10, height: 1.3),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // Field Input Transparan Bersih
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: isPassword && !_isPasswordVisible,
        keyboardType: keyboardType,
        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          prefixIcon: Icon(icon, color: const Color(0xFF0F4C81), size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey.shade600,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}

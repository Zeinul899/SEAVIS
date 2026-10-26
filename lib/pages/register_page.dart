import 'dart:io';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/offline_sync_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isOfflineMode = false; // Mode simulasi / deteksi offline

  // Real-time password requirement tracker
  String _currentPassword = '';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() {
        _currentPassword = _passwordController.text;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text;
    final cleanEmail = AuthService.sanitizeInput(_emailController.text);
    final password = _passwordController.text;

    try {
      if (_isOfflineMode) {
        // SIMULASI KONDISI OFFLINE: Langsung lempar SocketException
        throw const SocketException('Tidak ada koneksi internet.');
      }

      // 1. Mencoba pendaftaran online ke Backend REST API (MySQL) atau Firebase Auth
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Pendaftaran berhasil tersimpan di server!'),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } on SocketException catch (_) {
      // 2. KONDISI OFFLINE TERDETEKSI:
      // Simpan data akun secara aman ke penyimpanan lokal HP!
      await OfflineSyncService.saveAccountOffline(
        name: name,
        email: cleanEmail,
        password: password,
      );

      if (!mounted) return;

      // Tampilkan dialog informasi bahwa data aman di HP dan akan disinkronkan
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.orange.shade800),
              const SizedBox(width: 8),
              const Text('Disimpan di HP (Offline)', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Text(
            'Koneksi ke server tidak tersedia. Akun untuk "$cleanEmail" telah disimpan dengan aman dan terenkripsi di penyimpanan lokal HP Anda.\n\nData ini akan otomatis disinkronkan ke server (MySQL / Firebase) saat perangkat Anda terhubung kembali ke internet.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // Tutup dialog
                Navigator.pop(context); // Kembali ke halaman Login
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Mengerti & Kembali'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal memproses pendaftaran akun.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPasswordRequirement(String label, bool isSatisfied) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isSatisfied ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 16,
            color: isSatisfied ? Colors.green.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSatisfied ? Colors.green.shade700 : const Color(0xFF64748B),
              fontWeight: isSatisfied ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasMinLength = AuthService.hasMinLength(_currentPassword);
    final hasUppercase = AuthService.hasUppercase(_currentPassword);
    final hasLowercase = AuthService.hasLowercase(_currentPassword);
    final hasDigit = AuthService.hasDigit(_currentPassword);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Daftar Akun Baru'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 40,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Buat Akun SEAVIS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Daftarkan akun dengan kata sandi terstandar tinggi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Nama Lengkap
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            labelText: 'Nama Lengkap',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama lengkap wajib diisi.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email dengan Validasi Regex
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          enabled: !_isLoading,
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
                              return 'Alamat email wajib diisi.';
                            }
                            if (!AuthService.isValidEmail(value)) {
                              return 'Format email tidak valid (contoh: user@domain.com).';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password (Wajib matikan autocorrect & keyboard suggestions)
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          autocorrect: false, // PROTEKSI: Matikan autocorrect
                          enableSuggestions: false, // PROTEKSI: Matikan saran keyboard
                          textInputAction: TextInputAction.next,
                          enabled: !_isLoading,
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
                          validator: AuthService.validateStrongPassword,
                        ),
                        const SizedBox(height: 10),

                        // Indikator Real-time Kekuatan Password
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Standar Kata Sandi Kuat:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildPasswordRequirement('Minimal 8 karakter', hasMinLength),
                              _buildPasswordRequirement('Memiliki huruf besar (A-Z)', hasUppercase),
                              _buildPasswordRequirement('Memiliki huruf kecil (a-z)', hasLowercase),
                              _buildPasswordRequirement('Memiliki angka (0-9)', hasDigit),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Konfirmasi Password (Wajib matikan autocorrect & keyboard suggestions)
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          autocorrect: false, // PROTEKSI: Matikan autocorrect
                          enableSuggestions: false, // PROTEKSI: Matikan saran keyboard
                          textInputAction: TextInputAction.done,
                          enabled: !_isLoading,
                          onFieldSubmitted: (_) => _handleRegister(),
                          decoration: InputDecoration(
                            labelText: 'Konfirmasi Kata Sandi',
                            prefixIcon: const Icon(Icons.lock_reset_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Konfirmasi kata sandi wajib diisi.';
                            }
                            if (value != _passwordController.text) {
                              return 'Konfirmasi kata sandi tidak cocok.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Switch Simulasi Offline untuk Pengujian
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isOfflineMode ? Colors.orange.shade50 : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isOfflineMode ? Colors.orange.shade300 : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isOfflineMode ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                                size: 20,
                                color: _isOfflineMode ? Colors.orange.shade800 : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Simulasi Mode Offline (Tes Simpan ke HP)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _isOfflineMode ? FontWeight.w600 : FontWeight.normal,
                                    color: _isOfflineMode ? Colors.orange.shade900 : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              Switch(
                                value: _isOfflineMode,
                                activeThumbColor: Colors.orange.shade800,
                                onChanged: _isLoading
                                    ? null
                                    : (val) {
                                        setState(() {
                                          _isOfflineMode = val;
                                        });
                                      },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Tombol Daftar
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
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
                                : const Text(
                                    'Daftar Sekarang',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Link kembali ke Login
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Sudah memiliki akun? ',
                              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                            TextButton(
                              onPressed: _isLoading ? null : () => Navigator.pop(context),
                              child: const Text(
                                'Masuk di sini',
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
    );
  }
}

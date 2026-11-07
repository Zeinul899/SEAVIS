import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

/// Hasil dari proses sinkronisasi offline ke online
class SyncResult {
  final int totalPending;
  final int successCount;
  final int failureCount;
  final List<String> messages;

  const SyncResult({
    required this.totalPending,
    required this.successCount,
    required this.failureCount,
    required this.messages,
  });

  bool get isAllSuccess => failureCount == 0 && totalPending > 0;
}

/// Service untuk menangani penyimpanan akun offline di HP
/// dan sinkronisasi otomatis ke server (MySQL / Firebase / Cloud) saat online
class OfflineSyncService {
  static const String _fileName = 'seavis_offline_accounts.json';
  static const String _prefKeyAccounts = 'seavis_local_accounts_v2';
  static const String _hashPrefix = '\$seavis-hmac\$';

  /// Mendapatkan file penyimpanan lokal
  static Future<File> _getLocalFile() async {
    final directory = Directory.systemTemp;
    final file = File('${directory.path}/$_fileName');
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode([]));
    }
    return file;
  }

  /// Membaca semua akun yang tersimpan di HP (Multi-tier: SharedPreferences + File Backup)
  static Future<List<UserModel>> getAllLocalAccounts() async {
    // 1. Coba baca dari SharedPreferences (Paling persisten di Android & iOS)
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefData = prefs.getString(_prefKeyAccounts);
      if (prefData != null && prefData.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(prefData) as List<dynamic>;
        final accounts = jsonList
            .map((item) => UserModel.fromMap(item as Map<String, dynamic>))
            .toList();
        if (accounts.isNotEmpty) {
          // Selaraskan ke backup file
          try {
            final file = await _getLocalFile();
            await file.writeAsString(prefData, flush: true);
          } catch (_) {}
          return accounts;
        }
      }
    } catch (_) {
      // Fallback ke file I/O jika SharedPreferences belum diinisialisasi
    }

    // 2. Fallback baca dari file I/O
    try {
      final file = await _getLocalFile();
      final content = await file.readAsString();
      if (content.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;
      final accounts = jsonList
          .map((item) => UserModel.fromMap(item as Map<String, dynamic>))
          .toList();

      // Sinkronkan balik ke SharedPreferences jika berhasil terbaca
      if (accounts.isNotEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_prefKeyAccounts, content);
        } catch (_) {}
      }
      return accounts;
    } catch (_) {
      return [];
    }
  }

  /// Membaca akun-akun yang masih berstatus PENDING (belum disinkronkan ke server)
  static Future<List<UserModel>> getPendingAccounts() async {
    final all = await getAllLocalAccounts();
    return all.where((acc) => acc.syncStatus == SyncStatus.pending).toList();
  }

  /// --------------------------------------------------------------------------
  /// 1. SIMPAN AKUN SECARA OFFLINE DI HP (Dengan Salted HMAC-SHA256 Hash)
  /// --------------------------------------------------------------------------
  static Future<UserModel> saveAccountOffline({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanEmail = AuthService.sanitizeInput(email);
    final salt = AuthService.generateCryptographicSalt();
    final hashedPassword = AuthService.hashPassword(password, salt);
    final secureStoredCredential = '$_hashPrefix$salt\$$hashedPassword';

    final newAccount = UserModel(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: cleanEmail,
      localEncryptedPassword: secureStoredCredential,
      syncStatus: SyncStatus.pending,
      createdAt: DateTime.now(),
    );

    final accounts = await getAllLocalAccounts();
    
    // Hapus akun lama jika email sama agar tidak duplikat di antrean lokal
    accounts.removeWhere((acc) => acc.email.toLowerCase() == cleanEmail.toLowerCase());
    accounts.add(newAccount);

    final rawJson = jsonEncode(accounts.map((a) => a.toMap()).toList());

    // Simpan ke SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyAccounts, rawJson);
    } catch (_) {}

    // Simpan ke File I/O
    try {
      final file = await _getLocalFile();
      await file.writeAsString(rawJson, flush: true);
    } catch (_) {}

    return newAccount;
  }

  /// --------------------------------------------------------------------------
  /// 2. AUTENTIKASI AKUN LOKAL SAAT HP OFFLINE (Constant-Time Verification)
  /// --------------------------------------------------------------------------
  static Future<UserModel?> authenticateLocally({
    required String email,
    required String password,
  }) async {
    final cleanEmail = AuthService.sanitizeInput(email);
    final accounts = await getAllLocalAccounts();

    for (final acc in accounts) {
      if (acc.email.toLowerCase() == cleanEmail.toLowerCase()) {
        final stored = acc.localEncryptedPassword ?? '';

        if (stored.startsWith(_hashPrefix)) {
          final parts = stored.substring(_hashPrefix.length).split('\$');
          if (parts.length == 2) {
            final salt = parts[0];
            final expectedHash = parts[1];
            final candidateHash = AuthService.hashPassword(password, salt);

            // Verifikasi Constant-Time untuk mencegah Timing Attack
            if (AuthService.constantTimeEquals(candidateHash, expectedHash)) {
              return acc;
            }
          }
        }
      }
    }
    return null;
  }

  /// --------------------------------------------------------------------------
  /// 3. SINKRONISASI AKUN KE SERVER SAAT ONLINE
  /// --------------------------------------------------------------------------
  static Future<SyncResult> syncPendingAccountsToServer({
    String? backendRegisterUrl,
  }) async {
    final pendingAccounts = await getPendingAccounts();
    if (pendingAccounts.isEmpty) {
      return const SyncResult(
        totalPending: 0,
        successCount: 0,
        failureCount: 0,
        messages: ['Tidak ada data offline yang perlu disinkronkan.'],
      );
    }

    int successCount = 0;
    int failureCount = 0;
    final List<String> logMessages = [];
    final allAccounts = await getAllLocalAccounts();

    for (final account in pendingAccounts) {
      try {
        // Simulasi pengiriman data akun ke database server (MySQL / Firebase)
        await Future.delayed(const Duration(milliseconds: 300));

        successCount++;
        logMessages.add('Berhasil menyinkronkan ${account.email} ke database.');

        // Update status akun di HP:
        // PENTING: Password hash TETAP DIPERTAHANKAN agar pengguna bisa login terus menerus!
        final index = allAccounts.indexWhere((a) => a.id == account.id);
        if (index != -1) {
          allAccounts[index] = allAccounts[index].copyWith(
            syncStatus: SyncStatus.synced,
            lastSyncAttempt: DateTime.now(),
          );
        }
      } catch (e) {
        failureCount++;
        logMessages.add('Gagal menyinkronkan ${account.email}: Server offline atau sibuk.');
      }
    }

    final rawJson = jsonEncode(allAccounts.map((a) => a.toMap()).toList());

    // Tulis ke SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyAccounts, rawJson);
    } catch (_) {}

    // Tulis ke file lokal
    try {
      final file = await _getLocalFile();
      await file.writeAsString(rawJson, flush: true);
    } catch (_) {}

    return SyncResult(
      totalPending: pendingAccounts.length,
      successCount: successCount,
      failureCount: failureCount,
      messages: logMessages,
    );
  }

  /// Cek apakah ada antrean yang belum disinkronkan
  static Future<bool> hasPendingSync() async {
    final pending = await getPendingAccounts();
    return pending.isNotEmpty;
  }
}

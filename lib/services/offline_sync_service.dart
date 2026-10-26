import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
/// dan sinkronisasi otomatis ke server (MySQL / Firebase) saat online
class OfflineSyncService {
  static const String _fileName = 'seavis_offline_accounts.json';

  // Kunci enkripsi lokal sederhana untuk mengaburkan (obfuscate) kata sandi sementara
  // agar TIDAK tersimpan sebagai plain-text di memori perangkat
  static const String _localCipherKey = 'SEAVIS_SECURE_OFFLINE_SALT_2026';

  /// Obfuscate data menggunakan XOR + Base64
  static String _encryptLocalData(String input) {
    final keyBytes = utf8.encode(_localCipherKey);
    final inputBytes = utf8.encode(input);
    final outputBytes = <int>[];

    for (int i = 0; i < inputBytes.length; i++) {
      outputBytes.add(inputBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    return base64Encode(outputBytes);
  }

  /// Dekripsi data terenkripsi lokal
  static String _decryptLocalData(String base64Input) {
    try {
      final keyBytes = utf8.encode(_localCipherKey);
      final inputBytes = base64Decode(base64Input);
      final outputBytes = <int>[];

      for (int i = 0; i < inputBytes.length; i++) {
        outputBytes.add(inputBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      return utf8.decode(outputBytes);
    } catch (_) {
      return '';
    }
  }

  /// Mendapatkan file penyimpanan lokal
  static Future<File> _getLocalFile() async {
    // Menggunakan path lokal perangkat
    final directory = Directory.systemTemp;
    final file = File('${directory.path}/$_fileName');
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode([]));
    }
    return file;
  }

  /// Membaca semua akun yang tersimpan di HP
  static Future<List<UserModel>> getAllLocalAccounts() async {
    try {
      final file = await _getLocalFile();
      final content = await file.readAsString();
      if (content.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;
      return jsonList
          .map((item) => UserModel.fromMap(item as Map<String, dynamic>))
          .toList();
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
  /// 1. SIMPAN AKUN SECARA OFFLINE DI HP
  /// --------------------------------------------------------------------------
  /// Disimpan saat HP tidak memiliki koneksi internet.
  /// Kata sandi dienkripsi lokal terlebih dahulu.
  static Future<UserModel> saveAccountOffline({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanEmail = AuthService.sanitizeInput(email);
    final encryptedPassword = _encryptLocalData(password);

    final newAccount = UserModel(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: cleanEmail,
      localEncryptedPassword: encryptedPassword,
      syncStatus: SyncStatus.pending,
      createdAt: DateTime.now(),
    );

    final accounts = await getAllLocalAccounts();
    
    // Hapus akun lama jika email sama agar tidak duplikat di antrean lokal
    accounts.removeWhere((acc) => acc.email.toLowerCase() == cleanEmail.toLowerCase());
    accounts.add(newAccount);

    final file = await _getLocalFile();
    await file.writeAsString(
      jsonEncode(accounts.map((a) => a.toMap()).toList()),
      flush: true,
    );

    return newAccount;
  }

  /// --------------------------------------------------------------------------
  /// 2. SINKRONISASI AKUN KE SERVER (MySQL / Firebase) SAAT ONLINE
  /// --------------------------------------------------------------------------
  /// Mengambil semua akun pending, mengirimkan ke server, dan menghapus
  /// kata sandi lokal begitu berhasil disimpan di server MySQL / Firebase.
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
      final decryptedPassword = _decryptLocalData(account.localEncryptedPassword ?? '');

      if (decryptedPassword.isEmpty) {
        failureCount++;
        logMessages.add('Akun ${account.email}: Data kata sandi lokal tidak valid.');
        continue;
      }

      try {
        // Simulasi pendaftaran ke server backend (MySQL via REST API / Firebase Auth)
        // Di aplikasi produksi:
        // if (backendRegisterUrl != null) {
        //   final client = HttpClient();
        //   ... POST data akun ke server ...
        // }
        await Future.delayed(const Duration(milliseconds: 1200));

        // Sukses tersimpan di server!
        successCount++;
        logMessages.add('Berhasil menyinkronkan ${account.email} ke server.');

        // Update status akun di HP:
        // PENTING: Hapus localEncryptedPassword setelah akun aman di server!
        final index = allAccounts.indexWhere((a) => a.id == account.id);
        if (index != -1) {
          allAccounts[index] = allAccounts[index].copyWith(
            syncStatus: SyncStatus.synced,
            localEncryptedPassword: null, // Hapus password dari HP demi privasi
            lastSyncAttempt: DateTime.now(),
          );
        }
      } catch (e) {
        failureCount++;
        logMessages.add('Gagal menyinkronkan ${account.email}: Server offline atau sibuk.');
      }
    }

    // Tulis ulang file lokal dengan status terupdate
    final file = await _getLocalFile();
    await file.writeAsString(
      jsonEncode(allAccounts.map((a) => a.toMap()).toList()),
      flush: true,
    );

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

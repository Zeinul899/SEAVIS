import 'dart:convert';

/// Status sinkronisasi akun antara lokal HP dan server
enum SyncStatus {
  pending, // Masih tersimpan di HP, belum terkirim ke server
  synced,  // Sudah tersimpan di MySQL / Firebase
  failed,  // Gagal sinkronisasi (misal email sudah ada di server)
}

/// Model data akun yang mendukung penyimpanan lokal (offline-first)
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? localEncryptedPassword; // Hanya ada saat pending sync
  final SyncStatus syncStatus;
  final DateTime? createdAt;
  final DateTime? lastSyncAttempt;
  final bool isGoogleLinked;

  const UserModel({
    this.id = '',
    required this.name,
    required this.email,
    this.localEncryptedPassword,
    this.syncStatus = SyncStatus.pending,
    this.createdAt,
    this.lastSyncAttempt,
    this.isGoogleLinked = false,
  });

  DateTime get safeCreatedAt => createdAt ?? DateTime.now();

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? localEncryptedPassword,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? lastSyncAttempt,
    bool? isGoogleLinked,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      localEncryptedPassword:
          localEncryptedPassword ?? this.localEncryptedPassword,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      isGoogleLinked: isGoogleLinked ?? this.isGoogleLinked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id.isNotEmpty ? id : DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'email': email,
      'localEncryptedPassword': localEncryptedPassword,
      'syncStatus': syncStatus.name,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      'lastSyncAttempt': lastSyncAttempt?.toIso8601String(),
      'isGoogleLinked': isGoogleLinked,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      localEncryptedPassword: map['localEncryptedPassword'] as String?,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == map['syncStatus'],
        orElse: () => SyncStatus.pending,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
      lastSyncAttempt: map['lastSyncAttempt'] != null
          ? DateTime.tryParse(map['lastSyncAttempt'] as String)
          : null,
      isGoogleLinked: map['isGoogleLinked'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

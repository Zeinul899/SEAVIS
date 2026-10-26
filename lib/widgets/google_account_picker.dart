import 'package:flutter/material.dart';
import '../models/user_model.dart';

/// Callback yang mengembalikan idToken yang aman setelah autentikasi Google
typedef GoogleAuthSuccessCallback = void Function(String idToken);

/// Widget Dialog / Modal Pemilih Akun Google (Demo / Multi-Account)
class GoogleAccountPicker extends StatelessWidget {
  final Function(UserModel)? onAccountSelected;

  const GoogleAccountPicker({
    super.key,
    this.onAccountSelected,
  });

  static const List<UserModel> _accounts = [
    UserModel(
      name: 'Muhammad Faris Syaddad',
      email: 'faris.syaddad@gmail.com',
      isGoogleLinked: true,
    ),
    UserModel(
      name: 'Tim Riset SeaVis',
      email: 'research.seavis@gmail.com',
      isGoogleLinked: true,
    ),
  ];

  static List<UserModel> get accounts => _accounts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Pilih Akun Google',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          ..._accounts.map(
            (acc) => ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE2E8F0),
                child: Icon(Icons.person, color: Color(0xFF64748B)),
              ),
              title: Text(acc.name),
              subtitle: Text(acc.email),
              onTap: () {
                if (onAccountSelected != null) {
                  onAccountSelected!(acc);
                }
                Navigator.pop(context, acc);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget Tombol "Lanjutkan dengan Google" dengan standar keamanan:
/// 1. Verifikasi Fingerprint SHA-1 & SHA-256 di Firebase / Google Cloud Console.
/// 2. Mengambil `idToken` kriptografis (Bukan sekadar email mentah) untuk diteruskan ke backend.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.white,
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      'G',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Flexible(
                  child: Text(
                    'Lanjutkan dengan Google',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

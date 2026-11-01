import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final UserModel? user;
  final int currentBalance;
  final Function(String newName, String newPhone, String newPort)? onProfileUpdated;

  const ProfilePage({
    super.key,
    this.user,
    this.currentBalance = 540000,
    this.onProfileUpdated,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String _name;
  late String _email;
  late String _phone;
  String _port = 'Pantai Bandengan, Jepara';
  String _vesselName = 'KM Samudera Berkah';
  final String _vesselGt = '5 GT (Tradisional)';
  final String _partnershipDuration = '1 Tahun 4 Bulan (Bermitra sejak 15 Okt 2025)';
  final String _memberId = 'SV-NL-2025-0849';
  final String _rekeningBri = '0129-01-084729-50-2';
  final String _rekeningDana = '0812-3456-7890';

  @override
  void initState() {
    super.initState();
    _name = widget.user?.name.isNotEmpty == true ? widget.user!.name : 'Pak Anto';
    _email = widget.user?.email.isNotEmpty == true ? widget.user!.email : 'Anto@mail.com';
    _phone = '0812-3456-7890';
  }

  String _formatCurrency(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  void _showEditProfileModal() {
    final nameCtrl = TextEditingController(text: _name);
    final phoneCtrl = TextEditingController(text: _phone);
    final portCtrl = TextEditingController(text: _port);
    final vesselCtrl = TextEditingController(text: _vesselName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Edit Informasi Nelayan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor WhatsApp / HP',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: portCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Pangkalan Pantai Asal',
                    prefixIcon: Icon(Icons.anchor_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: vesselCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Perahu / Kapal',
                    prefixIcon: Icon(Icons.directions_boat_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _name = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : _name;
                        _phone = phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : _phone;
                        _port = portCtrl.text.trim().isNotEmpty ? portCtrl.text.trim() : _port;
                        _vesselName = vesselCtrl.text.trim().isNotEmpty ? vesselCtrl.text.trim() : _vesselName;
                      });
                      widget.onProfileUpdated?.call(_name, _phone, _port);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profil nelayan berhasil diperbarui!'),
                          backgroundColor: Color(0xFF059669),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C81),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Simpan Perubahan'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi SeaVis?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF), // Tema Biru Laut Halus & Bersih
      appBar: AppBar(
        title: const Text(
          'Profil Nelayan Mitra',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profil',
            onPressed: _showEditProfileModal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. KARTU HEADER PROFIL
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBAE6FD)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFF0F4C81),
                        child: Text(
                          _name.isNotEmpty ? _name[0].toUpperCase() : 'N',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Email: $_email',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF0284C7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Telp: $_phone',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined, size: 12, color: Color(0xFF0284C7)),
                              SizedBox(width: 4),
                              Text(
                                'Mitra Konservasi Karbon Aktif',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0369A1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. KARTU INFORMASI AKUN & LAMA KERJA SAMA
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.badge_outlined, size: 20, color: Color(0xFF0F4C81)),
                      SizedBox(width: 8),
                      Text(
                        'Informasi Kemitraan & Akun',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildInfoRow(
                    icon: Icons.history_edu_outlined,
                    label: 'Lama Kerja Sama',
                    value: _partnershipDuration,
                    isHighlighted: true,
                  ),
                  const Divider(height: 18, color: Color(0xFFF1F5F9)),
                  _buildInfoRow(
                    icon: Icons.fingerprint,
                    label: 'ID Mitra Nelayan',
                    value: _memberId,
                  ),
                  const Divider(height: 18, color: Color(0xFFF1F5F9)),
                  _buildInfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Basis Pangkalan Pesisir',
                    value: _port,
                  ),
                  const Divider(height: 18, color: Color(0xFFF1F5F9)),
                  _buildInfoRow(
                    icon: Icons.groups_outlined,
                    label: 'Kelompok Nelayan',
                    value: 'KUB Nelayan Bahari Sejahtera',
                  ),
                  const Divider(height: 18, color: Color(0xFFF1F5F9)),
                  _buildInfoRow(
                    icon: Icons.directions_boat_outlined,
                    label: 'Armada / Kapal Nelayan',
                    value: '$_vesselName ($_vesselGt)',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. STATISTIK KONTRIBUSI & SALDO
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.analytics_outlined, size: 20, color: Color(0xFF0D9488)),
                      SizedBox(width: 8),
                      Text(
                        'Statistik Kontribusi & Karbon',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.camera_alt_outlined,
                          title: 'Foto Disetujui',
                          value: '48 Foto',
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.eco_outlined,
                          title: 'Karbon Terserap',
                          value: '128.5 Ton',
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Saldo Siap Tarik',
                          value: 'Rp ${_formatCurrency(widget.currentBalance)}',
                          color: const Color(0xFF0F4C81),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.payments_outlined,
                          title: 'Total Insentif',
                          value: 'Rp 1.200.000',
                          color: const Color(0xFF0D9488),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4. REKENING & E-WALLET PENCAIRAN
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance_outlined, size: 20, color: Color(0xFF0284C7)),
                      SizedBox(width: 8),
                      Text(
                        'Rekening & E-Wallet Pencairan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentMethodTile(
                    title: 'Bank BRI',
                    number: _rekeningBri,
                    owner: _name,
                    icon: Icons.account_balance,
                  ),
                  const SizedBox(height: 10),
                  _buildPaymentMethodTile(
                    title: 'E-Wallet DANA',
                    number: _rekeningDana,
                    owner: _name,
                    icon: Icons.account_balance_wallet,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 5. TOMBOL AKSI
            ElevatedButton.icon(
              onPressed: _showEditProfileModal,
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Edit Data Nelayan & Kapal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F4C81),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
              label: const Text('Keluar dari Akun', style: TextStyle(color: Color(0xFFDC2626))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isHighlighted ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required String title,
    required String number,
    required String owner,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF0284C7), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  number,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
                Text(
                  'a.n. $owner',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
        ],
      ),
    );
  }
}

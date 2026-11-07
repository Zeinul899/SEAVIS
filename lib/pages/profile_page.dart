import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/esp32_support_service.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final UserModel? user;
  final int currentBalance;
  final Function(String newName, String newPhone, String newPort)? onProfileUpdated;
  final ValueChanged<int>? onBalanceUpdated;

  const ProfilePage({
    super.key,
    this.user,
    this.currentBalance = 540000,
    this.onProfileUpdated,
    this.onBalanceUpdated,
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
  late int _balance;

  final Esp32SupportService _esp32Service = Esp32SupportService();

  @override
  void initState() {
    super.initState();
    _name = widget.user?.name.isNotEmpty == true ? widget.user!.name : 'Pak Anto';
    _email = widget.user?.email.isNotEmpty == true ? widget.user!.email : 'Anto@mail.com';
    _phone = '0812-3456-7890';
    _balance = widget.currentBalance;
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  'Edit Informasi Surveyor & Armada',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap Nelayan',
                    prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF15803D)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Nomor WhatsApp / HP',
                    prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF15803D)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: portCtrl,
                  decoration: InputDecoration(
                    labelText: 'Pangkalan Pantai Asal',
                    prefixIcon: const Icon(Icons.anchor_outlined, color: Color(0xFF15803D)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: vesselCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nama Perahu / Kapal',
                    prefixIcon: const Icon(Icons.directions_boat_outlined, color: Color(0xFF15803D)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                      backgroundColor: const Color(0xFF006994),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Simpan Perubahan Profil', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTarikSaldoModal() {
    final amountController = TextEditingController(text: '50000');
    String selectedMethod = 'DANA';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.wallet, color: Color(0xFF15803D), size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pencairan Saldo Insentif',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'Transfer instan bebas biaya admin insentif',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Saldo Tersedia:', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                          Text(
                            'Rp ${_formatCurrency(_balance)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F766E)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Pilih Channel Pembayaran:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => selectedMethod = 'DANA'),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selectedMethod == 'DANA' ? const Color(0xFFECFDF5) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedMethod == 'DANA' ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
                                  width: selectedMethod == 'DANA' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('E-Wallet DANA', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                                  const SizedBox(height: 2),
                                  Text(_rekeningDana, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => selectedMethod = 'BRI'),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selectedMethod == 'BRI' ? const Color(0xFFECFDF5) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedMethod == 'BRI' ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
                                  width: selectedMethod == 'BRI' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Bank BRI', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F4C81))),
                                  const SizedBox(height: 2),
                                  Text(_rekeningBri, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Nominal Pencairan',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [50000, 100000, 200000, _balance].map((nominal) {
                        return ActionChip(
                          label: Text(
                            nominal == _balance ? 'Tarik Semua' : 'Rp ${_formatCurrency(nominal)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onPressed: () {
                            setModalState(() {
                              amountController.text = nominal.toString();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final text = amountController.text.trim();
                          if (!RegExp(r'^\d+$').hasMatch(text)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Nominal penarikan harus berupa angka bulat positif.'),
                                backgroundColor: Color(0xFFDC2626),
                              ),
                            );
                            return;
                          }
                          final amount = int.tryParse(text) ?? 0;
                          if (amount <= 0 || amount > _balance || amount < 25000) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(amount > _balance ? 'Nominal melebihi saldo.' : 'Minimal penarikan Rp 25.000'),
                                backgroundColor: const Color(0xFFDC2626),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _balance -= amount;
                          });
                          widget.onBalanceUpdated?.call(_balance);
                          Navigator.pop(ctx);
                          showDialog(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              title: const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 28),
                                  SizedBox(width: 8),
                                  Text('Pencairan Berhasil'),
                                ],
                              ),
                              content: Text(
                                'Penarikan dana sebesar Rp ${_formatCurrency(amount)} ke $selectedMethod berhasil diproses seketika.',
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('OK')),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006994),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Konfirmasi Tarik Saldo', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF006994), // Warna Biru Laut Utama (Sea Blue)
              Color(0xFF01386A), // Marine Blue / Rona Kedalaman Laut
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header Bar dengan Tombol Back & Edit
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context, _balance),
                    ),
                    const Expanded(
                      child: Text(
                        'Profil Surveyor Nelayan',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_note, color: Colors.white, size: 26),
                      tooltip: 'Edit Data Profil',
                      onPressed: _showEditProfileModal,
                    ),
                  ],
                ),
              ),

              // Isi Konten Profil Surveyor
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. KARTU IDENTITAS FIELD SURVEYOR
                      _buildSurveyorIdentityCard(),
                      const SizedBox(height: 14),

                      // 2. KARTU SALDO & PENCAIRAN INSENTIF
                      _buildBalanceCard(),
                      const SizedBox(height: 14),

                      // 3. KARTU STATUS PENGHUBUNG ESP32 (Hanya muncul jika aktif terhubung)
                      if (_esp32Service.isConnected) ...[
                        _buildEsp32StatusCard(),
                        const SizedBox(height: 14),
                      ],

                      // 4. KARTU INFORMASI KEMITRAAN & LAMA KERJA SAMA
                      _buildPartnershipInfoCard(),
                      const SizedBox(height: 14),

                      // 5. KARTU REKENING & E-WALLET PENCAIRAN
                      _buildPaymentAccountsCard(),
                      const SizedBox(height: 14),

                      // 6. TOMBOL LOGOUT
                      OutlinedButton.icon(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                        label: const Text(
                          'Keluar dari Akun SEAVIS',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white60, width: 1.2),
                          backgroundColor: Colors.black.withValues(alpha: 0.2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurveyorIdentityCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Surveyor
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _name.isNotEmpty ? _name[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FIELD SURVEYOR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15803D),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Email: $_email',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'WhatsApp / Telp: $_phone',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              // Badge ONLINE
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF86EFAC), width: 1.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ONLINE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 24, thickness: 1),
          Row(
            children: [
              Expanded(child: _subIdentityItem(Icons.anchor_outlined, 'Pangkalan', _port)),
              const SizedBox(width: 8),
              Expanded(child: _subIdentityItem(Icons.directions_boat_outlined, 'Kapal', '$_vesselName ($_vesselGt)')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _subIdentityItem(IconData icon, String title, String val) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF059669)),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              Text(
                val,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF0F766E), size: 26),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SALDO SURVEYOR',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                      Text(
                        'Rp ${_formatCurrency(_balance)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F766E)),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showTarikSaldoModal,
                icon: const Icon(Icons.payments_outlined, size: 16),
                label: const Text('Tarik Saldo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006994),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_outlined, size: 14, color: Color(0xFF16A34A)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Pencairan instan tanpa potongan biaya admin untuk nelayan.',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF15803D)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEsp32StatusCard() {
    final bool isConnected = _esp32Service.isConnected;
    final currentData = _esp32Service.currentData;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isConnected ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isConnected ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sensors,
                  color: isConnected ? const Color(0xFF15803D) : const Color(0xFF64748B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PENGHUBUNG IOT ESP32 KUALITAS AIR',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    Text(
                      isConnected
                          ? 'Terhubung (BLE) • Telemetri Kualitas Air Aktif'
                          : 'Belum Terhubung (Opsional untuk data penunjang)',
                      style: TextStyle(
                        fontSize: 11,
                        color: isConnected ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () async {
                  if (isConnected) {
                    _esp32Service.disconnectEsp32();
                  } else {
                    await _esp32Service.connectToEsp32();
                  }
                  setState(() {});
                },
                child: Text(
                  isConnected ? 'Putus' : 'Sambungkan',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isConnected ? const Color(0xFFDC2626) : const Color(0xFF006994),
                  ),
                ),
              ),
            ],
          ),
          if (isConnected) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _espMetricBadge('Suhu', '${currentData.waterTempC ?? 28.5}°C'),
                _espMetricBadge('pH', '${currentData.ph ?? 8.1}'),
                _espMetricBadge('TDS', '${currentData.tdsPpm ?? 345} ppm'),
                _espMetricBadge('Turbidity', '${currentData.turbidityNtu ?? 3.4} NTU'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _espMetricBadge(String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFF15803D))),
          Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF14532D))),
        ],
      ),
    );
  }

  Widget _buildPartnershipInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.handshake_outlined, size: 20, color: Color(0xFF006994)),
              SizedBox(width: 8),
              Text(
                'Informasi Kemitraan Konservasi',
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
            icon: Icons.groups_outlined,
            label: 'Kelompok Nelayan',
            value: 'KUB Nelayan Bahari Sejahtera',
          ),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Pangkalan Pantai Asal',
            value: _port,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentAccountsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.credit_card_outlined, size: 20, color: Color(0xFF006994)),
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
          _buildPaymentTile(
            title: 'Bank BRI',
            number: _rekeningBri,
            owner: _name,
            icon: Icons.account_balance,
          ),
          const SizedBox(height: 10),
          _buildPaymentTile(
            title: 'E-Wallet DANA',
            number: _rekeningDana,
            owner: _name,
            icon: Icons.account_balance_wallet,
          ),
        ],
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
                  color: isHighlighted ? const Color(0xFF059669) : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentTile({
    required String title,
    required String number,
    required String owner,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF15803D), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text(number, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                Text('a.n. $owner', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
        ],
      ),
    );
  }
}

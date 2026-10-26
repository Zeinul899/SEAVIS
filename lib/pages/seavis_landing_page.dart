import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/fisherman_data.dart';
import 'login_page.dart';

class SeaVisLandingPage extends StatefulWidget {
  final UserModel? user;

  const SeaVisLandingPage({
    super.key,
    this.user,
  });

  @override
  State<SeaVisLandingPage> createState() => _SeaVisLandingPageState();
}

class _SeaVisLandingPageState extends State<SeaVisLandingPage> {
  // Tab index aktif: 0 = Beranda, 1 = Kirim Foto, 2 = Tarik Tunai, 3 = Tanya AI
  int _activeTabIndex = 0;

  // Data Profil Nelayan (Bisa diedit via modal profil)
  late String _fishermanName;
  late String _fishermanPhone;
  String _fishermanPort = 'PPI Muara Baru, Teluk Jakarta';
  String _vesselName = 'KM Samudera Berkah';
  String _vesselGt = '5 GT (Tradisional)';
  final String _rekeningBri = '0129-01-084729-50-2';
  final String _rekeningDana = '0812-3456-7890';
  final String _kusukaId = 'ID-KKP-772910-JKT';

  // State Keuangan & Kuota Foto
  // Aturan: Rp 25.000 per foto, kuota maksimal 5 foto per hari
  static const int _rewardPerFoto = 25000;
  static const int _maxDailyPhotos = 5;

  int _currentBalance = 50000; // Saldo awal (misal dari 2 foto sebelumnya)

  // Daftar foto tangkapan hari ini (dimulai dengan 2 foto contoh yang sudah valid)
  final List<FishermanPhoto> _todayPhotos = [
    FishermanPhoto(
      id: 'photo-1',
      title: 'Tangkapan Ikan Tongkol Segar (25 Kg)',
      category: 'Hasil Tangkapan Laut',
      location: 'Dermaga 2 Muara Baru - WPPNRI 712',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      reward: _rewardPerFoto,
      status: 'Disetujui',
      sampleIcon: Icons.set_meal_rounded,
      iconColor: const Color(0xFF0284C7),
    ),
    FishermanPhoto(
      id: 'photo-2',
      title: 'Kondisi Permukaan Laut & Gelombang Tenang',
      category: 'Observasi Kelautan',
      location: 'Muara Baru Kolam Labuh - WPPNRI 712',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      reward: _rewardPerFoto,
      status: 'Disetujui',
      sampleIcon: Icons.water_rounded,
      iconColor: const Color(0xFF0F766E),
    ),
  ];

  // Riwayat Penarikan Tunai
  final List<WithdrawalRecord> _withdrawalHistory = [
    WithdrawalRecord(
      id: 'WD-8910',
      amount: 50000,
      channel: 'DANA',
      destinationNumber: '0812-3456-7890',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      status: 'Berhasil',
    ),
  ];

  // Form Pengiriman Foto
  final TextEditingController _photoNoteController = TextEditingController();
  String _selectedCategory = 'Hasil Ikan Tangkapan';
  int _selectedPresetIndex = 0;
  bool _isUploading = false;

  // Contoh preset foto tangkapan nelayan yang realistis
  final List<Map<String, dynamic>> _catchPresets = [
    {
      'title': 'Ikan Tongkol & Cakalang Pagi',
      'category': 'Hasil Tangkapan Laut',
      'icon': Icons.set_meal_rounded,
      'color': Color(0xFF0284C7),
      'defaultNote': 'Hasil tangkapan 35 kg tongkol segar jaring insang pagi.',
    },
    {
      'title': 'Ikan Kakap Merah Segar',
      'category': 'Hasil Tangkapan Laut',
      'icon': Icons.phishing_rounded,
      'color': Color(0xFFDC2626),
      'defaultNote': 'Tangkapan pancing ulur kakap merah ukuran sedang 15 kg.',
    },
    {
      'title': 'Kondisi Ombak & Kejernihan Air Laut',
      'category': 'Observasi Kelautan',
      'icon': Icons.waves_rounded,
      'color': Color(0xFF0D9488),
      'defaultNote': 'Kondisi laut tenang, tinggi gelombang sekitar 0.7 meter.',
    },
    {
      'title': 'Aktivitas Bongkar Ikan di Dermaga',
      'category': 'Aktivitas Pelabuhan',
      'icon': Icons.sailing_rounded,
      'color': Color(0xFF4F46E5),
      'defaultNote': 'Kapal sandar dengan selamat di dermaga pendaratan ikan.',
    },
  ];

  // State Form Tarik Tunai
  String _selectedWithdrawMethod = 'DANA';
  final TextEditingController _withdrawAmountController =
      TextEditingController();
  bool _isProcessingWithdraw = false;

  // State AI Chat
  final TextEditingController _chatInputController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  bool _isAiTyping = false;
  final List<ChatMessage> _chatMessages = [
    ChatMessage(
      id: 'msg-0',
      text:
          'Halo Pak Nelayan! Selamat datang di Sahabat Nelayan AI SeaVis.\n\nSaya siap membantu menjawab pertanyaan seputar:\n• Pengiriman foto tangkapan (Rp 25.000/foto)\n• Batas kuota 5 foto per hari\n• Cara tarik tunai saldo ke rekening/e-wallet\n• Prakiraan cuaca & kondisi melaut\n\nSilakan pilih pertanyaan cepat di bawah atau ketik langsung keluhan Anda.',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fishermanName = widget.user?.name.isNotEmpty == true
        ? widget.user!.name
        : 'Pak Joko Susanto';
    _fishermanPhone = '0812-3456-7890';
    _photoNoteController.text =
        _catchPresets[_selectedPresetIndex]['defaultNote'] as String;
  }

  @override
  void dispose() {
    _photoNoteController.dispose();
    _withdrawAmountController.dispose();
    _chatInputController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  // Sisa kuota foto hari ini
  int get _remainingPhotos =>
      (_maxDailyPhotos - _todayPhotos.length).clamp(0, _maxDailyPhotos);

  // ---------------------------------------------------------------------------
  // DIALOG / BOTTOM SHEET PROFIL NELAYAN
  // ---------------------------------------------------------------------------
  void _openFishermanProfile() {
    final nameController = TextEditingController(text: _fishermanName);
    final phoneController = TextEditingController(text: _fishermanPhone);
    final portController = TextEditingController(text: _fishermanPort);
    final vesselController = TextEditingController(text: _vesselName);
    final vesselGtController = TextEditingController(text: _vesselGt);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                    // Handle drag bar
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

                    // Header profil dengan avatar besar
                    Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: const Color(0xFF0F4C81),
                              child: Text(
                                _fishermanName.isNotEmpty
                                    ? _fishermanName[0].toUpperCase()
                                    : 'N',
                                style: const TextStyle(
                                  fontSize: 32,
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
                                  color: Color(0xFF059669),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                ),
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
                                _fishermanName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFA7F3D0),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_user_rounded,
                                      size: 13,
                                      color: Color(0xFF059669),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Nelayan Terverifikasi KKP',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF065F46),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'KUSUKA: $_kusukaId',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 16),

                    const Text(
                      'Informasi Data Nelayan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Input Nama
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap Nelayan',
                        prefixIcon: Icon(Icons.person_outline),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Input No WhatsApp/HP
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Nomor WhatsApp / HP',
                        prefixIcon: Icon(Icons.phone_outlined),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Input Asal Pangkalan / Pelabuhan
                    TextField(
                      controller: portController,
                      decoration: const InputDecoration(
                        labelText: 'Pangkalan / Pelabuhan Asal',
                        prefixIcon: Icon(Icons.anchor_outlined),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Input Kapal
                    TextField(
                      controller: vesselController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kapal Nelayan',
                        prefixIcon: Icon(Icons.directions_boat_outlined),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Input Kapasitas GT
                    TextField(
                      controller: vesselGtController,
                      decoration: const InputDecoration(
                        labelText: 'Kapasitas & Tipe Kapal (Gross Tonnage)',
                        prefixIcon: Icon(Icons.speed_outlined),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Rekening pencairan
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
                            'Rekening & E-Wallet Terdaftar:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.account_balance,
                                  size: 16, color: Color(0xFF0F4C81)),
                              const SizedBox(width: 8),
                              Text('Bank BRI: $_rekeningBri',
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.account_balance_wallet,
                                  size: 16, color: Color(0xFF0284C7)),
                              const SizedBox(width: 8),
                              Text('DANA: $_rekeningDana',
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _fishermanName = nameController.text.trim().isNotEmpty
                                ? nameController.text.trim()
                                : _fishermanName;
                            _fishermanPhone = phoneController.text.trim().isNotEmpty
                                ? phoneController.text.trim()
                                : _fishermanPhone;
                            _fishermanPort = portController.text.trim().isNotEmpty
                                ? portController.text.trim()
                                : _fishermanPort;
                            _vesselName = vesselController.text.trim().isNotEmpty
                                ? vesselController.text.trim()
                                : _vesselName;
                            _vesselGt = vesselGtController.text.trim().isNotEmpty
                                ? vesselGtController.text.trim()
                                : _vesselGt;
                          });
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Tombol Keluar / Ganti Akun
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.logout_rounded,
                            size: 16, color: Color(0xFFDC2626)),
                        label: const Text(
                          'Keluar ke Halaman Login',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  // ---------------------------------------------------------------------------
  // LOGIKA PENGIRIMAN FOTO TANGKAPAN
  // ---------------------------------------------------------------------------
  void _submitCatchPhoto() async {
    if (_todayPhotos.length >= _maxDailyPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Batas kuota 5 foto hari ini telah tercapai. Kuota akan kembali dibuka besok!',
          ),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    // Simulasi pengunggahan cepat (1 detik)
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    final preset = _catchPresets[_selectedPresetIndex];
    final customNote = _photoNoteController.text.trim();
    final photoTitle = customNote.isNotEmpty
        ? customNote
        : (preset['title'] as String);

    final newPhoto = FishermanPhoto(
      id: 'photo-${DateTime.now().millisecondsSinceEpoch}',
      title: photoTitle,
      category: _selectedCategory,
      location: 'Dermaga Muara Baru - WPPNRI 712',
      timestamp: DateTime.now(),
      reward: _rewardPerFoto,
      status: 'Disetujui',
      sampleIcon: preset['icon'] as IconData,
      iconColor: preset['color'] as Color,
    );

    setState(() {
      _todayPhotos.insert(0, newPhoto);
      _currentBalance += _rewardPerFoto;
      _isUploading = false;
    });

    // Dialog Konfirmasi Hadiah Rp 25.000
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 28),
            SizedBox(width: 10),
            Text('Foto Diterima!', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Laporan foto tangkapan laut berhasil divalidasi oleh sistem SeaVis.',
              style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on,
                      color: Color(0xFF059669), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reward Masuk ke Saldo:',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF065F46),
                          ),
                        ),
                        Text(
                          '+Rp ${_formatCurrency(_rewardPerFoto)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sisa kuota foto hari ini: $_remainingPhotos dari $_maxDailyPhotos kali.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _activeTabIndex = 2; // Beralih ke tab Tarik Tunai
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F4C81),
              foregroundColor: Colors.white,
            ),
            child: const Text('Lihat & Tarik Saldo'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LOGIKA PENARIKAN TUNAI
  // ---------------------------------------------------------------------------
  void _executeWithdrawal() async {
    final amountText = _withdrawAmountController.text.trim();
    final amount = int.tryParse(amountText.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nominal penarikan yang valid.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (amount > _currentBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal penarikan melebihi saldo yang tersedia.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (amount < 25000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal penarikan adalah Rp 25.000.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() {
      _isProcessingWithdraw = true;
    });

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    final targetAccount = _selectedWithdrawMethod == 'DANA' ||
            _selectedWithdrawMethod == 'OVO' ||
            _selectedWithdrawMethod == 'GoPay'
        ? _rekeningDana
        : _rekeningBri;

    final newWithdrawal = WithdrawalRecord(
      id: 'WD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      amount: amount,
      channel: _selectedWithdrawMethod,
      destinationNumber: targetAccount,
      timestamp: DateTime.now(),
      status: 'Berhasil',
    );

    setState(() {
      _currentBalance -= amount;
      _withdrawalHistory.insert(0, newWithdrawal);
      _withdrawAmountController.clear();
      _isProcessingWithdraw = false;
    });

    // Struk / Konfirmasi Pencairan Digital
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 28),
            SizedBox(width: 10),
            Text('Penarikan Berhasil', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dana pencairan telah dikirimkan ke rekening tujuan Anda tanpa biaya admin.',
              style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _receiptRow('Jumlah Ditarik', 'Rp ${_formatCurrency(amount)}',
                      isBold: true),
                  const SizedBox(height: 6),
                  _receiptRow('Metode Pencairan', _selectedWithdrawMethod),
                  const SizedBox(height: 6),
                  _receiptRow('Rekening/Nomor', targetAccount),
                  const SizedBox(height: 6),
                  _receiptRow('Nama Penerima', _fishermanName),
                  const SizedBox(height: 6),
                  _receiptRow('Biaya Admin', 'Rp 0 (Gratis)'),
                  const Divider(height: 12, color: Color(0xFFE2E8F0)),
                  _receiptRow(
                      'Sisa Saldo Anda', 'Rp ${_formatCurrency(_currentBalance)}',
                      color: const Color(0xFF059669)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F4C81),
              foregroundColor: Colors.white,
            ),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // LOGIKA AI CHAT
  // ---------------------------------------------------------------------------
  void _sendChatMessage([String? customPrompt]) async {
    final text = customPrompt ?? _chatInputController.text.trim();
    if (text.isEmpty) return;

    if (customPrompt == null) {
      _chatInputController.clear();
    }

    final userMsg = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _chatMessages.add(userMsg);
      _isAiTyping = true;
    });

    _scrollChatToBottom();

    // Simulasi respon asisten pintar AI nelayan
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    final lower = text.toLowerCase();
    String responseText;

    if (lower.contains('reward') || lower.contains('25') || lower.contains('hadiah') || lower.contains('bayar')) {
      responseText =
          'Setiap foto tangkapan atau kondisi laut yang Anda kirimkan bernilai Rp 25.000 per foto. Saldo langsung masuk otomatis setelah foto dikirim!';
    } else if (lower.contains('limit') || lower.contains('batas') || lower.contains('5')) {
      responseText =
          'Batas pengiriman foto dibatasi maksimal 5 kali sehari (Maksimal Rp 125.000/hari). Kuota akan direset setiap pukul 00:00 WIB tengah malam.';
    } else if (lower.contains('tarik') || lower.contains('cair') || lower.contains('dana') || lower.contains('bri')) {
      responseText =
          'Untuk menarik uang, buka menu "Tarik Tunai" di tab navigasi bawah. Anda bisa mencairkan saldo minimal Rp 25.000 langsung ke rekening Bank BRI atau e-wallet DANA tanpa potongan biaya admin.';
    } else if (lower.contains('cuaca') || lower.contains('ombak') || lower.contains('angin')) {
      responseText =
          'Prakiraan cuaca perairan hari ini: Gelombang berkisar 0.6 - 0.9 meter (kategori tenang/aman), arah angin Barat Daya kecepatan 10-12 knot. Aman untuk kegiatan melaut.';
    } else if (lower.contains('ikan') || lower.contains('tips') || lower.contains('kriteria') || lower.contains('foto')) {
      responseText =
          'Tips agar foto cepat diverifikasi:\n1. Pastikan foto cukup terang & tidak buram\n2. Tampilkan jenis ikan atau hasil jaring secara jelas\n3. Boleh menyertakan latar kapal atau dermaga pelabuhan.';
    } else {
      responseText =
          'Terima kasih atas pertanyaannya, Pak Nelayan. Terkait "$text", sistem kami telah mencatatnya. Untuk bantuan darurat di laut atau verifikasi manual, Anda juga dapat menghubungi posko dermaga atau tim SeaVis.';
    }

    final aiMsg = ChatMessage(
      id: 'msg-ai-${DateTime.now().millisecondsSinceEpoch}',
      text: responseText,
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _isAiTyping = false;
      _chatMessages.add(aiMsg);
    });

    _scrollChatToBottom();
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatCurrency(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  // ---------------------------------------------------------------------------
  // BUILD METHOD & APP BAR
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Warna latar tenang, tidak mencolok
      appBar: _buildCleanAppBar(),
      body: IndexedStack(
        index: _activeTabIndex,
        children: [
          _buildBerandaTab(),
          _buildKirimFotoTab(),
          _buildTarikTunaiTab(),
          _buildAiChatTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // App Bar Bersih dengan Foto Profil Nelayan yang bisa ditekan
  PreferredSizeWidget _buildCleanAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A),
      elevation: 0,
      scrolledUnderElevation: 1,
      titleSpacing: 16,
      title: Row(
        children: [
          // Logo / Icon SeaVis
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F4C81),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.sailing_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SeaVis Nelayan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Portal Observasi & Reward Tangkapan',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Tombol / Foto Profil yang bisa dipencet oleh nelayan
        Padding(
          padding: const EdgeInsets.only(right: 14.0),
          child: InkWell(
            onTap: _openFishermanProfile, // Buka data profil nelayan saat ditekan
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFF0F4C81),
                    child: Text(
                      _fishermanName.isNotEmpty
                          ? _fishermanName[0].toUpperCase()
                          : 'N',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 85),
                    child: Text(
                      _fishermanName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 0: BERANDA (TAMPILAN UTAMA BERSIH & RAPI)
  // Desain ramah nelayan: Tanpa tumpukan kartu berlebih & tanpa gradasi memusingkan
  // ---------------------------------------------------------------------------
  Widget _buildBerandaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ucapan salam & status kapal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, $_fishermanName',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_fishermanPort • $_vesselName ($_vesselGt)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              // Tombol buka profil langsung
              OutlinedButton.icon(
                onPressed: _openFishermanProfile,
                icon: const Icon(Icons.person_rounded, size: 14),
                label: const Text('Profil', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  foregroundColor: const Color(0xFF0F4C81),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // PANEL UTAMA: RINGKASAN SALDO & KUOTA FOTO
          // Solid background elegan, bersih, tanpa gradasi pelangi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                // Baris Saldo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saldo Siap Ditarik',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rp ${_formatCurrency(_currentBalance)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F4C81),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _activeTabIndex = 2; // Ke tab Tarik Tunai
                        });
                      },
                      icon: const Icon(Icons.account_balance_wallet_outlined,
                          size: 16),
                      label: const Text('Tarik Tunai'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F4C81),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 14),

                // Baris Kuota Foto Hari Ini (5x per hari, Rp 25rb per foto)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Color(0xFF059669),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Kuota Foto Hari Ini',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                '${_todayPhotos.length} / $_maxDailyPhotos Terkirim',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _remainingPhotos > 0
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _remainingPhotos > 0
                                ? 'Sisa $_remainingPhotos foto lagi (Rp 25.000 / foto)'
                                : 'Batas 5 foto hari ini sudah tercapai',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _activeTabIndex = 1; // Ke tab Kirim Foto
                        });
                      },
                      child: const Text('Kirim', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // INFORMASI CUACA MELAUT (Minimalis & Ringkas)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.waves_rounded,
                  color: Color(0xFF0284C7),
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prakiraan Laut: Gelombang 0.6 - 0.9 m (Tenang)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Angin 10 knot Barat Daya • Aman untuk melaut & menjaring.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Aman',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // PANDUAN RINGKAS PROGRAM REWARD
          const Text(
            'Aturan & Panduan Foto Nelayan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _guideItem(
                  icon: Icons.camera_alt_outlined,
                  title: 'Ambil Foto Tangkapan / Kondisi Laut',
                  desc: 'Foto ikan di jaring, palka, atau kondisi perairan.',
                ),
                const Divider(height: 14, color: Color(0xFFF1F5F9)),
                _guideItem(
                  icon: Icons.monetization_on_outlined,
                  title: 'Imbalan Rp 25.000 Per Foto',
                  desc: 'Setiap foto yang valid langsung ditambahkan ke saldo.',
                ),
                const Divider(height: 14, color: Color(0xFFF1F5F9)),
                _guideItem(
                  icon: Icons.timelapse_rounded,
                  title: 'Batas Maksimal 5 Foto Per Hari',
                  desc: 'Maksimal Rp 125.000/hari. Kuota direset tiap tengah malam.',
                ),
                const Divider(height: 14, color: Color(0xFFF1F5F9)),
                _guideItem(
                  icon: Icons.account_balance_outlined,
                  title: 'Tarik Tunai Kapan Saja',
                  desc: 'Pencairan instan ke Bank BRI atau DANA tanpa potongan.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // CUPLIKAN FOTO TANGKAPAN TERKIRIM HARI INI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Laporan Foto Terkirim Hari Ini',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                '${_todayPhotos.length} Foto',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_todayPhotos.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text(
                  'Belum ada foto yang dikirim hari ini.\nTekan tab "Kirim Foto" untuk dapatkan Rp 25.000!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            ..._todayPhotos.map((photo) => _buildPhotoListTile(photo)),
        ],
      ),
    );
  }

  Widget _guideItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0F4C81)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                desc,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: KIRIM FOTO (UPLOAD FOTO + LIMIT 5 KALI SAJA + REWARD RP 25.000)
  // ---------------------------------------------------------------------------
  Widget _buildKirimFotoTab() {
    final bool isLimitReached = _todayPhotos.length >= _maxDailyPhotos;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Tab
          const Text(
            'Kirim Foto Tangkapan Laut',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Dapatkan imbalan Rp 25.000 setiap pengiriman foto valid. Dibatasi 5 kali pengiriman per hari.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 16),

          // INDIKATOR KUOTA 5 FOTO HARI INI
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isLimitReached
                    ? const Color(0xFFFCA5A5)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status Kuota Harian (${_todayPhotos.length}/$_maxDailyPhotos)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      isLimitReached ? 'Kuota Penuh' : 'Sisa $_remainingPhotos Foto',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isLimitReached
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 5 Kotak Indikator visual
                Row(
                  children: List.generate(_maxDailyPhotos, (index) {
                    final isFilled = index < _todayPhotos.length;
                    return Expanded(
                      child: Container(
                        height: 8,
                        margin: EdgeInsets.only(
                            right: index < _maxDailyPhotos - 1 ? 6 : 0),
                        decoration: BoxDecoration(
                          color: isFilled
                              ? const Color(0xFF059669)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 10),
                Text(
                  isLimitReached
                      ? 'Hebat! Anda sudah mengirim 5 foto hari ini (Total Rp 125.000 terkumpul). Kuota baru akan aktif besok pukul 00:00 WIB.'
                      : 'Kirimkan $_remainingPhotos foto lagi untuk memaksimalkan tambahan saldo hingga Rp ${_formatCurrency(_remainingPhotos * _rewardPerFoto)} hari ini.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isLimitReached
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // KONTEN PENGIRIMAN ATAU BANNER LIMIT TERCAPAI
          if (isLimitReached)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.lock_clock_rounded,
                    color: Color(0xFFDC2626),
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Batas Maksimal 5 Foto Tercapai',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Anda telah mengirim 5 foto hari ini. Seluruh imbalan Rp 125.000 sudah masuk ke saldo Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _activeTabIndex = 2; // Ke tab Tarik Tunai
                      });
                    },
                    icon: const Icon(Icons.account_balance_wallet, size: 16),
                    label: const Text('Cairkan Saldo Sekarang'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C81),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // FORM INPUT FOTO BARU
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Jenis Foto Tangkapan / Observasi:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Pilihan cepat contoh foto tangkapan
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_catchPresets.length, (index) {
                      final preset = _catchPresets[index];
                      final isSelected = _selectedPresetIndex == index;
                      return ChoiceChip(
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _selectedPresetIndex = index;
                              _selectedCategory = preset['category'] as String;
                              _photoNoteController.text =
                                  preset['defaultNote'] as String;
                            });
                          }
                        },
                        avatar: Icon(
                          preset['icon'] as IconData,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : (preset['color'] as Color),
                        ),
                        label: Text(
                          preset['title'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        selectedColor: const Color(0xFF0F4C81),
                        backgroundColor: const Color(0xFFF1F5F9),
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  // Area Preview Foto Tangkapan
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _catchPresets[_selectedPresetIndex]['icon'] as IconData,
                          size: 48,
                          color: _catchPresets[_selectedPresetIndex]['color']
                              as Color,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _catchPresets[_selectedPresetIndex]['title'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Kamera & GPS Aktif • Lokasi: Dermaga Muara Baru',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Input Catatan / Keterangan
                  const Text(
                    'Keterangan / Catatan Tangkapan:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _photoNoteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Misal: Tangkapan 30 kg tongkol jaring pagi...',
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tombol Kirim Foto
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _submitCatchPhoto,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _isUploading
                            ? 'Memproses Unggahan...'
                            : 'Kirim Foto (+Rp ${_formatCurrency(_rewardPerFoto)})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // DAFTAR FOTO HARI INI
          Text(
            'Riwayat Pengiriman Hari Ini (${_todayPhotos.length}/$_maxDailyPhotos)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),

          ..._todayPhotos.map((photo) => _buildPhotoListTile(photo)),
        ],
      ),
    );
  }

  Widget _buildPhotoListTile(FishermanPhoto photo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(photo.sampleIcon, color: photo.iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${photo.location} • ${_formatTime(photo.timestamp)}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Text(
              '+Rp ${_formatCurrency(photo.reward)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF059669),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: TARIK TUNAI (PENCAIRAN SALDO REWARD KE BANK BRI / DANA)
  // ---------------------------------------------------------------------------
  Widget _buildTarikTunaiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pencairan & Tarik Tunai',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cairkan hasil reward pengiriman foto Anda ke rekening bank atau e-wallet tanpa biaya admin.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 16),

          // KARTU SALDO UTAMA (Simpel, bersih, kontras tinggi)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F4C81), // Solid Deep Navy
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saldo Tersedia',
                      style: TextStyle(fontSize: 12, color: Color(0xFFBAE6FD)),
                    ),
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFFBAE6FD),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Rp ${_formatCurrency(_currentBalance)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Dari total ${_todayPhotos.length} foto tangkapan yang disetujui hari ini',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFE2E8F0)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // FORM PENARIKAN TUNAI
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Metode Pencairan:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 10),

                // Pilihan metode (DANA, BRI, Mandiri, BCA)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['DANA', 'Bank BRI', 'GoPay', 'Bank Mandiri', 'BCA']
                      .map((method) {
                    final isSelected = _selectedWithdrawMethod == method;
                    return ChoiceChip(
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedWithdrawMethod = method;
                          });
                        }
                      },
                      label: Text(
                        method,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isSelected ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      selectedColor: const Color(0xFF0F4C81),
                      backgroundColor: const Color(0xFFF1F5F9),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Input Nomor Rekening / E-Wallet
                const Text(
                  'Nomor Rekening / Akun Tujuan:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card,
                          size: 18, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedWithdrawMethod == 'Bank BRI'
                              ? '$_rekeningBri (BRI a/n $_fishermanName)'
                              : '$_rekeningDana (DANA a/n $_fishermanName)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Pilihan Cepat Nominal
                const Text(
                  'Pilih Nominal Penarikan:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [25000, 50000, 75000, 100000].map((nominal) {
                    return ActionChip(
                      onPressed: () {
                        setState(() {
                          _withdrawAmountController.text = nominal.toString();
                        });
                      },
                      label: Text('Rp ${_formatCurrency(nominal)}',
                          style: const TextStyle(fontSize: 11)),
                      backgroundColor: const Color(0xFFF1F5F9),
                    );
                  }).toList()
                    ..add(
                      ActionChip(
                        onPressed: () {
                          setState(() {
                            _withdrawAmountController.text =
                                _currentBalance.toString();
                          });
                        },
                        label: const Text('Tarik Semua',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F4C81))),
                        backgroundColor: const Color(0xFFE0F2FE),
                      ),
                    ),
                ),

                const SizedBox(height: 12),

                // Input Manual Nominal
                TextField(
                  controller: _withdrawAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nominal Pencairan (Rp)',
                    hintText: 'Minimal Rp 25.000',
                    prefixText: 'Rp ',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),

                const SizedBox(height: 16),

                // Tombol Tarik Tunai
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isProcessingWithdraw || _currentBalance < 25000)
                        ? null
                        : _executeWithdrawal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C81),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isProcessingWithdraw
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Tarik Tunai Sekarang',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // RIWAYAT PENARIKAN TUNAI
          const Text(
            'Riwayat Penarikan Saldo',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),

          if (_withdrawalHistory.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text(
                  'Belum ada riwayat penarikan saldo.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            ..._withdrawalHistory.map((rec) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.arrow_circle_up_rounded,
                          color: Color(0xFF0F4C81),
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pencairan via ${rec.channel}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '${rec.destinationNumber} • ${_formatTime(rec.timestamp)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '-Rp ${_formatCurrency(rec.amount)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Text(
                          'Berhasil',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: AI CHAT (TANYA JAWAB NELAYAN)
  // ---------------------------------------------------------------------------
  Widget _buildAiChatTab() {
    return Column(
      children: [
        // Header Chat
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Color(0xFF0284C7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sahabat Nelayan AI',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Bantuan otomatis info reward, foto & cuaca',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Daftar Pesan Chat
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              final msg = _chatMessages[index];
              return _buildChatBubble(msg);
            },
          ),
        ),

        // Indikator AI Sedang Mengetik
        if (_isAiTyping)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF0F4C81),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Sahabat Nelayan AI sedang mengetik...',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

        // Pertanyaan Cepat (Quick FAQ Chips)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _quickChatChip('Berapa reward per foto?'),
                _quickChatChip('Batas 5 foto hari ini'),
                _quickChatChip('Cara tarik uang ke BRI/DANA'),
                _quickChatChip('Prakiraan cuaca melaut'),
                _quickChatChip('Tips foto ikan valid'),
              ],
            ),
          ),
        ),

        // Input Bar Pesan
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatInputController,
                    onSubmitted: (val) => _sendChatMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Tanyakan sesuatu seputar foto/saldo/laut...',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _sendChatMessage(),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C81),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickChatChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        onPressed: () => _sendChatMessage(label),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        backgroundColor: const Color(0xFFF1F5F9),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isUser ? const Color(0xFF0F4C81) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(msg.isUser ? 14 : 2),
            bottomRight: Radius.circular(msg.isUser ? 2 : 14),
          ),
          border: Border.all(
            color: msg.isUser
                ? const Color(0xFF0F4C81)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: msg.isUser ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(msg.timestamp),
              style: TextStyle(
                fontSize: 9,
                color: msg.isUser
                    ? const Color(0xFFBAE6FD)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM NAVIGATION BAR
  // Beranda | Kirim Foto (Badge Kuota) | Tarik Tunai | Tanya AI
  // ---------------------------------------------------------------------------
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: BottomNavigationBar(
        currentIndex: _activeTabIndex,
        onTap: (index) {
          setState(() {
            _activeTabIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0F4C81),
        unselectedItemColor: const Color(0xFF64748B),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('$_remainingPhotos'),
              backgroundColor: _remainingPhotos > 0
                  ? const Color(0xFF059669)
                  : const Color(0xFF94A3B8),
              child: const Icon(Icons.camera_alt_outlined),
            ),
            activeIcon: Badge(
              label: Text('$_remainingPhotos'),
              backgroundColor: _remainingPhotos > 0
                  ? const Color(0xFF059669)
                  : const Color(0xFF94A3B8),
              child: const Icon(Icons.camera_alt_rounded),
            ),
            label: 'Kirim Foto',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Tarik Tunai',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            activeIcon: Icon(Icons.smart_toy_rounded),
            label: 'Tanya AI',
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute WIB';
  }
}

// Alias agar kompatibel dengan penamaan alternatif
typedef SeavisLandingPage = SeaVisLandingPage;

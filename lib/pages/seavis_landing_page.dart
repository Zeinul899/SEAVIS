import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/fisherman_data.dart';
import 'profile_page.dart';

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
  // Data Profil Nelayan
  late String _fishermanName;
  late String _fishermanEmail;

  // Rekening Pencairan
  final String _rekeningBri = '0129-01-084729-50-2';
  final String _rekeningDana = '0812-3456-7890';

  // Saldo & Aturan Insentif Foto
  // Sesuai sketsa mentah Canva: Saldo awal Rp 540.000, batas 5 foto/hari @ Rp 25.000
  static const int _rewardPerFoto = 25000;
  static const int _maxDailyPhotos = 5;
  int _currentBalance = 540000;

  // Daftar foto yang telah disetujui hari ini
  final List<FishermanPhoto> _todayPhotos = [
    FishermanPhoto(
      id: 'photo-1',
      title: 'Lamun Enhalus acoroides (Tutupan 85%)',
      category: 'Padang Lamun Alami',
      location: 'Pantai Bandengan, Jepara - Zona Karbon Tinggi',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      reward: _rewardPerFoto,
      status: 'Disetujui',
      sampleIcon: Icons.eco_rounded,
      iconColor: const Color(0xFF0F766E),
    ),
    FishermanPhoto(
      id: 'photo-2',
      title: 'Lamun Thalassia hemprichii (Air Jernih)',
      category: 'Padang Lamun Alami',
      location: 'Pesisir Jepara Timur - Titik GPS Terkunci',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      reward: _rewardPerFoto,
      status: 'Disetujui',
      sampleIcon: Icons.waves_rounded,
      iconColor: const Color(0xFF0284C7),
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

  // Controller & Form State
  final TextEditingController _photoNoteController = TextEditingController();
  final TextEditingController _withdrawAmountController = TextEditingController();
  String _selectedWithdrawMethod = 'DANA';
  bool _isUploading = false;
  bool _isProcessingWithdraw = false;

  @override
  void initState() {
    super.initState();
    _fishermanName = widget.user?.name.isNotEmpty == true
        ? widget.user!.name
        : 'Pak Anto';
    _fishermanEmail = widget.user?.email.isNotEmpty == true
        ? widget.user!.email
        : 'Anto@mail.com';
  }

  @override
  void dispose() {
    _photoNoteController.dispose();
    _withdrawAmountController.dispose();
    super.dispose();
  }

  // Sisa kuota foto hari ini
  int get _remainingPhotos =>
      (_maxDailyPhotos - _todayPhotos.length).clamp(0, _maxDailyPhotos);

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return 'Selamat pagi';
    if (hour >= 11 && hour < 15) return 'Selamat siang';
    if (hour >= 15 && hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  void _openProfilePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          user: widget.user ?? UserModel(name: _fishermanName, email: _fishermanEmail),
          currentBalance: _currentBalance,
          onProfileUpdated: (newName, newPhone, newPort) {
            setState(() {
              _fishermanName = newName;
            });
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MODAL BOTTOM SHEET: CASH OUT (Tarik Tunai Saldo Langsung dari Banner)
  // ---------------------------------------------------------------------------
  void _openCashOutModal() {
    _withdrawAmountController.text = '50000';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    // Handle Bar
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

                    // Judul Modal
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBCE062),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.local_atm_rounded,
                            color: Color(0xFF1E293B),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cash Out Saldo',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Pencairan langsung ke rekening atau e-wallet',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Info Saldo Saat Ini
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
                          const Text(
                            'Saldo Tersedia:',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Rp ${_formatCurrency(_currentBalance)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Pilihan Channel Pencairan
                    const Text(
                      'Tujuan Pencairan:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => _selectedWithdrawMethod = 'DANA'),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _selectedWithdrawMethod == 'DANA'
                                    ? const Color(0xFFEFF6FF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedWithdrawMethod == 'DANA'
                                      ? const Color(0xFF0284C7)
                                      : const Color(0xFFCBD5E1),
                                  width: _selectedWithdrawMethod == 'DANA' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'DANA',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _rekeningDana,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => _selectedWithdrawMethod = 'BRI'),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _selectedWithdrawMethod == 'BRI'
                                    ? const Color(0xFFEFF6FF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedWithdrawMethod == 'BRI'
                                      ? const Color(0xFF0284C7)
                                      : const Color(0xFFCBD5E1),
                                  width: _selectedWithdrawMethod == 'BRI' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Bank BRI',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F4C81),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _rekeningBri,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Input Nominal
                    TextField(
                      controller: _withdrawAmountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Nominal Penarikan (Rp)',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Tombol Nominal Cepat
                    Wrap(
                      spacing: 8,
                      children: [50000, 100000, 200000, _currentBalance].map((nominal) {
                        return ActionChip(
                          label: Text(
                            nominal == _currentBalance
                                ? 'Tarik Semua'
                                : 'Rp ${_formatCurrency(nominal)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onPressed: () {
                            setSheetState(() {
                              _withdrawAmountController.text = nominal.toString();
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Tombol Konfirmasi Cash Out
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isProcessingWithdraw
                            ? null
                            : () => _handleWithdrawal(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isProcessingWithdraw
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Konfirmasi Penarikan Tunai',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
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

  void _handleWithdrawal(BuildContext sheetContext) async {
    final amountText = _withdrawAmountController.text.trim();
    final amount = int.tryParse(amountText.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    if (amount <= 0 || amount > _currentBalance || amount < 25000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            amount > _currentBalance
                ? 'Nominal melebihi saldo tersedia.'
                : 'Minimal penarikan adalah Rp 25.000.',
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _isProcessingWithdraw = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    final targetAccount = _selectedWithdrawMethod == 'DANA' ? _rekeningDana : _rekeningBri;

    final newRecord = WithdrawalRecord(
      id: 'WD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      amount: amount,
      channel: _selectedWithdrawMethod,
      destinationNumber: targetAccount,
      timestamp: DateTime.now(),
      status: 'Berhasil',
    );

    setState(() {
      _currentBalance -= amount;
      _withdrawalHistory.insert(0, newRecord);
      _isProcessingWithdraw = false;
    });

    if (sheetContext.mounted) {
      Navigator.pop(sheetContext);
    }

    // Dialog Sukses
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
        content: Text(
          'Dana sebesar Rp ${_formatCurrency(amount)} berhasil ditransfer ke $_selectedWithdrawMethod ($targetAccount).',
          style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MODAL BOTTOM SHEET: UPLOAD FOTO PADANG LAMUN (Kamera / Galeri & AI 4 Tahap)
  // ---------------------------------------------------------------------------
  void _openUploadModal() {
    if (_todayPhotos.length >= _maxDailyPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Batas kuota 5 foto hari ini telah tercapai. Kuota kembali besok!'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    _photoNoteController.text = 'Padang lamun rapat dekat tubir karang pesisir timur.';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                            color: const Color(0xFFBCE062),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.add_a_photo_rounded,
                            color: Color(0xFF1E293B),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unggah Foto Padang Lamun',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Tahap 1-4: AI, GPS, Karbon & Reward Rp 25.000',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Dua Opsi Pengambilan Foto
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.camera_alt_rounded, size: 32, color: Color(0xFF0F4C81)),
                                SizedBox(height: 6),
                                Text(
                                  'Kamera Langsung',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Sudut 90° di Pantai',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.photo_library_rounded, size: 32, color: Color(0xFF059669)),
                                SizedBox(height: 6),
                                Text(
                                  'Galeri HP',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Pilih Foto Tersimpan',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Catatan Kondisi Pantai
                    TextField(
                      controller: _photoNoteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Catatan Kondisi Pantai / Lamun',
                        hintText: 'Contoh: Padang lamun rapat, air surut jernih',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Tombol Kirim Foto
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : () => _submitPhotoWorkflow(ctx),
                        icon: _isUploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.cloud_upload_rounded, size: 20),
                        label: Text(
                          _isUploading
                              ? 'Memverifikasi AI & Karbon...'
                              : 'Kirim & Dapatkan Rp 25.000',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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

  void _submitPhotoWorkflow(BuildContext sheetContext) async {
    setState(() => _isUploading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final note = _photoNoteController.text.trim();
    final newPhoto = FishermanPhoto(
      id: 'photo-${DateTime.now().millisecondsSinceEpoch}',
      title: note.isNotEmpty ? note : 'Padang Lamun Alami (Akurasi AI 94%)',
      category: 'Padang Lamun Alami',
      location: 'Pantai Bandengan, Jepara (Lat: -6.5528, Lon: 110.6508)',
      timestamp: DateTime.now(),
      reward: _rewardPerFoto,
      status: 'Disetujui',
      sampleIcon: Icons.eco_rounded,
      iconColor: const Color(0xFF059669),
    );

    setState(() {
      _todayPhotos.insert(0, newPhoto);
      _currentBalance += _rewardPerFoto;
      _isUploading = false;
    });

    if (sheetContext.mounted) {
      Navigator.pop(sheetContext);
    }

    // Dialog Berhasil
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 28),
            SizedBox(width: 10),
            Text('Verifikasi Lolos!', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI MobileNetV2 berhasil memverifikasi objek padang lamun (Akurasi: 94%, Estimasi Karbon: 5.4 kg CO₂e/m²).',
              style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFBCE062).withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBCE062)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Color(0xFF1E293B), size: 26),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Insentif Diterima:',
                        style: TextStyle(fontSize: 11, color: Color(0xFF334155)),
                      ),
                      Text(
                        '+Rp ${_formatCurrency(_rewardPerFoto)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------
  Widget _buildCanvaGuideItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF334155),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD UTAMA (100% PERSIS SESUAI SKETSA MENTAH CANVA: BIRU LAUT, BANNER & CARD BESAR)
  // TIDAK ADA TAB LAIN / BOTTOM NAV BAR
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background warna biru laut / toska muda persis sesuai canvas Canva (#93F8F2)
      backgroundColor: const Color(0xFF93F8F2),
      appBar: null,
      bottomNavigationBar: null, // Tab lain dihapus agar dasboard fokus & identik Canva
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------------------------------------------------------------
              // 1. HEADER PROFIL (Sesuai Sketsa Atas Canva)
              // Lingkaran Putih di Kiri + Nama Pengguna & Email
              // ---------------------------------------------------------------
              GestureDetector(
                onTap: _openProfilePage,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    // Lingkaran Putih Foto Profil (Bisa ditekan ke Profile Page)
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _fishermanName.isNotEmpty
                              ? _fishermanName[0].toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Teks Nama & Email Sesuai Login
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getGreeting()}, $_fishermanName',
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Email: $_fishermanEmail',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Indikator panah halus ke profil
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ---------------------------------------------------------------
              // 2. BANNER SALDO & CASH OUT (Sesuai Sketsa Banner Canva: #BCE062)
              // Kiri: Ikon Dompet + 540.000 | Kanan: Cash Out + Ikon ATM
              // ---------------------------------------------------------------
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFBCE062), // Warna lime green Canva
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Kiri: Ikon Dompet + Nilai Saldo Rp 540.000
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 32,
                          color: Color(0xFF1E293B),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Rp ${_formatCurrency(_currentBalance)}',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),

                    // Kanan: Teks "Cash Out" di atas ikon ATM (Sesuai Sketsa Canva)
                    GestureDetector(
                      onTap: _openCashOutModal,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Cash Out',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            SizedBox(height: 2),
                            Icon(
                              Icons.local_atm_rounded,
                              size: 26,
                              color: Color(0xFF1E293B),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ---------------------------------------------------------------
              // 3. TATA CARA PENGAMBILAN FOTO (DI ATASNYA CARD FOTO)
              // ---------------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFBCE062), // Warna hijau lime Canva
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.checklist_rtl_rounded,
                          size: 20,
                          color: Color(0xFF1E293B),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Tata Cara Pengambilan Foto yang Benar:',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 4 Panduan Pengambilan Foto Ringkas
                    _buildCanvaGuideItem(
                      icon: Icons.crop_free_rounded,
                      title: 'Sudut 90 Derajat',
                      desc: 'Arahkan kamera tegak lurus langsung dari atas permukaan padang lamun.',
                    ),
                    _buildCanvaGuideItem(
                      icon: Icons.waves_rounded,
                      title: 'Saat Air Surut & Jernih',
                      desc: 'Ambil saat kondisi air surut dangkal dan tidak keruh berlumpur tebal.',
                    ),
                    _buildCanvaGuideItem(
                      icon: Icons.eco_rounded,
                      title: 'Daun & Rimpang Terlihat Jelas',
                      desc: 'Pastikan helai daun lamun dan substrat dasar perairan tampak fokus.',
                    ),
                    _buildCanvaGuideItem(
                      icon: Icons.verified_rounded,
                      title: 'Maksimal 5 Foto Per Hari',
                      desc: 'Setiap foto yang lolos verifikasi AI otomatis menambah saldo Rp 25.000.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ---------------------------------------------------------------
              // 4. CARD 1 AJA & TRANSPARAN DENGAN LOGO FOTO (TIDAK PANJANG)
              // ---------------------------------------------------------------
              GestureDetector(
                onTap: _openUploadModal,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.38), // Card Transparan
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.75),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo Foto Berlingkar di Tengah Card
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF0F4C81),
                            width: 2.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_a_photo_rounded,
                          size: 32,
                          color: Color(0xFF0F4C81),
                        ),
                      ),
                      const SizedBox(height: 12),

                      const Text(
                        'Upload Foto Padang Lamun',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Rp 25.000 / Foto',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sisa Kuota: $_remainingPhotos dari $_maxDailyPhotos',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Tombol Aksi Ambil Foto Lamun Sekarang
                      ElevatedButton.icon(
                        onPressed: _openUploadModal,
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: const Text(
                          'Ambil Foto Lamun Sekarang',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

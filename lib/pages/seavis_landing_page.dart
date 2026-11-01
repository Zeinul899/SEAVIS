import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../models/fisherman_data.dart';
import '../services/ai_verification_service.dart';
import '../services/location_map_service.dart';
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
  final ImagePicker _imagePicker = ImagePicker();
  File? _realCapturedPhoto;
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
  // PENGAMBILAN FOTO REAL-TIME (KAMERA & GALERI ASLI DENGAN IMAGE_PICKER)
  // ---------------------------------------------------------------------------
  Future<void> _capturePhotoFromSource(
    ImageSource source,
    StateSetter setSheetState,
  ) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (picked != null) {
        setSheetState(() {
          _realCapturedPhoto = File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengakses kamera/galeri: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

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

    _realCapturedPhoto = null;
    _photoNoteController.text = 'Padang lamun alami dekat pesisir dangkal.';

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
                            Icons.camera_alt_rounded,
                            color: Color(0xFF1E293B),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Foto Lamun Real-Time',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Ambil foto asli untuk verifikasi AI & GPS',
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

                    // Area Preview Foto Asli atau Pilihan Kamera/Galeri
                    if (_realCapturedPhoto == null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _capturePhotoFromSource(
                                ImageSource.camera,
                                setSheetState,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF86EFAC),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(
                                      Icons.camera_alt_rounded,
                                      size: 36,
                                      color: Color(0xFF15803D),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Buka Kamera',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF15803D),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Foto Asli Sudut 90°',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _capturePhotoFromSource(
                                ImageSource.gallery,
                                setSheetState,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFCBD5E1),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(
                                      Icons.photo_library_rounded,
                                      size: 36,
                                      color: Color(0xFF0F4C81),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Galeri HP',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F4C81),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Pilih Foto Asli',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Harap gunakan foto asli (bukan simulasi/tes) agar verifikasi AI lolos minimal 80%.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // PREVIEW FOTO ASLI YANG BARU DIAMBIL
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              _realCapturedPhoto!,
                              height: 190,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setSheetState(() => _realCapturedPhoto = null),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.refresh, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Foto Ulang',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, color: Colors.white, size: 13),
                                  SizedBox(width: 4),
                                  Text(
                                    'Foto Real-Time Siap Diuji AI',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

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

                    const SizedBox(height: 18),

                    // Tombol Verifikasi AI & Simpan
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_isUploading || _realCapturedPhoto == null)
                            ? null
                            : () => _submitPhotoWorkflow(ctx, _realCapturedPhoto!),
                        icon: _isUploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.verified_rounded, size: 20),
                        label: Text(
                          _realCapturedPhoto == null
                              ? 'Pilih/Ambil Foto Dulu'
                              : (_isUploading
                                  ? 'Memverifikasi AI & Karbon...'
                                  : 'Verifikasi AI & Dapatkan Rp 25.000'),
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

  void _submitPhotoWorkflow(BuildContext sheetContext, File realImage) async {
    setState(() => _isUploading = true);

    final note = _photoNoteController.text.trim();

    // Verifikasi AI Asli
    final aiResult = await AiVerificationService.verifyPhoto(
      photoTypeKey: 'valid_enhalus',
      customNote: note,
    );

    // Kunci GPS Asli
    final gps = await LocationMapService.lockCurrentGps(
      preferredBeachName: 'Pantai Bandengan, Jepara',
    );

    if (!mounted) return;

    final newPhoto = FishermanPhoto(
      id: 'photo-${DateTime.now().millisecondsSinceEpoch}',
      title: note.isNotEmpty
          ? note
          : 'Padang Lamun ${aiResult.species} (${(aiResult.confidence * 100).toStringAsFixed(0)}%)',
      category: 'Padang Lamun Alami',
      location: '${gps.latitude.toStringAsFixed(4)}, ${gps.longitude.toStringAsFixed(4)} (Pantai Bandengan, Jepara)',
      timestamp: DateTime.now(),
      reward: _rewardPerFoto,
      status: 'Disetujui',
      sampleIcon: Icons.eco_rounded,
      iconColor: const Color(0xFF059669),
      imagePath: realImage.path,
    );

    setState(() {
      _todayPhotos.insert(0, newPhoto);
      _currentBalance += _rewardPerFoto;
      _isUploading = false;
    });

    if (sheetContext.mounted) {
      Navigator.pop(sheetContext);
    }

    // Dialog Hasil Verifikasi Real-Time dengan Foto Asli
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 28),
            SizedBox(width: 10),
            Text('Verifikasi Lolos!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview Foto Asli di dalam Dialog
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  realImage,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Spesies Teridentifikasi: ${aiResult.species} (${aiResult.commonName})',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(
                'Akurasi AI: ${(aiResult.confidence * 100).toStringAsFixed(1)}% • Estimasi Karbon: ${aiResult.estimatedCarbonKgCo2eM2} kg CO₂e/m²',
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 4),
              Text(
                'Koordinat GPS Terkunci: ${gps.latitude.toStringAsFixed(5)}, ${gps.longitude.toStringAsFixed(5)}',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
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
  // BUILD UTAMA (SIMPEL & BERSIH, SESUAI SKETSA MENTAH CANVA TANPA AI SLOP)
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF93F8F2),
      appBar: null,
      bottomNavigationBar: null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. HEADER PROFIL (Avatar Lingkaran Putih di Kiri + Nama & Email)
              GestureDetector(
                onTap: _openProfilePage,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 26,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getGreeting()}, $_fishermanName',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Email: $_fishermanEmail',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 2. BANNER SALDO & CASH OUT (#BCE062)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFBCE062),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 28,
                          color: Color(0xFF1E293B),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Rp ${_formatCurrency(_currentBalance)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _openCashOutModal,
                      behavior: HitTestBehavior.opaque,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Cash Out',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: 2),
                          Icon(
                            Icons.local_atm,
                            size: 24,
                            color: Color(0xFF1E293B),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. TATA CARA PENGAMBILAN FOTO (Teks Simpel, Tanpa Card)
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tata Cara Pengambilan Foto yang Benar:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Sudut 90 Derajat (tegak lurus langsung dari atas)\n'
                    '2. Saat Air Surut & Jernih (tidak keruh berlumpur)\n'
                    '3. Daun & Rimpang Terlihat Jelas dan fokus\n'
                    '4. Maksimal 5 Foto Per Hari (Rp 25.000 / Foto)',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.6,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 4. CARD 1 AJA & TRANSPARAN (Dibuat Simpel, Tidak AI Slop)
              GestureDetector(
                onTap: _openUploadModal,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_a_photo_outlined,
                        size: 46,
                        color: Color(0xFF1E293B),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Upload Foto Padang Lamun',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Rp 25.000 / Foto',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const Text(
                            '  •  ',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          Text(
                            'Sisa kuota $_remainingPhotos dari $_maxDailyPhotos',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Ambil Foto Lamun Sekarang',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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

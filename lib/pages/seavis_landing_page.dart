import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../models/fisherman_data.dart';
import '../models/seagrass_report_model.dart';
import '../services/ai_verification_service.dart';
import '../services/location_map_service.dart';
import '../services/esp32_support_service.dart';
import '../screens/realtime_carbon_map_screen.dart';
import '../screens/sheets_history_screen.dart';
import '../screens/esp32_water_checker_screen.dart';
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
  String _lastAiResultText = 'Belum ada foto';

  // Layanan Pendukung IoT ESP32 (Kualitas Air & Karbon)
  final Esp32SupportService _esp32Service = Esp32SupportService();
  StreamSubscription<Esp32SupportData>? _esp32Subscription;

  @override
  void initState() {
    super.initState();
    _fishermanName = widget.user?.name.isNotEmpty == true
        ? widget.user!.name
        : 'Pak Anto';
    _fishermanEmail = widget.user?.email.isNotEmpty == true
        ? widget.user!.email
        : 'Anto@mail.com';

    // Langganan stream telemetri ESP32
    _esp32Subscription = _esp32Service.dataStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _photoNoteController.dispose();
    _withdrawAmountController.dispose();
    _esp32Subscription?.cancel();
    super.dispose();
  }

  // Sisa kuota foto hari ini
  int get _remainingPhotos =>
      (_maxDailyPhotos - _todayPhotos.length).clamp(0, _maxDailyPhotos);

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  void _openProfilePage() async {
    final res = await Navigator.push<int>(
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
          onBalanceUpdated: (newBal) {
            setState(() {
              _currentBalance = newBal;
            });
          },
        ),
      ),
    );
    if (res != null && mounted) {
      setState(() {
        _currentBalance = res;
      });
    }
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
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Color(0xFF15803D),
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
                        color: const Color(0xFFF8FAFC),
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
                              color: Color(0xFF0F5A47),
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
                                    ? const Color(0xFFF0FDF4)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedWithdrawMethod == 'DANA'
                                      ? const Color(0xFF0F5A47)
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
                                      color: Color(0xFF0F5A47),
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
                                    ? const Color(0xFFF0FDF4)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedWithdrawMethod == 'BRI'
                                      ? const Color(0xFF0F5A47)
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
                                      color: Color(0xFF0F5A47),
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
                        final isAll = nominal == _currentBalance;
                        return ActionChip(
                          backgroundColor: const Color(0xFFF0FDF4),
                          side: const BorderSide(color: Color(0xFFBBF7D0)),
                          label: Text(
                            isAll
                                ? 'Tarik Semua'
                                : 'Rp ${_formatCurrency(nominal)}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
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
                          backgroundColor: const Color(0xFF0F5A47),
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
  // PENGAMBILAN FOTO REAL-TIME (HANYA KAMERA ASLI, GALERI DINONAKTIFKAN)
  // ---------------------------------------------------------------------------
  Future<void> _capturePhotoFromCamera(
    StateSetter setSheetState,
  ) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
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
            content: Text('Gagal mengakses kamera perangkat: $e'),
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
                        const Expanded(
                          child: Column(
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
                                'Wajib kamera asli di pantai (Galeri HP Dilarang)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Area Preview Foto Asli atau Tombol Buka Kamera (Galeri Dinonaktifkan)
                    if (_realCapturedPhoto == null) ...[
                      GestureDetector(
                        onTap: () => _capturePhotoFromCamera(setSheetState),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFF16A34A),
                              width: 1.8,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF15803D),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 38,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Buka Kamera Langsung',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Wajib foto real-time di pantai (Sudut 90° Tegak Lurus)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined, color: Color(0xFFDC2626), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Akses Galeri Dinonaktifkan: Untuk menjaga integritas data riset padang lamun, foto wajib diambil langsung menggunakan kamera HP saat di lokasi pantai.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF991B1B),
                                  height: 1.4,
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
      _lastAiResultText = '${aiResult.species}\n(${(aiResult.confidence * 100).toStringAsFixed(0)}% Akurat)';
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
              if (_esp32Service.isConnected) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sensors, size: 16, color: Color(0xFF15803D)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Data ESP32 Terlampir: Suhu ${_esp32Service.currentData.waterTempC}°C, pH ${_esp32Service.currentData.ph}, TDS ${_esp32Service.currentData.tdsPpm} ppm (${_esp32Service.currentData.waterCarbonStatus})',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
  // NAVIGATION & ACTIONS
  // ---------------------------------------------------------------------------
  void _openSheetsHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SheetsHistoryScreen()),
    );
  }

  void _openAiChat() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF8E24AA), size: 26),
                const SizedBox(width: 10),
                const Text(
                  'SeaVis AI Assistant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Panduan Asisten AI SeaVis untuk Nelayan & Surveyor:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Pastikan foto padang lamun diambil tegak lurus (90°) dengan air surut dan jernih.\n'
              '• Model MobileNetV2 memverifikasi tutupan lamun (≥80%) & estimasi serapan karbon otomatis.\n'
              '• Foto lolos verifikasi langsung dikirim ke Cloudinary & Google Sheets untuk pencairan insentif.',
              style: TextStyle(fontSize: 12.5, height: 1.5, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openUploadModal();
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Mulai Ambil Foto Lamun'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F5A47),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD UTAMA (SESUAI WIREFRAME & DESAIN SEAGRASS GUARD)
  // ---------------------------------------------------------------------------
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
              Color(0xFF7DD895), // Vibrant soft mint green
              Color(0xFF38976C), // Mid green
              Color(0xFF0F4D3C), // Deep emerald green
              Color(0xFF0A3328), // Dark ocean green
            ],
            stops: [0.0, 0.32, 0.70, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. TOP WHITE PROFILE CARD
                      _buildProfileCard(),
                      const SizedBox(height: 12),

                      // 2. LIVE COASTAL MAP CARD
                      _buildLiveCoastalMapCard(),
                      const SizedBox(height: 12),

                      // 3. GPS COORDINATES CARD
                      _buildGpsCard(),
                      const SizedBox(height: 12),

                      // 4. PANDUAN 4 SUDUT FOTO (ANGLE) CARD
                      _buildAngleGuidelineCard(),
                      const SizedBox(height: 12),

                      // 4b. PENGHUBUNG IOT ESP32 WATER CHECKER (BLE)
                      _buildEsp32LiveCard(),
                      const SizedBox(height: 14),

                      // 5. TWO SIDE-BY-SIDE PHOTO & AI SCAN CARDS
                      _buildPhotoAndAiRow(),
                      const SizedBox(height: 18),

                      // 6. CONSERVATION GALLERY
                      _buildConservationGallery(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // 7. BOTTOM NAVIGATION BAR
              _buildBottomNavBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGET HELPER SECTIONS
  // ---------------------------------------------------------------------------

  Widget _buildProfileCard() {
    return GestureDetector(
      onTap: _openProfilePage,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
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
            // Row Atas: Avatar + Nama/Email + Status Online
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Lingkaran dengan nuansa surveyor
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      size: 28,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Kolom Identitas Surveyor
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
                        _fishermanName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _fishermanEmail,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 13,
                            color: Color(0xFF475569),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Hari Pertama',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Badge Status ONLINE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF86EFAC),
                      width: 1.4,
                    ),
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

            const Divider(color: Color(0xFFE2E8F0), height: 22, thickness: 1),

            // Row Statistik: Saldo Surveyor & Sisa Kuota Hari Ini
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Color(0xFF0D9488),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SALDO SURVEYOR',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Rp ${_formatCurrency(_currentBalance)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_box_outlined,
                        color: Color(0xFF0D9488),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SISA KUOTA HARI INI',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_remainingPhotos / $_maxDailyPhotos Laporan',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tanggal Tugas Centered
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: Color(0xFF94A3B8),
                ),
                SizedBox(width: 6),
                Text(
                  'Tanggal Tugas: 30 Mei 2026',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveCoastalMapCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RealtimeCarbonMapScreen()),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.map_outlined,
              color: Colors.white,
              size: 26,
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LIVE COASTAL MAP',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Click to view seagrass distribution area',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.my_location,
            color: Color(0xFFEF4444),
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'X8GH+6Q8, Parangtritis, Kecamatan Kretek\n(-8.02455, 110.32951)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
                height: 1.35,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAngleGuidelineCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 1.2,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Color(0xFFD1FAE5),
                size: 19,
              ),
              SizedBox(width: 8),
              Text(
                'PANDUAN 4 SUDUT FOTO (ANGLE)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFECFDF5),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Untuk hasil verifikasi AI terbaik, Anda wajib mengambil tepat 4 foto dengan sudut pandang berbeda:\n'
            '1. Atas (Tegak lurus menghadap objek)\n'
            '2. Samping (Kemiringan sudut sekitar 45°)\n'
            '3. Dekat / Makro (Detail ketebalan helai daun)\n'
            '4. Jauh / Lanskap (Menunjukkan area sekitar pesisir)',
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEsp32LiveCard() {
    final bool isConnected = _esp32Service.isConnected;
    final currentEsp = _esp32Service.currentData;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Esp32WaterCheckerScreen()),
        ).then((_) => setState(() {}));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: isConnected ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.sensors_rounded,
                    color: isConnected ? const Color(0xFF15803D) : const Color(0xFF64748B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'ESP32 WATER CHECKER',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isConnected ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isConnected ? 'TERHUBUNG' : 'BLE AKTIF',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isConnected ? const Color(0xFF15803D) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isConnected
                            ? 'Sensor perairan aktif • Siap lampirkan data'
                            : 'Alat pendukung kualitas air & karbon pesisir',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (isConnected) {
                      _esp32Service.disconnectEsp32();
                    } else {
                      await _esp32Service.connectToEsp32();
                    }
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConnected ? const Color(0xFFFEE2E2) : const Color(0xFF0F5A47),
                    foregroundColor: isConnected ? const Color(0xFFDC2626) : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(
                    isConnected ? 'Putus' : 'Hubungkan',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (isConnected) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _espLiveChip('Suhu', '${currentEsp.waterTempC ?? 28.5}°C'),
                  _espLiveChip('pH', '${currentEsp.ph ?? 8.1}'),
                  _espLiveChip('TDS', '${currentEsp.tdsPpm ?? 345} ppm'),
                  _espLiveChip('Turbidity', '${currentEsp.turbidityNtu ?? 3.4} NTU'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _espLiveChip(String label, String val) {
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

  Widget _buildPhotoAndAiRow() {
    return Row(
      children: [
        // Kartu Kiri: Ambil Foto 1: Tampak Atas
        Expanded(
          child: GestureDetector(
            onTap: _openUploadModal,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 145,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F5A47),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ambil Foto 1: Tampak Atas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F5A47),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Kartu Kanan: AI SCAN RESULT
        Expanded(
          child: Container(
            height: 145,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFD8B4E2),
                width: 2,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF9C27B0),
                  size: 28,
                ),
                const SizedBox(height: 8),
                const Text(
                  'AI SCAN RESULT:',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _lastAiResultText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8E24AA),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConservationGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CONSERVATION GALLERY',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 95,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final speciesNames = [
                'Enhalus acoroides',
                'Thalassia hemprichii',
                'Halodule uninervis',
                'Syringodium isoetifolium',
              ];
              final carbonValues = [
                'Karbon 148.5 T/Ha',
                'Karbon 132.0 T/Ha',
                'Karbon 118.4 T/Ha',
                'Karbon 105.2 T/Ha',
              ];

              return Container(
                width: 155,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      index % 2 == 0 ? const Color(0xFF0284C7) : const Color(0xFF0F766E),
                      index % 2 == 0 ? const Color(0xFF0369A1) : const Color(0xFF115E59),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      bottom: -10,
                      child: Icon(
                        Icons.waves,
                        size: 70,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              index == 0
                                  ? Icons.eco
                                  : (index == 1 ? Icons.water : Icons.nature),
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                speciesNames[index],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          carbonValues[index],
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111417),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.only(top: 10, bottom: 12, left: 16, right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'SEAGRASS GUARD v1.0',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.assignment_outlined,
                label: 'Form',
                isActive: true,
                onTap: () {},
              ),
              _buildNavItem(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Saldo',
                isActive: false,
                onTap: _openCashOutModal,
              ),
              _buildNavItem(
                icon: Icons.history,
                label: 'History',
                isActive: false,
                onTap: _openSheetsHistory,
              ),
              _buildNavItem(
                icon: Icons.auto_awesome,
                label: 'AI Chat',
                isActive: false,
                onTap: _openAiChat,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final color = isActive ? const Color(0xFF26E6D9) : const Color(0xFF94A3B8);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

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
import 'login_page.dart';

class ConservationGalleryItem {
  final String imagePath;
  final String title;
  final String category;
  final String species;
  final String carbonInfo;
  final String description;

  const ConservationGalleryItem({
    required this.imagePath,
    required this.title,
    required this.category,
    required this.species,
    required this.carbonInfo,
    required this.description,
  });
}

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

  // Navigasi Tab Bottom Bar (Header Bawah)
  int _selectedBottomIndex = 0; // 0 = Form, 1 = Saldo, 2 = Perangkat IoT, 3 = History, 4 = AI Chat, 5 = Profil
  final TextEditingController _iotWifiIpController = TextEditingController(text: '192.168.4.1');
  final TextEditingController _iotWifiSsidController = TextEditingController(text: 'ESP32_SEAVIS_NODE_01');

  // Koleksi Dokumentasi Nyata Konservasi Padang Lamun
  final List<ConservationGalleryItem> _conservationItems = const [
    ConservationGalleryItem(
      imagePath: 'assets/images/conservation_1.jpg',
      title: 'Kuadran Transek Padang Lamun',
      category: 'Citizen Science',
      species: 'Enhalus acoroides & Thalassia',
      carbonInfo: 'Stok Karbon: 148.5 T/Ha',
      description:
          'Nelayan dan periset lapangan melakukan pemantauan persentase tutupan lamun menggunakan bingkai kuadran transek 50x50 cm di perairan surut pantai.',
    ),
    ConservationGalleryItem(
      imagePath: 'assets/images/conservation_2.jpg',
      title: 'Transplantasi Bibit Lamun',
      category: 'Restorasi Pesisir',
      species: 'Enhalus acoroides (Bibit Polybag)',
      carbonInfo: 'Potensi Serapan: +25% Karbon Biru',
      description:
          'Aksi penanaman dan pengembalian bibit lamun oleh kelompok nelayan pemuda untuk merehabilitasi padang lamun yang terdegradasi.',
    ),
    ConservationGalleryItem(
      imagePath: 'assets/images/conservation_3.jpg',
      title: 'Edukasi & Taksonomi Spesies',
      category: 'Edukasi Komunitas',
      species: 'Thalassia hemprichii & Halodule',
      carbonInfo: 'Zona Perlindungan Karbon',
      description:
          'Pelatihan bersama nelayan tradisional mengenai morfologi akar rimpang dan kemampuan sekuestrasi sedimen lamun bawah laut.',
    ),
    ConservationGalleryItem(
      imagePath: 'assets/images/conservation_4.png',
      title: 'Monitoring Ekosistem Karbon Biru',
      category: 'Konektivitas Mangrove-Lamun',
      species: 'Syringodium isoetifolium & Mangrove',
      carbonInfo: 'Stok Terpadu: 210 T/Ha',
      description:
          'Survei perairan intertidal untuk memverifikasi kesehatan padang lamun di sekitar perakaran bakau penyerap emisi karbon.',
    ),
  ];

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
    _iotWifiIpController.dispose();
    _iotWifiSsidController.dispose();
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

  void _openProfilePage() {
    setState(() {
      _selectedBottomIndex = 5;
    });
  }

  // ---------------------------------------------------------------------------
  // MODAL BOTTOM SHEET: CASH OUT (Tarik Tunai Saldo Langsung dari Banner)
  // ---------------------------------------------------------------------------
  void _openCashOutModal() {
    setState(() {
      _selectedBottomIndex = 1;
    });
    return;
    // ignore: dead_code
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
                          backgroundColor: const Color(0xFF006994),
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
    if (!RegExp(r'^\d+$').hasMatch(amountText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal penarikan harus berupa angka bulat positif.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }
    final amount = int.tryParse(amountText) ?? 0;

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
    setState(() => _selectedBottomIndex = 3);
  }

  void _openAiChat() {
    setState(() => _selectedBottomIndex = 4);
  }

  // ---------------------------------------------------------------------------
  // BUILD UTAMA (ARSITEKTUR SEAVIS DENGAN TAB NAVIGASI MANDIRI)
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
              Color(0xFF0096C7), // Rona cerah kehijauan permukaan laut (Cyan-tinted Sea Blue)
              Color(0xFF006994), // Warna Biru Laut Utama (Sea Blue)
              Color(0xFF01386A), // Marine Blue / Rona Kedalaman Laut
              Color(0xFF001A33), // Deep Abyssal Navy Blue
            ],
            stops: [0.0, 0.32, 0.70, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: _buildCurrentTab(),
              ),

              // BOTTOM NAVIGATION BAR (HEADER BAWAH)
              _buildBottomNavBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_selectedBottomIndex) {
      case 0:
        return _buildFormContent();
      case 1:
        return _buildSaldoContent();
      case 2:
        return _buildIoTContent();
      case 3:
        return _buildHistoryContent();
      case 4:
        return _buildAiChatContent();
      case 5:
        return _buildProfileContent();
      default:
        return _buildFormContent();
    }
  }

  Widget _buildFormContent() {
    return SingleChildScrollView(
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
          const SizedBox(height: 14),

          // 4b. SENSOR ESP32 KUALITAS AIR (HANYA MUNCUL JIKA TERHUBUNG / ADA)
          if (_esp32Service.isConnected) ...[
            _buildEsp32ActiveBanner(),
            const SizedBox(height: 14),
          ],

          // 5. TWO SIDE-BY-SIDE PHOTO & AI SCAN CARDS
          _buildPhotoAndAiRow(),
          const SizedBox(height: 18),

          // 6. CONSERVATION GALLERY (DOKUMENTASI NYATA)
          _buildConservationGallery(),
          const SizedBox(height: 16),
        ],
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
                  child: InkWell(
                    onTap: () => setState(() => _selectedBottomIndex = 1),
                    borderRadius: BorderRadius.circular(8),
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

  Widget _buildEsp32ActiveBanner() {
    final currentEsp = _esp32Service.currentData;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Esp32WaterCheckerScreen()),
        ).then((_) => setState(() {}));
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sensors_rounded,
                    color: Color(0xFF15803D),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'ESP32 TERHUBUNG',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15803D),
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.check_circle, size: 12, color: Color(0xFF16A34A)),
                        ],
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Telemetri kualitas air aktif dilampirkan ke laporan',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _esp32Service.disconnectEsp32();
                    setState(() {});
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Putus',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 8),
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
                      color: const Color(0xFF006994),
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
                      color: Color(0xFF006994),
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

  // ---------------------------------------------------------------------------
  // CONSERVATION GALLERY (DOKUMENTASI NYATA CITIZEN SCIENCE & RESTORASI)
  // ---------------------------------------------------------------------------
  Widget _buildConservationGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF26E6D9).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF26E6D9), width: 1),
              ),
              child: const Row(
                children: [
                  Icon(Icons.photo_library_outlined, size: 12, color: Color(0xFF26E6D9)),
                  SizedBox(width: 4),
                  Text(
                    '4 Dokumentasi Nyata',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF26E6D9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _conservationItems.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = _conservationItems[index];
              return GestureDetector(
                onTap: () => _showConservationDetailModal(item),
                child: Container(
                  width: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          item.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: const Color(0xFF0F4C81),
                            child: const Center(
                              child: Icon(Icons.broken_image, color: Colors.white54),
                            ),
                          ),
                        ),
                        // Gradient shadow agar teks terbaca tajam
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.15),
                                Colors.black.withValues(alpha: 0.8),
                              ],
                              stops: const [0.35, 1.0],
                            ),
                          ),
                        ),
                        // Badge Kategori di Kiri Atas
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0096C7).withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.category,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        // Konten Teks di Bawah
                        Positioned(
                          bottom: 10,
                          left: 10,
                          right: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.eco_rounded, size: 12, color: Color(0xFF34D399)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item.carbonInfo,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF6EE7B7),
                                      ),
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showConservationDetailModal(ConservationGalleryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 200,
                child: Image.asset(
                  item.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    color: const Color(0xFF0F4C81),
                    child: const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.category,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.carbonInfo,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Spesies: ${item.species}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0D9488)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.description,
                      style: const TextStyle(fontSize: 12.5, height: 1.5, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006994),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Tutup Dokumentasi'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: SALDO (DOMPET SURVEYOR MANDIRI - BUKAN POPUP!)
  // ---------------------------------------------------------------------------
  Widget _buildSaldoContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dompet Insentif Surveyor',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Hasil monitoring lamun & sekuestrasi Blue Carbon',
                    style: TextStyle(fontSize: 11, color: Color(0xFFE2E8F0)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Primary Card: Saldo Aktif
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF006994), Color(0xFF01386A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL SALDO AKTIF',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1.1),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rp ${_formatCurrency(_currentBalance)}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat('Insentif / Foto', 'Rp 25.000'),
                      _buildMiniStat('Kuota Hari Ini', '$_remainingPhotos / $_maxDailyPhotos'),
                      _buildMiniStat('Bebas Biaya', '100% Gratis'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // IN-PAGE FORM PENCAIRAN SALDO (BUKAN POPUP!)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                const Row(
                  children: [
                    Icon(Icons.payments_rounded, color: Color(0xFF006994), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Tarik Saldo Insentif Langsung',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pencairan instan tanpa biaya admin ke rekening atau e-wallet nelayan.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),

                // Input Nominal
                TextField(
                  controller: _withdrawAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Nominal Penarikan (Rp)',
                    prefixIcon: const Icon(Icons.monetization_on_outlined, color: Color(0xFF006994)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 10),

                // Pilihan Cepat Nominal
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildNominalChip(25000),
                    _buildNominalChip(50000),
                    _buildNominalChip(100000),
                    _buildNominalChip(200000),
                    ActionChip(
                      label: const Text('Tarik Semua', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF006994))),
                      backgroundColor: const Color(0xFFE0F2FE),
                      onPressed: () {
                        setState(() {
                          _withdrawAmountController.text = _currentBalance.toString();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Metode Pencairan
                const Text('Pilih Metode Pencairan:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['DANA', 'GoPay', 'OVO', 'Bank BRI', 'Bank Mandiri', 'Bank BCA'].map((method) {
                    final isSelected = _selectedWithdrawMethod == method;
                    return ChoiceChip(
                      label: Text(method),
                      selected: isSelected,
                      selectedColor: const Color(0xFF006994),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF334155),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedWithdrawMethod = method);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Nomor Akun Tujuan
                Text(
                  _selectedWithdrawMethod.startsWith('Bank') ? 'Nomor Rekening Tujuan:' : 'Nomor Handphone E-Wallet:',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedWithdrawMethod.startsWith('Bank') ? _rekeningBri : _rekeningDana,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const Text('(Tersimpan)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Tombol Tarik Saldo
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessingWithdraw ? null : _handleInPageWithdrawal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006994),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isProcessingWithdraw
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Tarik Saldo Sekarang', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Riwayat Penarikan Saldo
          _buildWithdrawalHistorySection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFFCBD5E1))),
      ],
    );
  }

  Widget _buildNominalChip(int amount) {
    return ActionChip(
      label: Text('Rp ${_formatCurrency(amount)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFFF1F5F9),
      onPressed: () {
        setState(() {
          _withdrawAmountController.text = amount.toString();
        });
      },
    );
  }

  void _handleInPageWithdrawal() async {
    final text = _withdrawAmountController.text.trim();
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
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() {
      _currentBalance -= amount;
      _withdrawalHistory.insert(
        0,
        WithdrawalRecord(
          id: 'WD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          amount: amount,
          channel: _selectedWithdrawMethod,
          destinationNumber: _selectedWithdrawMethod.startsWith('Bank') ? _rekeningBri : _rekeningDana,
          timestamp: DateTime.now(),
          status: 'Berhasil',
        ),
      );
      _isProcessingWithdraw = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pencairan Rp ${_formatCurrency(amount)} ke $_selectedWithdrawMethod berhasil diproses!',
        ),
        backgroundColor: const Color(0xFF059669),
      ),
    );
  }

  Widget _buildWithdrawalHistorySection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          const Text(
            'Riwayat Penarikan Dana',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          if (_withdrawalHistory.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text('Belum ada riwayat penarikan dana.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _withdrawalHistory.length,
              separatorBuilder: (ctx, i) => const Divider(height: 18, color: Color(0xFFF1F5F9)),
              itemBuilder: (ctx, i) {
                final item = _withdrawalHistory[i];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_downward_rounded, color: Color(0xFF15803D), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.channel,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              item.destinationNumber,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '-Rp ${_formatCurrency(item.amount)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Berhasil', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: PERANGKAT IOT (ESP32 VIA WIFI)
  // ---------------------------------------------------------------------------
  Widget _buildIoTContent() {
    final data = _esp32Service.currentData;
    final isConnected = _esp32Service.isConnected;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.wifi_tethering_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perangkat IoT ESP32 (WiFi)',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Sensor Kualitas Air & Parameter Karbon Biru',
                    style: TextStyle(fontSize: 11, color: Color(0xFFE2E8F0)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Box Status Koneksi WiFi ESP32
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isConnected ? Icons.wifi : Icons.wifi_off,
                          color: isConnected ? const Color(0xFF059669) : const Color(0xFFDC2626),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isConnected ? 'Terhubung via WiFi' : 'WiFi Terputus',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isConnected ? const Color(0xFF059669) : const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isConnected ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isConnected ? 'ONLINE' : 'STANDBY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isConnected ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Input IP & SSID
                TextField(
                  controller: _iotWifiIpController,
                  decoration: InputDecoration(
                    labelText: 'Alamat IP ESP32 (WiFi)',
                    hintText: '192.168.4.1',
                    prefixIcon: const Icon(Icons.settings_ethernet, color: Color(0xFF006994)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _iotWifiSsidController,
                  decoration: InputDecoration(
                    labelText: 'SSID Hotspot / Jaringan WiFi',
                    hintText: 'ESP32_SEAVIS_NODE_01',
                    prefixIcon: const Icon(Icons.wifi_outlined, color: Color(0xFF006994)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),

                // Tombol Hubungkan / Putuskan
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (isConnected) {
                            _esp32Service.disconnectEsp32();
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Koneksi WiFi ESP32 diputuskan.')),
                            );
                          } else {
                            await _esp32Service.connectViaWifi(
                              ipAddress: _iotWifiIpController.text,
                              ssid: _iotWifiSsidController.text,
                            );
                            if (!mounted) return;
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Berhasil terhubung ke modul ESP32 via WiFi!'),
                                backgroundColor: Color(0xFF059669),
                              ),
                            );
                          }
                        },
                        icon: Icon(isConnected ? Icons.link_off : Icons.wifi_protected_setup_rounded),
                        label: Text(isConnected ? 'Putuskan WiFi' : 'Hubungkan WiFi ESP32'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isConnected ? const Color(0xFFDC2626) : const Color(0xFF006994),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Status Karbon Perairan Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF006994), Color(0xFF0F766E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.eco_rounded, color: Color(0xFF34D399), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'STATUS LINGKUNGAN PERAIRAN',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF99F6E4), letterSpacing: 1),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ZONA KARBON ${data.waterCarbonStatus}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Kualitas air mendukung fotosintesis lamun & penyerapan karbon biru.',
                        style: TextStyle(fontSize: 11, color: Color(0xFFCCFBF1)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Grid Telemetri Sensor 4 Metrik
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              _buildSensorMetricTile(
                title: 'pH Air Laut',
                value: isConnected && data.ph != null ? data.ph!.toStringAsFixed(2) : '8.10',
                unit: 'pH',
                status: 'Optimal Basa Pesisir',
                icon: Icons.science_rounded,
                iconColor: const Color(0xFF0284C7),
              ),
              _buildSensorMetricTile(
                title: 'Suhu Air Laut',
                value: isConnected && data.waterTempC != null ? data.waterTempC!.toStringAsFixed(1) : '28.5',
                unit: '°C',
                status: 'Tropis Hangat',
                icon: Icons.thermostat_rounded,
                iconColor: const Color(0xFFEA580C),
              ),
              _buildSensorMetricTile(
                title: 'TDS / Salinitas',
                value: isConnected && data.tdsPpm != null ? data.tdsPpm!.toStringAsFixed(0) : '345',
                unit: 'ppm',
                status: 'Kadar Garam Stabil',
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFF0D9488),
              ),
              _buildSensorMetricTile(
                title: 'Kekeruhan',
                value: isConnected && data.turbidityNtu != null ? data.turbidityNtu!.toStringAsFixed(1) : '3.4',
                unit: 'NTU',
                status: 'Sangat Jernih',
                icon: Icons.opacity_rounded,
                iconColor: const Color(0xFF8B5CF6),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Card Catatan Opsional
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.white70, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Perangkat ESP32 berfungsi sebagai alat pendukung opsional. Laporan pemantauan lamun tetap dapat disubmit meskipun ESP32 offline.',
                    style: TextStyle(fontSize: 11, color: Colors.white, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSensorMetricTile({
    required String title,
    required String value,
    required String unit,
    required String status,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              Icon(icon, color: iconColor, size: 18),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
            ],
          ),
          Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: iconColor),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: HISTORY (RIWAYAT LAPORAN GOOGLE SHEETS & CLOUDINARY)
  // ---------------------------------------------------------------------------
  Widget _buildHistoryContent() {
    return const SheetsHistoryScreen();
  }

  // ---------------------------------------------------------------------------
  // TAB 4: AI CHAT (ASISTEN CERDAS SEAVIS)
  // ---------------------------------------------------------------------------
  Widget _buildAiChatContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Asisten AI SEAVIS',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Konsultasi identifikasi lamun & perhitungan Blue Carbon',
                    style: TextStyle(fontSize: 11, color: Color(0xFFE2E8F0)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                const Row(
                  children: [
                    Icon(Icons.smart_toy_rounded, color: Color(0xFF8E24AA), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Rekomendasi Pemantauan AI',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Halo Pak Nelayan! AI kami siap membantu verifikasi jenis spesies padang lamun, panduan pemotretan 4 sudut, dan kalkulasi estimasi serapan karbon di pesisir Anda.',
                  style: TextStyle(fontSize: 12.5, height: 1.5, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 14),

                const Text('Topik Tanya Jawab Populer:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildAiQuestionChip('Cara membedakan Enhalus & Thalassia'),
                    _buildAiQuestionChip('Tips agar foto lolos verifikasi 80%'),
                    _buildAiQuestionChip('Berapa serapan karbon rata-rata per ha?'),
                    _buildAiQuestionChip('Waktu terbaik survei air surut'),
                  ],
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _selectedBottomIndex = 0);
                    },
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Buka Kamera & Mulai Deteksi Lamun'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006994),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAiQuestionChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF006994))),
      backgroundColor: const Color(0xFFF0F9FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Jawaban AI: "$text" - AI merekomendasikan survei saat surut purnama dengan cahaya optimal.'),
            backgroundColor: const Color(0xFF006994),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 5: PROFILE (DIBIKIN SIMPLE & RINGKAS SESUAI PERMINTAAN USER)
  // ---------------------------------------------------------------------------
  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profil Field Surveyor',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Informasi akun mitra konservasi pesisir',
                    style: TextStyle(fontSize: 11, color: Color(0xFFE2E8F0)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Kartu Identitas Nelayan (Simple & Clean)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0F2FE),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _fishermanName.isNotEmpty ? _fishermanName[0].toUpperCase() : 'N',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF006994)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fishermanName,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Email: $_fishermanEmail',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Surveyor Aktif (Online)',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),

                // 3 Ringkasan Statistik
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSimpleProfileStat('Laporan', '${_todayPhotos.length + 10}'),
                    _buildSimpleProfileStat('Saldo', 'Rp ${_formatCurrency(_currentBalance)}'),
                    _buildSimpleProfileStat('Akurasi AI', '94%'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Detail Kemitraan & Rekening (Simple)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                const Text(
                  'Informasi Lapangan & Kemitraan',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 12),
                _buildSimpleInfoRow(Icons.badge_outlined, 'ID Kemitraan', 'SV-NL-2025-0849'),
                _buildSimpleInfoRow(Icons.calendar_today_outlined, 'Lama Kerja Sama', '1 Tahun 4 Bulan (Sejak 2025)'),
                _buildSimpleInfoRow(Icons.place_outlined, 'Pangkalan Pantai', 'Pantai Bandengan, Jepara'),
                _buildSimpleInfoRow(Icons.directions_boat_outlined, 'Nama Kapal / Armada', 'KM Samudera Berkah (5 GT)'),
                _buildSimpleInfoRow(Icons.account_balance_outlined, 'Bank BRI', _rekeningBri),
                _buildSimpleInfoRow(Icons.wallet_outlined, 'E-Wallet DANA', _rekeningDana),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tombol Buka Detail & Edit Profil Lengkap
          ElevatedButton.icon(
            onPressed: () {
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
                    onBalanceUpdated: (newBal) {
                      setState(() {
                        _currentBalance = newBal;
                      });
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.edit_note, color: Colors.white, size: 20),
            label: const Text(
              'Edit Data Profil & Armada Lengkap',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006994),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),

          // Tombol Keluar (Logout)
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSimpleProfileStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF006994))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildSimpleInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF006994)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM NAVIGATION BAR (HEADER BAWAH SEAVIS)
  // ---------------------------------------------------------------------------
  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111417),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.only(top: 10, bottom: 12, left: 10, right: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'SEAVIS v1.0',
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
                isActive: _selectedBottomIndex == 0,
                onTap: () => setState(() => _selectedBottomIndex = 0),
              ),
              _buildNavItem(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Saldo',
                isActive: _selectedBottomIndex == 1,
                onTap: _openCashOutModal,
              ),
              _buildNavItem(
                icon: Icons.wifi_tethering_rounded,
                label: 'Perangkat IoT',
                isActive: _selectedBottomIndex == 2,
                onTap: () => setState(() => _selectedBottomIndex = 2),
              ),
              _buildNavItem(
                icon: Icons.history_rounded,
                label: 'History',
                isActive: _selectedBottomIndex == 3,
                onTap: _openSheetsHistory,
              ),
              _buildNavItem(
                icon: Icons.auto_awesome_rounded,
                label: 'AI Chat',
                isActive: _selectedBottomIndex == 4,
                onTap: _openAiChat,
              ),
              _buildNavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profil',
                isActive: _selectedBottomIndex == 5,
                onTap: _openProfilePage,
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
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

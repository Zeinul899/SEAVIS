import 'package:flutter/material.dart';
import '../models/seagrass_report_model.dart';
import '../services/ai_verification_service.dart';
import '../services/location_map_service.dart';
import '../services/cloudinary_sheets_service.dart';
import '../services/esp32_support_service.dart';

class ReportWizardScreen extends StatefulWidget {
  final VoidCallback? onReportSubmitted;

  const ReportWizardScreen({super.key, this.onReportSubmitted});

  @override
  State<ReportWizardScreen> createState() => _ReportWizardScreenState();
}

class _ReportWizardScreenState extends State<ReportWizardScreen> {
  int _currentStep = 0; // 0 = Input, 1 = AI Verif, 2 = GPS Lock & Map, 3 = Kirim Cloudinary & Sheets

  // Form Fields (Langkah 1)
  final TextEditingController _fishermanController =
      TextEditingController(text: 'Pak Budi Santoso');
  final TextEditingController _beachNameController =
      TextEditingController(text: 'Pantai Bandengan, Jepara');
  final TextEditingController _notesController =
      TextEditingController(text: 'Padang lamun tumbuh rapat di perairan dangkal dekat pesisir timur.');

  String _selectedPhotoType = 'valid_enhalus'; // valid_enhalus, valid_thalassia, invalid_trash
  bool _attachEsp32Data = false;

  // State Verifikasi AI (Langkah 2)
  bool _isVerifyingAi = false;
  AiVerificationResult? _aiResult;
  String? _aiErrorMessage;

  // State Kunci GPS & Maps (Langkah 3)
  bool _isLockingGps = false;
  GpsCoordinate? _lockedGps;

  // State Simpan Cloudinary & Sheets (Langkah 4)
  bool _isSubmitting = false;
  String _submissionStatusText = '';

  final Esp32SupportService _esp32Service = Esp32SupportService();

  @override
  void initState() {
    super.initState();
    _attachEsp32Data = _esp32Service.isConnected;
  }

  @override
  void dispose() {
    _fishermanController.dispose();
    _beachNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // TAHAP 2: PROSES VERIFIKASI AI
  // ---------------------------------------------------------------------------
  Future<void> _runAiVerification() async {
    setState(() {
      _isVerifyingAi = true;
      _aiErrorMessage = null;
    });

    final result = await AiVerificationService.verifyPhoto(
      photoTypeKey: _selectedPhotoType,
      customNote: _notesController.text,
    );

    setState(() {
      _isVerifyingAi = false;
      _aiResult = result;
      if (!result.isVerified) {
        _aiErrorMessage = result.rejectionReason ??
            'Verifikasi AI gagal. Foto tidak memenuhi syarat minimal 80%. Laporan tidak dapat dilanjutkan.';
      } else {
        // Lolos AI: Maju ke Tahap 3 (Kunci GPS)
        _currentStep = 2;
        _runGpsLock();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // TAHAP 3: KUNCI KOORDINAT GPS & REAL-TIME MAP
  // ---------------------------------------------------------------------------
  Future<void> _runGpsLock() async {
    setState(() {
      _isLockingGps = true;
    });

    final gps = await LocationMapService.lockCurrentGps(
      preferredBeachName: _beachNameController.text,
    );

    setState(() {
      _isLockingGps = false;
      _lockedGps = gps;
    });
  }

  // ---------------------------------------------------------------------------
  // TAHAP 4: SIMPAN KE CLOUDINARY & GOOGLE SHEETS
  // ---------------------------------------------------------------------------
  Future<void> _submitToCloudinaryAndSheets() async {
    if (_aiResult == null || !_aiResult!.isVerified || _lockedGps == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selesaikan verifikasi AI dan koordinat GPS terlebih dahulu.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submissionStatusText = '1/2 Mengunggah foto ke Cloudinary...';
    });

    // 1. Upload ke Cloudinary
    final imageUrl = await CloudinarySheetsService.uploadPhotoToCloudinary(
      imageSourceIndicator: _selectedPhotoType,
    );

    setState(() {
      _submissionStatusText = '2/2 Mengirim seluruh Data Jadi ke Google Sheets...';
    });

    // Susun Payload "Data Jadi"
    final reportId = 'SG-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    Esp32SupportData espData = const Esp32SupportData(isAttached: false);
    if (_attachEsp32Data) {
      espData = _esp32Service.currentData.copyWith(isAttached: true);
    }

    final newReport = SeagrassReportModel(
      reportId: reportId,
      timestamp: DateTime.now().toIso8601String(),
      fishermanName: _fishermanController.text.trim().isNotEmpty
          ? _fishermanController.text.trim()
          : 'Nelayan Pesisir',
      beachName: _beachNameController.text.trim().isNotEmpty
          ? _beachNameController.text.trim()
          : 'Pantai Bandengan, Jepara',
      beachNotes: _notesController.text.trim(),
      aiVerified: true,
      species: _aiResult!.species,
      aiConfidence: _aiResult!.confidence,
      estimatedCarbonKgCo2eM2: _aiResult!.estimatedCarbonKgCo2eM2,
      estimatedCarbonTonHa: _aiResult!.estimatedCarbonTonHa,
      carbonZoneCategory: _aiResult!.carbonZoneCategory,
      gps: _lockedGps!,
      cloudinaryImageUrl: imageUrl,
      esp32SupportData: espData,
    );

    // 2. Kirim Data Jadi ke Google Sheets
    await CloudinarySheetsService.sendReportToGoogleSheets(newReport);

    setState(() {
      _isSubmitting = false;
    });

    widget.onReportSubmitted?.call();

    // Dialog Sukses
    _showSuccessDialog(newReport);
  }

  void _showSuccessDialog(SeagrassReportModel report) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Laporan Tersimpan!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alur 4 tahap selesai dengan sukses! Foto tersimpan permanen di Cloudinary dan seluruh Data Jadi telah tercatat di Google Sheets.',
              style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID Laporan: ${report.reportId}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('Pantai: ${report.beachName}', style: const TextStyle(fontSize: 12)),
                  Text('Spesies: ${report.species} (${(report.aiConfidence * 100).toStringAsFixed(0)}% AI)',
                      style: const TextStyle(fontSize: 12)),
                  Text('Estimasi Karbon: ${report.estimatedCarbonKgCo2eM2} kg CO2e/m² (${report.estimatedCarbonTonHa} ton C/ha)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                  Text('Koordinat: ${report.gps.latitude.toStringAsFixed(4)}, ${report.gps.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF047857))),
                  if (report.esp32SupportData.isAttached)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text('✓ Dilampirkan Data Kualitas Air ESP32',
                          style: TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetWizard();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F4C81),
              foregroundColor: Colors.white,
            ),
            child: const Text('Buat Laporan Baru'),
          ),
        ],
      ),
    );
  }

  void _resetWizard() {
    setState(() {
      _currentStep = 0;
      _aiResult = null;
      _aiErrorMessage = null;
      _lockedGps = null;
    });
  }

  // ---------------------------------------------------------------------------
  // BUILD METHOD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepperHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: _buildCurrentStepContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Indikator 4 Langkah Alur Utama
  Widget _buildStepperHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pelaporan Padang Lamun',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Tahap ${_currentStep + 1} dari 4',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _stepIndicatorItem(0, '1. Foto & Info'),
              _stepDivider(0),
              _stepIndicatorItem(1, '2. AI & Karbon'),
              _stepDivider(1),
              _stepIndicatorItem(2, '3. GPS & Map'),
              _stepDivider(2),
              _stepIndicatorItem(3, '4. Cloud & Sheets'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepIndicatorItem(int stepIndex, String title) {
    final bool isDone = _currentStep > stepIndex;
    final bool isCurrent = _currentStep == stepIndex;

    Color bg = const Color(0xFFF1F5F9);
    Color textColor = const Color(0xFF64748B);
    if (isDone) {
      bg = const Color(0xFF059669);
      textColor = Colors.white;
    } else if (isCurrent) {
      bg = const Color(0xFF0F4C81);
      textColor = Colors.white;
    }

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text(
                      '${stepIndex + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? const Color(0xFF0F4C81) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepDivider(int stepIndex) {
    final isDone = _currentStep > stepIndex;
    return Container(
      width: 14,
      height: 2,
      color: isDone ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1InputFoto();
      case 1:
        return _buildStep2VerifikasiAi();
      case 2:
        return _buildStep3GpsAndMap();
      case 3:
        return _buildStep4CloudinarySheets();
      default:
        return _buildStep1InputFoto();
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 1: INPUT FOTO & INFO PANTAI OLEH NELAYAN
  // ---------------------------------------------------------------------------
  Widget _buildStep1InputFoto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tahap 1: Foto Lamun & Info Pantai',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Ambil foto padang lamun di pesisir pantai dan lengkapi informasi singkat di bawah ini.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),

        // Pilihan Contoh Foto (Simulasi Kamera/Galeri Nelayan)
        const Text(
          'Pilih Foto Lamun untuk Diuji:',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _photoOptionChip(
              id: 'valid_enhalus',
              title: 'Lamun Enhalus Sehat',
              icon: Icons.eco_rounded,
              color: const Color(0xFF059669),
            ),
            _photoOptionChip(
              id: 'valid_thalassia',
              title: 'Lamun Thalassia Karang',
              icon: Icons.grass_rounded,
              color: const Color(0xFF0D9488),
            ),
            _photoOptionChip(
              id: 'invalid_trash',
              title: 'Non-Lamun (Sampah/Batu) [Test Gagal]',
              icon: Icons.delete_outline_rounded,
              color: const Color(0xFFDC2626),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Preview Box Foto
        Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedPhotoType.contains('invalid')
                          ? Icons.warning_amber_rounded
                          : Icons.filter_vintage_rounded,
                      size: 48,
                      color: _selectedPhotoType.contains('invalid')
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF34D399),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedPhotoType == 'valid_enhalus'
                          ? 'Foto: Enhalus acoroides (Padang Lamun Daun Lebar)'
                          : (_selectedPhotoType == 'valid_thalassia'
                              ? 'Foto: Thalassia hemprichii (Padang Lamun Karang)'
                              : 'Foto: Objek Pantai Berbatu / Bukan Lamun'),
                      style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    const Text('Kamera Siap • Format RGB 224x224 Siap Inferensi',
                        style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x99000000),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Pratinjau', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Form Info Nelayan & Pantai
        TextField(
          controller: _fishermanController,
          decoration: const InputDecoration(
            labelText: 'Nama Nelayan / Pelapor',
            prefixIcon: Icon(Icons.person_outline),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 10),

        TextField(
          controller: _beachNameController,
          decoration: const InputDecoration(
            labelText: 'Nama Pantai / Lokasi Pesisir',
            prefixIcon: Icon(Icons.beach_access_outlined),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 10),

        TextField(
          controller: _notesController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Catatan Kondisi Lamun di Pantai',
            hintText: 'Misal: Tumbuh rapat, kondisi perairan jernih...',
            contentPadding: EdgeInsets.all(12),
          ),
        ),

        const SizedBox(height: 14),

        // Checkbox Opsi Alat Pendukung ESP32
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Lampirkan data pendukung kualitas air dari ESP32',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              subtitle: Text(
                _esp32Service.isConnected
                    ? 'ESP32 Terhubung (Suhu ${_esp32Service.currentData.waterTempC}°C, pH ${_esp32Service.currentData.ph})'
                    : 'ESP32 belum terhubung (akan gunakan data lampiran simulasi)',
                style: TextStyle(
                  fontSize: 11,
                  color: _esp32Service.isConnected ? const Color(0xFF059669) : const Color(0xFF64748B),
                ),
              ),
              value: _attachEsp32Data,
              activeColor: const Color(0xFF0F4C81),
              onChanged: (val) {
                setState(() {
                  _attachEsp32Data = val ?? false;
                });
              },
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Tombol Lanjut ke Tahap 2
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _currentStep = 1;
              });
            },
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Lanjut: Verifikasi AI & Karbon'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F4C81),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _photoOptionChip({
    required String id,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedPhotoType == id;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedPhotoType = id;
            if (id == 'valid_enhalus') {
              _beachNameController.text = 'Pantai Bandengan, Jepara';
            } else if (id == 'valid_thalassia') {
              _beachNameController.text = 'Teluk Kemujan, Karimunjawa';
            } else {
              _beachNameController.text = 'Kawasan Karang Pesisir';
            }
          });
        }
      },
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : color),
      label: Text(title, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : const Color(0xFF1E293B))),
      selectedColor: const Color(0xFF0F4C81),
      backgroundColor: Colors.white,
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: VERIFIKASI AI & DETEKSI KARBON
  // ---------------------------------------------------------------------------
  Widget _buildStep2VerifikasiAi() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tahap 2: Verifikasi AI & Deteksi Karbon',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Model MobileNetV2 mengecek keaslian objek lamun (syarat lolos akurasi >= 80%) dan menghitung estimasi serapan karbon.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),

        // Kotak Status Verifikasi AI
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _aiResult != null && !_aiResult!.isVerified
                  ? const Color(0xFFFCA5A5)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_aiResult == null) ...[
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.smart_toy_outlined, size: 48, color: Color(0xFF0284C7)),
                      SizedBox(height: 10),
                      Text('Siap untuk verifikasi foto dengan AI Edge Model',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Ambang batas akurasi minimal: 80.0%',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ] else if (_aiResult!.isVerified) ...[
                // HASIL LOLOS
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('VERIFIKASI AI BERHASIL (>= 80%)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                          Text('Akurasi Keyakinan: ${(_aiResult!.confidence * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF065F46))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 14),

                Text('Spesies Terdeteksi: ${_aiResult!.species}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                Text(_aiResult!.commonName,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic)),
                const SizedBox(height: 10),

                // Kartu Estimasi Karbon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.eco_rounded, color: Color(0xFF059669), size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Estimasi Serapan Karbon Biru:',
                                style: TextStyle(fontSize: 11, color: Color(0xFF065F46))),
                            Text(
                              '${_aiResult!.estimatedCarbonKgCo2eM2} kg CO2e/m²',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                            ),
                            Text(
                              'Setara ${_aiResult!.estimatedCarbonTonHa} ton Karbon/Hektar',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _aiResult!.carbonZoneCategory == 'HIGH_CARBON' ? 'ZONA TINGGI' : 'ZONA SEDANG',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // HASIL GAGAL (< 80% ATAU BUKAN LAMUN)
                Row(
                  children: [
                    const Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('VERIFIKASI AI DITOLAK (< 80%)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                          Text('Akurasi Keyakinan: ${(_aiResult!.confidence * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF7F1D1D))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _aiErrorMessage ?? 'Foto ditolak karena bukan padang lamun atau akurasi di bawah 80%. Sesuai aturan sistem, proses berhenti di sini.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Tombol Jalankan Verifikasi
        if (_aiResult == null || !_aiResult!.isVerified)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isVerifyingAi ? null : _runAiVerification,
              icon: _isVerifyingAi
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isVerifyingAi ? 'Memeriksa dengan MobileNetV2...' : 'Jalankan Verifikasi AI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F4C81),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _currentStep = 2;
                });
              },
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Lanjut: Kunci Koordinat & Peta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

        const SizedBox(height: 10),
        Center(
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _currentStep = 0;
              });
            },
            icon: const Icon(Icons.arrow_back, size: 14),
            label: const Text('Kembali ke Input Foto', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: KUNCI KOORDINAT GPS & REAL-TIME MAPS
  // ---------------------------------------------------------------------------
  Widget _buildStep3GpsAndMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tahap 3: Kunci Koordinat & Real-Time Maps',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Titik koordinat GPS terkunci otomatis dan langsung ditampilkan pada Real-Time Maps dengan indikator zona karbon.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),

        // Mini Real-Time Map Widget
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Stack(
            children: [
              // Background peta pesisir
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                  ),
                ),
              ),

              // Garis kontur laut & pulau sederhana
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Lingkaran zona karbon (Hijau)
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0x33059669),
                            border: Border.all(color: const Color(0xFF059669), width: 2),
                          ),
                        ),
                        const Icon(
                          Icons.location_on_rounded,
                          size: 40,
                          color: Color(0xFF059669),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Color(0x1A000000), blurRadius: 4),
                        ],
                      ),
                      child: Text(
                        _beachNameController.text,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ),
                  ],
                ),
              ),

              // Chip koordinat terkunci di sudut atas
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xE6FFFFFF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gps_fixed, size: 12, color: Color(0xFF0284C7)),
                      const SizedBox(width: 4),
                      Text(
                        _isLockingGps
                            ? 'Mengunci Satelit GPS...'
                            : (_lockedGps != null
                                ? 'Lat: ${_lockedGps!.latitude.toStringAsFixed(4)}, Lng: ${_lockedGps!.longitude.toStringAsFixed(4)}'
                                : 'Mengunci Satelit GPS...'),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

              // Badge Zona Karbon
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Zona Karbon Tinggi',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Detail Koordinat
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _infoRow('Lokasi Pantai', _beachNameController.text),
              const Divider(height: 12, color: Color(0xFFF1F5F9)),
              _infoRow(
                'Koordinat GPS',
                _lockedGps != null
                    ? '${_lockedGps!.latitude.toStringAsFixed(6)}, ${_lockedGps!.longitude.toStringAsFixed(6)}'
                    : 'Mendeteksi...',
              ),
              const Divider(height: 12, color: Color(0xFFF1F5F9)),
              _infoRow('Waktu Penguncian', '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} WIB (Real-Time)'),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Tombol Lanjut ke Tahap 4
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _currentStep = 3;
              });
            },
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Lanjut: Simpan ke Cloudinary & Sheets'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F4C81),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),

        const SizedBox(height: 10),
        Center(
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _currentStep = 1;
              });
            },
            icon: const Icon(Icons.arrow_back, size: 14),
            label: const Text('Kembali ke Verifikasi AI', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 4: SIMPAN KE CLOUDINARY & DATA JADI KE GOOGLE SHEETS
  // ---------------------------------------------------------------------------
  Widget _buildStep4CloudinarySheets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tahap 4: Simpan Foto & Kirim Data Jadi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Foto diunggah ke Cloudinary dan seluruh Data Jadi lengkap dikirim ke Google Sheets melalui Google Apps Script REST API.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),

        // Ringkasan Payload yang Siap Dikirim
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
              const Text('Ringkasan Data Jadi (Siap ke Sheets):',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 10),
              _summaryItem('Pelapor', _fishermanController.text),
              _summaryItem('Pantai', _beachNameController.text),
              _summaryItem('Spesies AI', '${_aiResult?.species ?? "-"} (${((_aiResult?.confidence ?? 0) * 100).toStringAsFixed(0)}%)'),
              _summaryItem('Estimasi Karbon', '${_aiResult?.estimatedCarbonKgCo2eM2 ?? 0} kg CO2e/m² (${_aiResult?.estimatedCarbonTonHa ?? 0} ton/ha)'),
              _summaryItem('Koordinat', '${_lockedGps?.latitude.toStringAsFixed(4)}, ${_lockedGps?.longitude.toStringAsFixed(4)}'),
              _summaryItem('Status ESP32', _attachEsp32Data ? 'Ya, Dilampirkan Kualitas Air' : 'Tidak Dilampirkan (Opsional)'),
              const Divider(height: 14, color: Color(0xFFF1F5F9)),
              const Row(
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 16, color: Color(0xFF0284C7)),
                  SizedBox(width: 6),
                  Text('Target Foto: Cloudinary API (secure_url)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
              const SizedBox(height: 4),
              const Row(
                children: [
                  Icon(Icons.table_chart_outlined, size: 16, color: Color(0xFF059669)),
                  SizedBox(width: 6),
                  Text('Target Data: Google Sheets via Apps Script', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        if (_isSubmitting)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _submissionStatusText,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Tombol Eksekusi Kirim
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submitToCloudinaryAndSheets,
            icon: const Icon(Icons.send_rounded),
            label: const Text(
              'Kirim Laporan (Cloudinary & Google Sheets)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),

        const SizedBox(height: 10),
        Center(
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _currentStep = 2;
              });
            },
            icon: const Icon(Icons.arrow_back, size: 14),
            label: const Text('Kembali ke Koordinat & Peta', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _summaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }
}

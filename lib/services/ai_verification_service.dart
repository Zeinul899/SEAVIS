import 'dart:math';

/// Hasil Evaluasi Verifikasi AI MobileNetV2 & Deteksi Karbon
class AiVerificationResult {
  final bool isVerified;
  final bool isSeagrass;
  final double confidence; // 0.0 - 1.0 (Syarat lolos >= 0.80)
  final String species;
  final String commonName;
  final double coveragePercentage; // 0 - 100%
  final double estimatedCarbonKgCo2eM2;
  final double estimatedCarbonTonHa;
  final String carbonZoneCategory; // "HIGH_CARBON", "MEDIUM_CARBON", "LOW_CARBON"
  final String explanation;
  final String? rejectionReason;

  const AiVerificationResult({
    required this.isVerified,
    required this.isSeagrass,
    required this.confidence,
    required this.species,
    required this.commonName,
    required this.coveragePercentage,
    required this.estimatedCarbonKgCo2eM2,
    required this.estimatedCarbonTonHa,
    required this.carbonZoneCategory,
    required this.explanation,
    this.rejectionReason,
  });
}

/// Service Verifikasi Edge AI (MobileNetV2 TFLite Engine & Carbon Estimator)
class AiVerificationService {
  AiVerificationService._();

  // Ambang batas akurasi minimal (80% / 0.80)
  static const double minimumConfidenceThreshold = 0.80;

  // Database spesies lamun tropis Indonesia (Pesisir Jawa, Bali, Maluku, Karimunjawa)
  static final List<Map<String, dynamic>> _seagrassSpeciesDatabase = [
    {
      'species': 'Enhalus acoroides',
      'commonName': 'Lamun Daun Pita Besar',
      'baseCarbon': 5.4, // kg CO2e/m2
      'baseTon': 148.5,  // ton C/ha
      'description': 'Spesies dominan di pesisir berlumpur/pasir dengan biomassa karbon biru tinggi.',
    },
    {
      'species': 'Thalassia hemprichii',
      'commonName': 'Lamun Daging / Daun Rata',
      'baseCarbon': 4.6,
      'baseTon': 126.8,
      'description': 'Tumbuh melimpah di perairan terumbu karang dangkal dengan rimpang tebal.',
    },
    {
      'species': 'Halodule uninervis',
      'commonName': 'Lamun Daun Jarum Ramping',
      'baseCarbon': 3.5,
      'baseTon': 95.2,
      'description': 'Spesies perintis yang cepat pulih dan mengikat sedimen karbon pantai.',
    },
    {
      'species': 'Cymodocea rotundata',
      'commonName': 'Lamun Daun Sendok Bulat',
      'baseCarbon': 4.1,
      'baseTon': 112.4,
      'description': 'Membentuk tutupan rapat di zona pasang surut intertidal.',
    },
  ];

  /// Verifikasi foto lamun menggunakan Edge AI Model
  /// [photoTypeKey]: Key preset atau indikator foto (contoh: "valid_enhalus", "valid_thalassia", "invalid_trash", "invalid_sand")
  static Future<AiVerificationResult> verifyPhoto({
    required String photoTypeKey,
    String? customNote,
  }) async {
    // Simulasi inferensi tensor TFLite MobileNetV2 (1000 - 1500ms)
    await Future.delayed(const Duration(milliseconds: 1200));

    final random = Random();

    // Skenario Foto BUKAN LAMUN atau TIDAK MEMENUHI SYARAT (Akurasi < 80%)
    if (photoTypeKey.contains('invalid') || photoTypeKey.contains('trash') || photoTypeKey.contains('sand')) {
      final failConfidence = 0.35 + (random.nextDouble() * 0.35); // 35% - 70% (< 80%)
      return AiVerificationResult(
        isVerified: false,
        isSeagrass: false,
        confidence: double.parse(failConfidence.toStringAsFixed(2)),
        species: 'Bukan Padang Lamun',
        commonName: 'Objek Tidak Teridentifikasi (Batu/Sampah/Pasir Kosong)',
        coveragePercentage: 0.0,
        estimatedCarbonKgCo2eM2: 0.0,
        estimatedCarbonTonHa: 0.0,
        carbonZoneCategory: 'LOW_CARBON',
        explanation: 'AI mendeteksi objek didominasi pasir atau puing non-organik.',
        rejectionReason: 'Akurasi AI (${(failConfidence * 100).toStringAsFixed(1)}%) di bawah syarat minimal 80.0%. Foto tidak memenuhi kriteria padang lamun.',
      );
    }

    // Skenario FOTO VALID LAMUN (Akurasi >= 80%)
    final chosenSpecies = _seagrassSpeciesDatabase[random.nextInt(_seagrassSpeciesDatabase.length)];
    final confidence = 0.84 + (random.nextDouble() * 0.12); // 84% - 96% (Lolos >= 80%)
    final coverage = 65.0 + (random.nextDouble() * 30.0); // 65% - 95% tutupan hijau

    // Kalkulasi serapan karbon berdasarkan rasio tutupan hijau lamun
    final coverageFactor = coverage / 100.0;
    final baseKg = chosenSpecies['baseCarbon'] as double;
    final baseTon = chosenSpecies['baseTon'] as double;

    final estimatedKg = double.parse((baseKg * coverageFactor).toStringAsFixed(2));
    final estimatedTon = double.parse((baseTon * coverageFactor).toStringAsFixed(1));

    // Kategori Zona Karbon
    String zoneCategory;
    if (estimatedKg >= 4.8) {
      zoneCategory = 'HIGH_CARBON'; // Hijau
    } else if (estimatedKg >= 3.2) {
      zoneCategory = 'MEDIUM_CARBON'; // Kuning
    } else {
      zoneCategory = 'LOW_CARBON'; // Merah
    }

    return AiVerificationResult(
      isVerified: true,
      isSeagrass: true,
      confidence: double.parse(confidence.toStringAsFixed(2)),
      species: chosenSpecies['species'] as String,
      commonName: chosenSpecies['commonName'] as String,
      coveragePercentage: double.parse(coverage.toStringAsFixed(1)),
      estimatedCarbonKgCo2eM2: estimatedKg,
      estimatedCarbonTonHa: estimatedTon,
      carbonZoneCategory: zoneCategory,
      explanation: chosenSpecies['description'] as String,
    );
  }
}

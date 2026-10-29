import 'dart:convert';

/// Model untuk Data Pendukung ESP32 (Kualitas Air & Karbon)
class Esp32SupportData {
  final bool isAttached;
  final double? waterTempC;
  final double? ph;
  final double? tdsPpm;
  final double? turbidityNtu;
  final String waterCarbonStatus; // "OPTIMAL", "MODERAT", "KRITIS"

  const Esp32SupportData({
    this.isAttached = false,
    this.waterTempC,
    this.ph,
    this.tdsPpm,
    this.turbidityNtu,
    this.waterCarbonStatus = "OPTIMAL",
  });

  Esp32SupportData copyWith({
    bool? isAttached,
    double? waterTempC,
    double? ph,
    double? tdsPpm,
    double? turbidityNtu,
    String? waterCarbonStatus,
  }) {
    return Esp32SupportData(
      isAttached: isAttached ?? this.isAttached,
      waterTempC: waterTempC ?? this.waterTempC,
      ph: ph ?? this.ph,
      tdsPpm: tdsPpm ?? this.tdsPpm,
      turbidityNtu: turbidityNtu ?? this.turbidityNtu,
      waterCarbonStatus: waterCarbonStatus ?? this.waterCarbonStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'is_attached': isAttached,
      'water_temp_c': waterTempC,
      'ph': ph,
      'tds_ppm': tdsPpm,
      'turbidity_ntu': turbidityNtu,
      'water_carbon_status': waterCarbonStatus,
    };
  }

  factory Esp32SupportData.fromMap(Map<String, dynamic> map) {
    return Esp32SupportData(
      isAttached: map['is_attached'] == true,
      waterTempC: (map['water_temp_c'] as num?)?.toDouble(),
      ph: (map['ph'] as num?)?.toDouble(),
      tdsPpm: (map['tds_ppm'] as num?)?.toDouble(),
      turbidityNtu: (map['turbidity_ntu'] as num?)?.toDouble(),
      waterCarbonStatus: map['water_carbon_status'] as String? ?? "OPTIMAL",
    );
  }
}

/// Model untuk Koordinat GPS
class GpsCoordinate {
  final double latitude;
  final double longitude;

  const GpsCoordinate({
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory GpsCoordinate.fromMap(Map<String, dynamic> map) {
    return GpsCoordinate(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Model Data Jadi Laporan Padang Lamun (Seagrass Guard)
class SeagrassReportModel {
  final String reportId;
  final String timestamp;
  final String fishermanName;
  final String beachName;
  final String beachNotes;
  final bool aiVerified;
  final String species;
  final double aiConfidence;
  final double estimatedCarbonKgCo2eM2;
  final double estimatedCarbonTonHa;
  final String carbonZoneCategory; // "HIGH_CARBON", "MEDIUM_CARBON", "LOW_CARBON"
  final GpsCoordinate gps;
  final String cloudinaryImageUrl;
  final Esp32SupportData esp32SupportData;

  const SeagrassReportModel({
    required this.reportId,
    required this.timestamp,
    required this.fishermanName,
    required this.beachName,
    required this.beachNotes,
    required this.aiVerified,
    required this.species,
    required this.aiConfidence,
    required this.estimatedCarbonKgCo2eM2,
    required this.estimatedCarbonTonHa,
    required this.carbonZoneCategory,
    required this.gps,
    required this.cloudinaryImageUrl,
    this.esp32SupportData = const Esp32SupportData(),
  });

  SeagrassReportModel copyWith({
    String? reportId,
    String? timestamp,
    String? fishermanName,
    String? beachName,
    String? beachNotes,
    bool? aiVerified,
    String? species,
    double? aiConfidence,
    double? estimatedCarbonKgCo2eM2,
    double? estimatedCarbonTonHa,
    String? carbonZoneCategory,
    GpsCoordinate? gps,
    String? cloudinaryImageUrl,
    Esp32SupportData? esp32SupportData,
  }) {
    return SeagrassReportModel(
      reportId: reportId ?? this.reportId,
      timestamp: timestamp ?? this.timestamp,
      fishermanName: fishermanName ?? this.fishermanName,
      beachName: beachName ?? this.beachName,
      beachNotes: beachNotes ?? this.beachNotes,
      aiVerified: aiVerified ?? this.aiVerified,
      species: species ?? this.species,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      estimatedCarbonKgCo2eM2:
          estimatedCarbonKgCo2eM2 ?? this.estimatedCarbonKgCo2eM2,
      estimatedCarbonTonHa: estimatedCarbonTonHa ?? this.estimatedCarbonTonHa,
      carbonZoneCategory: carbonZoneCategory ?? this.carbonZoneCategory,
      gps: gps ?? this.gps,
      cloudinaryImageUrl: cloudinaryImageUrl ?? this.cloudinaryImageUrl,
      esp32SupportData: esp32SupportData ?? this.esp32SupportData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'report_id': reportId,
      'timestamp': timestamp,
      'fisherman_name': fishermanName,
      'beach_name': beachName,
      'beach_notes': beachNotes,
      'ai_verified': aiVerified,
      'species': species,
      'ai_confidence': aiConfidence,
      'estimated_carbon_kg_co2e_m2': estimatedCarbonKgCo2eM2,
      'estimated_carbon_ton_ha': estimatedCarbonTonHa,
      'carbon_zone_category': carbonZoneCategory,
      'gps': gps.toMap(),
      'cloudinary_image_url': cloudinaryImageUrl,
      'esp32_support_data': esp32SupportData.toMap(),
    };
  }

  factory SeagrassReportModel.fromMap(Map<String, dynamic> map) {
    return SeagrassReportModel(
      reportId: map['report_id'] as String? ?? '',
      timestamp: map['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      fishermanName: map['fisherman_name'] as String? ?? '',
      beachName: map['beach_name'] as String? ?? '',
      beachNotes: map['beach_notes'] as String? ?? '',
      aiVerified: map['ai_verified'] == true,
      species: map['species'] as String? ?? 'Enhalus acoroides',
      aiConfidence: (map['ai_confidence'] as num?)?.toDouble() ?? 0.0,
      estimatedCarbonKgCo2eM2:
          (map['estimated_carbon_kg_co2e_m2'] as num?)?.toDouble() ?? 0.0,
      estimatedCarbonTonHa:
          (map['estimated_carbon_ton_ha'] as num?)?.toDouble() ?? 0.0,
      carbonZoneCategory: map['carbon_zone_category'] as String? ?? 'MEDIUM_CARBON',
      gps: map['gps'] != null
          ? GpsCoordinate.fromMap(map['gps'] as Map<String, dynamic>)
          : const GpsCoordinate(latitude: -6.5528, longitude: 110.6508),
      cloudinaryImageUrl: map['cloudinary_image_url'] as String? ?? '',
      esp32SupportData: map['esp32_support_data'] != null
          ? Esp32SupportData.fromMap(
              map['esp32_support_data'] as Map<String, dynamic>)
          : const Esp32SupportData(),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory SeagrassReportModel.fromJson(String source) =>
      SeagrassReportModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

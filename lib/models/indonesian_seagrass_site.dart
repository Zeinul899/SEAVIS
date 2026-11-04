/// Model Data Sebaran Padang Lamun Valid di Indonesia
/// Berdasarkan riset ilmiah Pusat Riset Oseanografi BRIN / PPO-LIPI & COREMAP-CTI
class IndonesianSeagrassSite {
  final String id;
  final String name;
  final String regency;
  final String province;
  final String islandGroup;
  final double latitude;
  final double longitude;
  final List<String> speciesList;
  final String dominantSpecies;
  final double coveragePercentage;
  final double estimatedCarbonTonHa;
  final double estimatedCarbonKgCo2eM2;
  final String conditionStatus; // "Kaya / Sangat Sehat", "Sedang", "Kurang Sehat"
  final double areaHectares;
  final String verifiedSource;
  final String notes;

  const IndonesianSeagrassSite({
    required this.id,
    required this.name,
    required this.regency,
    required this.province,
    required this.islandGroup,
    required this.latitude,
    required this.longitude,
    required this.speciesList,
    required this.dominantSpecies,
    required this.coveragePercentage,
    required this.estimatedCarbonTonHa,
    required this.estimatedCarbonKgCo2eM2,
    required this.conditionStatus,
    required this.areaHectares,
    required this.verifiedSource,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'regency': regency,
      'province': province,
      'islandGroup': islandGroup,
      'latitude': latitude,
      'longitude': longitude,
      'speciesList': speciesList,
      'dominantSpecies': dominantSpecies,
      'coveragePercentage': coveragePercentage,
      'estimatedCarbonTonHa': estimatedCarbonTonHa,
      'estimatedCarbonKgCo2eM2': estimatedCarbonKgCo2eM2,
      'conditionStatus': conditionStatus,
      'areaHectares': areaHectares,
      'verifiedSource': verifiedSource,
      'notes': notes,
    };
  }
}

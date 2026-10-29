import 'dart:math';
import '../models/seagrass_report_model.dart';

/// Service Pengambil Titik Koordinat GPS & Real-Time Coastal Positioning
class LocationMapService {
  LocationMapService._();

  // Daftar titik pesisir padang lamun penting di Indonesia
  static final List<Map<String, dynamic>> _knownCoastalSites = [
    {
      'name': 'Pantai Bandengan, Jepara',
      'lat': -6.5528,
      'lng': 110.6508,
      'region': 'Jawa Tengah',
    },
    {
      'name': 'Pantai Prawean, Jepara',
      'lat': -6.5684,
      'lng': 110.6481,
      'region': 'Jawa Tengah',
    },
    {
      'name': 'Teluk Kemujan, Karimunjawa',
      'lat': -5.8115,
      'lng': 110.4722,
      'region': 'Kepulauan Karimunjawa',
    },
    {
      'name': 'Pesisir Tanjung Benoa, Badung',
      'lat': -8.7523,
      'lng': 115.2215,
      'region': 'Bali',
    },
    {
      'name': 'Pantai Sanur Timur, Denpasar',
      'lat': -8.6881,
      'lng': 115.2635,
      'region': 'Bali',
    },
    {
      'name': 'Teluk Ekas, Lombok Timur',
      'lat': -8.8741,
      'lng': 116.4529,
      'region': 'Nusa Tenggara Barat',
    },
  ];

  /// Mengunci koordinat GPS saat ini (Tahap 3 Alur Utama)
  static Future<GpsCoordinate> lockCurrentGps({String? preferredBeachName}) async {
    // Simulasi akuisisi satelit GPS (600ms)
    await Future.delayed(const Duration(milliseconds: 600));

    if (preferredBeachName != null && preferredBeachName.isNotEmpty) {
      for (final site in _knownCoastalSites) {
        if (site['name'].toString().toLowerCase().contains(preferredBeachName.toLowerCase())) {
          return GpsCoordinate(
            latitude: site['lat'] as double,
            longitude: site['lng'] as double,
          );
        }
      }
    }

    // Default Jepara / Bandengan dengan variasi mikro GPS
    final random = Random();
    final deltaLat = (random.nextDouble() - 0.5) * 0.005;
    final deltaLng = (random.nextDouble() - 0.5) * 0.005;

    return GpsCoordinate(
      latitude: double.parse((-6.5528 + deltaLat).toStringAsFixed(6)),
      longitude: double.parse((110.6508 + deltaLng).toStringAsFixed(6)),
    );
  }

  /// Mendapatkan daftar lokasi pesisir referensi untuk nelayan
  static List<Map<String, dynamic>> get knownSites => _knownCoastalSites;
}

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/indonesian_seagrass_site.dart';
import '../services/location_map_service.dart';

/// Screen Live Coastal Map Indonesia Offline
/// Menampilkan Peta Vektor Kepulauan Indonesia Offline,
/// Titik Lokasi Akurat Nelayan via Geolocator,
/// serta Database Sebaran Padang Lamun Valid Nasional (Data Asli BRIN / LIPI, Bukan Simulasi).
class RealtimeCarbonMapScreen extends StatefulWidget {
  static bool enableInfiniteAnimation = true;

  const RealtimeCarbonMapScreen({super.key});

  @override
  State<RealtimeCarbonMapScreen> createState() => _RealtimeCarbonMapScreenState();
}

class _RealtimeCarbonMapScreenState extends State<RealtimeCarbonMapScreen>
    with SingleTickerProviderStateMixin {
  // Kontrol Tampilan & Filter
  String _selectedRegionFilter = 'ALL'; // ALL, Jawa, Bali & Nusa Tenggara, Sulawesi, Maluku & Papua, Sumatera, Kalimantan
  IndonesianSeagrassSite? _selectedSite;
  final String _searchQuery = '';

  // Geolocator State
  Position? _currentGpsPosition;
  bool _isFetchingGps = false;
  String? _gpsStatusMessage;

  // Ukuran Kanvas Virtual Peta Indonesia (Proyeksi Geografis Bujur 94°E-142°E & Lintang 6.5°N - -11.5°S)
  static const double _mapCanvasWidth = 1440.0;
  static const double _mapCanvasHeight = 600.0;

  final TransformationController _transformationController = TransformationController();
  late AnimationController _pulseController;

  List<IndonesianSeagrassSite> get _allSites => LocationMapService.verifiedIndonesianSites;

  List<IndonesianSeagrassSite> get _filteredSites {
    return _allSites.where((site) {
      final matchesRegion = _selectedRegionFilter == 'ALL' ||
          site.islandGroup == _selectedRegionFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          site.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          site.province.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          site.dominantSpecies.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesRegion && matchesSearch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (RealtimeCarbonMapScreen.enableInfiniteAnimation) {
      _pulseController.repeat(reverse: true);
    }

    // Pilih site pertama (Pantai Bandengan Jepara) sebagai default
    if (_allSites.isNotEmpty) {
      _selectedSite = _allSites.first;
    }

    // Ambil posisi GPS asli perangkat via Geolocator
    _fetchRealGpsPosition();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  /// Mengambil titik koordinat GPS riil nelayan via modul Geolocator
  Future<void> _fetchRealGpsPosition() async {
    setState(() {
      _isFetchingGps = true;
      _gpsStatusMessage = 'Mengunci sinyal satelit GPS...';
    });

    try {
      final position = await LocationMapService.getRealCurrentPosition();
      if (!mounted) return;

      setState(() {
        _isFetchingGps = false;
        if (position != null) {
          _currentGpsPosition = position;
          _gpsStatusMessage =
              'GPS Terkunci: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)} (±${position.accuracy.toStringAsFixed(0)}m)';
        } else {
          _gpsStatusMessage = 'GPS mati / izin belum aktif. Menggunakan referensi pesisir.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFetchingGps = false;
        _gpsStatusMessage = 'Gagal membaca GPS: $e';
      });
    }
  }

  /// Memusatkan tampilan peta ke koordinat GPS nelayan saat ini
  void _centerToUserLocation() {
    if (_currentGpsPosition == null) {
      _fetchRealGpsPosition();
      return;
    }

    final userOffset = _geoToCanvas(
      _currentGpsPosition!.latitude,
      _currentGpsPosition!.longitude,
    );

    // Pusatkan viewport InteractiveViewer
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height * 0.55;

    const scale = 2.2;
    final targetX = -(userOffset.dx * scale - screenWidth / 2);
    final targetY = -(userOffset.dy * scale - screenHeight / 2);

    final matrix = Matrix4.identity();
    matrix.setEntry(0, 0, scale);
    matrix.setEntry(1, 1, scale);
    matrix.setEntry(0, 3, targetX);
    matrix.setEntry(1, 3, targetY);

    _transformationController.value = matrix;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Peta dipusatkan ke koordinat GPS Anda: ${_currentGpsPosition!.latitude.toStringAsFixed(5)}, ${_currentGpsPosition!.longitude.toStringAsFixed(5)}',
        ),
        backgroundColor: const Color(0xFF0284C7),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Mengubah koordinat (Lintang, Bujur) menjadi titik koordinat piksel Kanvas Peta Indonesia
  static Offset _geoToCanvas(double lat, double lng) {
    const minLng = 94.0;
    const maxLng = 142.0;
    const minLat = -11.5;
    const maxLat = 6.5;

    final x = ((lng - minLng) / (maxLng - minLng)) * _mapCanvasWidth;
    final y = ((maxLat - lat) / (maxLat - minLat)) * _mapCanvasHeight;

    return Offset(
      x.clamp(0.0, _mapCanvasWidth),
      y.clamp(0.0, _mapCanvasHeight),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A192F),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live Coastal Map Indonesia',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Map Offline • Data Ilmiah BRIN / LIPI',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F233E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Pusatkan ke Lokasi Saya (GPS)',
            icon: Icon(
              Icons.my_location,
              color: _currentGpsPosition != null ? const Color(0xFF38BDF8) : Colors.white70,
            ),
            onPressed: _centerToUserLocation,
          ),
          IconButton(
            tooltip: 'Segarkan GPS',
            icon: _isFetchingGps
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh),
            onPressed: _fetchRealGpsPosition,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildRegionFilterBar(),
        ),
      ),
      body: Stack(
        children: [
          // 1. KANVAS PETA INDONESIA OFFLINE (INTERACTIVE VIEWER DENGAN ZOOM & PAN)
          _buildOfflineInteractiveMap(),

          // 2. STATUS GPS CHIP DI ATAS
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _buildGpsStatusBanner(),
          ),

          // 3. KONTROL ZOOM & TOMBOL PUSATKAN GPS DI KANAN ATAS
          Positioned(
            right: 14,
            top: 70,
            child: _buildMapToolControls(),
          ),

          // 4. KARTU DETAIL PADANG LAMUN TERPILIH DI BAWAH
          if (_selectedSite != null)
            Positioned(
              left: 14,
              right: 14,
              bottom: 16,
              child: _buildSelectedSiteCard(_selectedSite!),
            ),
        ],
      ),
    );
  }

  Widget _buildRegionFilterBar() {
    final regions = [
      {'label': 'Seluruh Indonesia (${_allSites.length})', 'value': 'ALL'},
      {'label': 'Jawa (${_allSites.where((s) => s.islandGroup == 'Jawa').length})', 'value': 'Jawa'},
      {'label': 'Bali & Nusa Tenggara', 'value': 'Bali & Nusa Tenggara'},
      {'label': 'Sulawesi', 'value': 'Sulawesi'},
      {'label': 'Maluku & Papua', 'value': 'Maluku & Papua'},
      {'label': 'Sumatera', 'value': 'Sumatera'},
      {'label': 'Kalimantan', 'value': 'Kalimantan'},
    ];

    return Container(
      color: const Color(0xFF0F233E),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: regions.map((r) {
            final isSelected = _selectedRegionFilter == r['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: ChoiceChip(
                selected: isSelected,
                label: Text(
                  r['label']!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                  ),
                ),
                selectedColor: const Color(0xFF0284C7),
                backgroundColor: const Color(0xFF1E3A5F),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334E68),
                ),
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _selectedRegionFilter = r['value']!;
                    });
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGpsStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xE60F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _currentGpsPosition != null ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _currentGpsPosition != null ? Icons.gps_fixed : Icons.gps_not_fixed,
            size: 16,
            color: _currentGpsPosition != null ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _gpsStatusMessage ?? 'Memeriksa GPS perangkat...',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_currentGpsPosition != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _centerToUserLocation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Fokus',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapToolControls() {
    return Column(
      children: [
        FloatingActionButton.small(
          heroTag: 'center_gps_btn',
          backgroundColor: const Color(0xFF0284C7),
          onPressed: _centerToUserLocation,
          child: const Icon(Icons.my_location, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'reset_zoom_btn',
          backgroundColor: const Color(0xFF1E3A5F),
          onPressed: () {
            _transformationController.value = Matrix4.identity();
          },
          child: const Icon(Icons.zoom_out_map, color: Colors.white, size: 20),
        ),
      ],
    );
  }

  Widget _buildOfflineInteractiveMap() {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.8,
      maxScale: 6.0,
      boundaryMargin: const EdgeInsets.all(200),
      child: SizedBox(
        width: _mapCanvasWidth,
        height: _mapCanvasHeight,
        child: Stack(
          children: [
            // Layer 1: Gambar Garis Pantai & Kepulauan Indonesia Offline
            CustomPaint(
              size: const Size(_mapCanvasWidth, _mapCanvasHeight),
              painter: _IndonesiaArchipelagoPainter(),
            ),

            // Layer 2: Render Titik-Titik Padang Lamun Valid Indonesia (Data BRIN)
            ..._filteredSites.map((site) {
              final pos = _geoToCanvas(site.latitude, site.longitude);
              final isSelected = _selectedSite?.id == site.id;

              // Warna Pin berdasarkan estimasi stok karbon
              final Color pinColor = site.estimatedCarbonTonHa >= 145.0
                  ? const Color(0xFF10B981) // Karbon Sangat Tinggi
                  : const Color(0xFFF59E0B); // Karbon Sedang

              return Positioned(
                left: pos.dx - 18,
                top: pos.dy - 36,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSite = site;
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge Pin Lamun
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isSelected)
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: pinColor.withValues(alpha: 0.35),
                                border: Border.all(color: pinColor, width: 2),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : pinColor,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x66000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.eco_rounded,
                              size: isSelected ? 20 : 16,
                              color: isSelected ? pinColor : Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Label Nama Pantai
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0F172A)
                              : const Color(0xCC0F172A),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected ? pinColor : const Color(0xFF334E68),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          site.name.split(',').first,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Layer 3: Render Titik Lokasi Akurat Nelayan (Geolocator GPS Marker)
            if (_currentGpsPosition != null) ...[
              Builder(builder: (context) {
                final userPos = _geoToCanvas(
                  _currentGpsPosition!.latitude,
                  _currentGpsPosition!.longitude,
                );

                return Positioned(
                  left: userPos.dx - 22,
                  top: userPos.dy - 22,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final pulseVal = _pulseController.value;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Gelombang radar GPS berdenyut
                          Container(
                            width: 32 + (pulseVal * 16),
                            height: 32 + (pulseVal * 16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.35 * (1 - pulseVal)),
                              border: Border.all(
                                color: const Color(0xFF38BDF8),
                                width: 1.5,
                              ),
                            ),
                          ),
                          // Titik tengah surveyor
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x80000000),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedSiteCard(IndonesianSeagrassSite site) {
    // Hitung jarak real-time dari posisi GPS pengguna jika aktif
    double? distanceKm;
    if (_currentGpsPosition != null) {
      distanceKm = LocationMapService.calculateDistanceKm(
        _currentGpsPosition!.latitude,
        _currentGpsPosition!.longitude,
        site.latitude,
        site.longitude,
      );
    }

    final isHighCarbon = site.estimatedCarbonTonHa >= 145.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F233E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHighCarbon ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Nama Pantai, Provinsi, & Badge Zona Karbon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      site.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${site.regency}, ${site.province}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isHighCarbon ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                      .withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isHighCarbon ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  ),
                ),
                child: Text(
                  isHighCarbon ? 'ZONA KARBON TINGGI' : 'ZONA KARBON SEDANG',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isHighCarbon ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(color: Color(0xFF1E3A5F), height: 1),
          const SizedBox(height: 10),

          // Grid Data Ilmiah: Spesies Dominan, Tutupan Lamun, & Stok Karbon
          Row(
            children: [
              Expanded(
                child: _siteMetricItem(
                  icon: Icons.eco_outlined,
                  label: 'Spesies Dominan',
                  value: site.dominantSpecies,
                  valueColor: const Color(0xFF38BDF8),
                ),
              ),
              Expanded(
                child: _siteMetricItem(
                  icon: Icons.pie_chart_outline,
                  label: 'Tutupan Lamun',
                  value: '${site.coveragePercentage}% (${site.conditionStatus})',
                  valueColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _siteMetricItem(
                  icon: Icons.cloud_outlined,
                  label: 'Stok Karbon Biru',
                  value: '${site.estimatedCarbonTonHa} Ton/Ha (${site.estimatedCarbonKgCo2eM2} kg/m²)',
                  valueColor: const Color(0xFF34D399),
                ),
              ),
              Expanded(
                child: _siteMetricItem(
                  icon: Icons.straighten,
                  label: 'Jarak dari GPS Anda',
                  value: distanceKm != null
                      ? '${distanceKm.toStringAsFixed(1)} km'
                      : 'GPS belum aktif',
                  valueColor: distanceKm != null ? const Color(0xFFFBBF24) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Sumber Data Ilmiah & Catatan Lapangan
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0A192F),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified, color: Color(0xFF38BDF8), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Validasi: ${site.verifiedSource} • Luas: ${site.areaHectares.toStringAsFixed(0)} Ha',
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFFCBD5E1)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _siteMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Painter Vektor Kepulauan Indonesia Offline
/// Menggambar secara presisi pulau-pulau utama Indonesia, batas ZEE/WPPNRI,
/// dan garis koordinat Khatulistiwa tanpa koneksi internet.
class _IndonesiaArchipelagoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Warna Latar Belakang Samudra Indonesia
    final oceanPaint = Paint()..color = const Color(0xFF08182B);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), oceanPaint);

    // 2. Garis Kisi Koordinat / Graticules Kelautan
    final gridPaint = Paint()
      ..color = const Color(0x1F38BDF8)
      ..strokeWidth = 1.0;

    // Bujur Timur (100°E s/d 140°E)
    for (double lng = 95.0; lng <= 140.0; lng += 5.0) {
      final x = ((lng - 94.0) / 48.0) * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Lintang (5°N, 0°, -5°S, -10°S)
    for (double lat = 5.0; lat >= -10.0; lat -= 5.0) {
      final y = ((6.5 - lat) / 18.0) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 3. Garis Khatulistiwa 0° Ekuator (Emas Berpendar)
    final equatorY = ((6.5 - 0.0) / 18.0) * size.height;
    final equatorPaint = Paint()
      ..color = const Color(0x80F59E0B)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, equatorY), Offset(size.width, equatorY), equatorPaint);

    // 4. Catatan Label Wilayah Laut
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    void drawSeaLabel(String text, double x, double y) {
      textPainter.text = TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0x4D38BDF8),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x, y));
    }

    drawSeaLabel('SAMUDRA HINDIA', 240, 480);
    drawSeaLabel('LAUT JAWA (WPPNRI 712)', 460, 360);
    drawSeaLabel('LAUT SULAWESI', 780, 160);
    drawSeaLabel('LAUT BANDA', 920, 420);
    drawSeaLabel('SAMUDRA PASIFIK', 1140, 120);
    drawSeaLabel('LAUT ARAFURA', 1120, 500);

    // 5. Gambar Poligon Kepulauan Indonesia (Daratan & Pesisir)
    final landPaint = Paint()
      ..color = const Color(0xFF1E3A5F)
      ..style = PaintingStyle.fill;

    final coastPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    Offset proj(double lat, double lng) {
      final x = ((lng - 94.0) / 48.0) * size.width;
      final y = ((6.5 - lat) / 18.0) * size.height;
      return Offset(x, y);
    }

    // --- PULAU SUMATERA ---
    final sumatera = Path()
      ..moveTo(proj(5.5, 95.3).dx, proj(5.5, 95.3).dy) // Banda Aceh
      ..lineTo(proj(4.0, 98.6).dx, proj(4.0, 98.6).dy) // Medan
      ..lineTo(proj(1.5, 101.5).dx, proj(1.5, 101.5).dy) // Riau / Dumai
      ..lineTo(proj(-0.9, 104.5).dx, proj(-0.9, 104.5).dy) // Jambi
      ..lineTo(proj(-3.0, 106.0).dx, proj(-3.0, 106.0).dy) // Palembang
      ..lineTo(proj(-5.8, 105.8).dx, proj(-5.8, 105.8).dy) // Lampung Bakauheni
      ..lineTo(proj(-5.2, 104.0).dx, proj(-5.2, 104.0).dy) // Semangka
      ..lineTo(proj(-3.8, 102.3).dx, proj(-3.8, 102.3).dy) // Bengkulu
      ..lineTo(proj(-0.9, 100.3).dx, proj(-0.9, 100.3).dy) // Padang
      ..lineTo(proj(1.8, 98.7).dx, proj(1.8, 98.7).dy) // Sibolga
      ..lineTo(proj(4.2, 96.1).dx, proj(4.2, 96.1).dy) // Meulaboh
      ..close();
    canvas.drawPath(sumatera, landPaint);
    canvas.drawPath(sumatera, coastPaint);

    // Kepulauan Riau (Bintan/Batam) & Bangka Belitung
    canvas.drawCircle(proj(1.17, 104.4), 10, landPaint);
    canvas.drawCircle(proj(1.17, 104.4), 10, coastPaint);
    canvas.drawCircle(proj(-2.1, 106.1), 12, landPaint); // Bangka
    canvas.drawCircle(proj(-2.1, 106.1), 12, coastPaint);
    canvas.drawCircle(proj(-2.8, 107.8), 10, landPaint); // Belitung
    canvas.drawCircle(proj(-2.8, 107.8), 10, coastPaint);

    // --- PULAU JAWA & MADURA ---
    final jawa = Path()
      ..moveTo(proj(-6.0, 105.9).dx, proj(-6.0, 105.9).dy) // Merak Banten
      ..lineTo(proj(-6.1, 106.8).dx, proj(-6.1, 106.8).dy) // Jakarta
      ..lineTo(proj(-6.7, 108.5).dx, proj(-6.7, 108.5).dy) // Cirebon
      ..lineTo(proj(-6.9, 110.4).dx, proj(-6.9, 110.4).dy) // Semarang
      ..lineTo(proj(-6.55, 110.65).dx, proj(-6.55, 110.65).dy) // Muria / Jepara
      ..lineTo(proj(-6.9, 112.5).dx, proj(-6.9, 112.5).dy) // Tuban
      ..lineTo(proj(-7.2, 112.7).dx, proj(-7.2, 112.7).dy) // Surabaya
      ..lineTo(proj(-7.7, 114.0).dx, proj(-7.7, 114.0).dy) // Situbondo
      ..lineTo(proj(-8.7, 114.4).dx, proj(-8.7, 114.4).dy) // Banyuwangi / Purwo
      ..lineTo(proj(-8.4, 112.8).dx, proj(-8.4, 112.8).dy) // Malang Selatan
      ..lineTo(proj(-8.0, 110.3).dx, proj(-8.0, 110.3).dy) // Parangtritis / Yogya
      ..lineTo(proj(-7.7, 109.0).dx, proj(-7.7, 109.0).dy) // Cilacap
      ..lineTo(proj(-6.9, 106.5).dx, proj(-6.9, 106.5).dy) // Pelabuhan Ratu
      ..lineTo(proj(-6.8, 105.3).dx, proj(-6.8, 105.3).dy) // Ujung Kulon
      ..close();
    canvas.drawPath(jawa, landPaint);
    canvas.drawPath(jawa, coastPaint);

    // Madura
    final madura = Path()
      ..moveTo(proj(-7.0, 112.7).dx, proj(-7.0, 112.7).dy)
      ..lineTo(proj(-6.8, 113.8).dx, proj(-6.8, 113.8).dy)
      ..lineTo(proj(-7.2, 114.1).dx, proj(-7.2, 114.1).dy)
      ..close();
    canvas.drawPath(madura, landPaint);
    canvas.drawPath(madura, coastPaint);

    // Karimunjawa
    canvas.drawCircle(proj(-5.81, 110.47), 6, landPaint);
    canvas.drawCircle(proj(-5.81, 110.47), 6, coastPaint);

    // --- PULAU KALIMANTAN (BAGIAN INDONESIA) ---
    final kalimantan = Path()
      ..moveTo(proj(0.9, 108.9).dx, proj(0.9, 108.9).dy) // Sambas
      ..lineTo(proj(-0.0, 109.3).dx, proj(-0.0, 109.3).dy) // Pontianak
      ..lineTo(proj(-1.8, 109.9).dx, proj(-1.8, 109.9).dy) // Ketapang
      ..lineTo(proj(-3.0, 110.5).dx, proj(-3.0, 110.5).dy) // Kendawangan
      ..lineTo(proj(-3.4, 114.6).dx, proj(-3.4, 114.6).dy) // Banjarmasin
      ..lineTo(proj(-3.9, 116.2).dx, proj(-3.9, 116.2).dy) // Kotabaru
      ..lineTo(proj(-1.2, 116.8).dx, proj(-1.2, 116.8).dy) // Balikpapan
      ..lineTo(proj(0.5, 117.5).dx, proj(0.5, 117.5).dy) // Kutai / Samarinda
      ..lineTo(proj(2.2, 118.0).dx, proj(2.2, 118.0).dy) // Berau
      ..lineTo(proj(3.3, 117.6).dx, proj(3.3, 117.6).dy) // Tarakan
      ..lineTo(proj(4.1, 117.6).dx, proj(4.1, 117.6).dy) // Nunukan
      ..lineTo(proj(3.8, 115.5).dx, proj(3.8, 115.5).dy)
      ..lineTo(proj(1.5, 113.0).dx, proj(1.5, 113.0).dy)
      ..lineTo(proj(1.0, 110.5).dx, proj(1.0, 110.5).dy)
      ..close();
    canvas.drawPath(kalimantan, landPaint);
    canvas.drawPath(kalimantan, coastPaint);

    // Derawan
    canvas.drawCircle(proj(2.28, 118.24), 6, landPaint);
    canvas.drawCircle(proj(2.28, 118.24), 6, coastPaint);

    // --- PULAU SULAWESI ---
    final sulawesi = Path()
      ..moveTo(proj(1.5, 125.0).dx, proj(1.5, 125.0).dy) // Manado Bunaken
      ..lineTo(proj(0.8, 123.0).dx, proj(0.8, 123.0).dy) // Gorontalo
      ..lineTo(proj(0.9, 120.0).dx, proj(0.9, 120.0).dy) // Tolitoli
      ..lineTo(proj(-0.9, 119.8).dx, proj(-0.9, 119.8).dy) // Palu
      ..lineTo(proj(-2.7, 118.9).dx, proj(-2.7, 118.9).dy) // Mamuju
      ..lineTo(proj(-5.1, 119.4).dx, proj(-5.1, 119.4).dy) // Makassar
      ..lineTo(proj(-5.6, 120.5).dx, proj(-5.6, 120.5).dy) // Bira
      ..lineTo(proj(-3.0, 120.3).dx, proj(-3.0, 120.3).dy) // Palopo
      ..lineTo(proj(-4.0, 122.5).dx, proj(-4.0, 122.5).dy) // Kendari
      ..lineTo(proj(-5.3, 122.7).dx, proj(-5.3, 122.7).dy) // Buton
      ..lineTo(proj(-1.5, 121.5).dx, proj(-1.5, 121.5).dy) // Kolonodale
      ..lineTo(proj(-1.0, 123.5).dx, proj(-1.0, 123.5).dy) // Luwuk Banggai
      ..lineTo(proj(0.1, 121.0).dx, proj(0.1, 121.0).dy)
      ..close();
    canvas.drawPath(sulawesi, landPaint);
    canvas.drawPath(sulawesi, coastPaint);

    // Wakatobi
    canvas.drawCircle(proj(-5.75, 123.93), 7, landPaint);
    canvas.drawCircle(proj(-5.75, 123.93), 7, coastPaint);

    // --- BALI & KEPULAUAN NUSA TENGGARA ---
    // Bali
    final bali = Path()
      ..addOval(Rect.fromCenter(center: proj(-8.4, 115.1), width: 28, height: 18));
    canvas.drawPath(bali, landPaint);
    canvas.drawPath(bali, coastPaint);

    // Lombok
    final lombok = Path()
      ..addOval(Rect.fromCenter(center: proj(-8.6, 116.3), width: 24, height: 22));
    canvas.drawPath(lombok, landPaint);
    canvas.drawPath(lombok, coastPaint);

    // Sumbawa
    final sumbawa = Path()
      ..addOval(Rect.fromCenter(center: proj(-8.6, 118.0), width: 50, height: 20));
    canvas.drawPath(sumbawa, landPaint);
    canvas.drawPath(sumbawa, coastPaint);

    // Komodo & Flores
    final flores = Path()
      ..addOval(Rect.fromCenter(center: proj(-8.6, 121.0), width: 65, height: 18));
    canvas.drawPath(flores, landPaint);
    canvas.drawPath(flores, coastPaint);

    // Sumba
    final sumba = Path()
      ..addOval(Rect.fromCenter(center: proj(-9.7, 119.9), width: 34, height: 18));
    canvas.drawPath(sumba, landPaint);
    canvas.drawPath(sumba, coastPaint);

    // Timor (Indonesia / Kupang)
    final timor = Path()
      ..addOval(Rect.fromCenter(center: proj(-9.8, 124.3), width: 44, height: 18));
    canvas.drawPath(timor, landPaint);
    canvas.drawPath(timor, coastPaint);

    // --- KEPULAUAN MALUKU ---
    // Halmahera
    final halmahera = Path()
      ..moveTo(proj(1.8, 127.8).dx, proj(1.8, 127.8).dy)
      ..lineTo(proj(0.5, 127.9).dx, proj(0.5, 127.9).dy)
      ..lineTo(proj(-0.5, 128.5).dx, proj(-0.5, 128.5).dy)
      ..close();
    canvas.drawPath(halmahera, landPaint);
    canvas.drawPath(halmahera, coastPaint);

    // Seram & Ambon
    final seram = Path()
      ..addOval(Rect.fromCenter(center: proj(-3.1, 129.0), width: 52, height: 16));
    canvas.drawPath(seram, landPaint);
    canvas.drawPath(seram, coastPaint);
    canvas.drawCircle(proj(-3.65, 128.25), 6, landPaint); // Ambon
    canvas.drawCircle(proj(-3.65, 128.25), 6, coastPaint);

    // --- PULAU PAPUA (BAGIAN INDONESIA) ---
    final papua = Path()
      ..moveTo(proj(-0.8, 131.2).dx, proj(-0.8, 131.2).dy) // Sorong Raja Ampat
      ..lineTo(proj(-0.8, 134.0).dx, proj(-0.8, 134.0).dy) // Manokwari
      ..lineTo(proj(-2.5, 134.5).dx, proj(-2.5, 134.5).dy) // Teluk Cenderawasih
      ..lineTo(proj(-2.5, 140.7).dx, proj(-2.5, 140.7).dy) // Jayapura
      ..lineTo(proj(-8.5, 141.0).dx, proj(-8.5, 141.0).dy) // Perbatasan Merauke
      ..lineTo(proj(-8.5, 140.4).dx, proj(-8.5, 140.4).dy) // Merauke
      ..lineTo(proj(-5.0, 138.0).dx, proj(-5.0, 138.0).dy) // Asmat
      ..lineTo(proj(-4.5, 136.5).dx, proj(-4.5, 136.5).dy) // Mimika
      ..lineTo(proj(-3.5, 133.5).dx, proj(-3.5, 133.5).dy) // Kaimana
      ..close();
    canvas.drawPath(papua, landPaint);
    canvas.drawPath(papua, coastPaint);

    // Raja Ampat (Misool / Waigeo)
    canvas.drawCircle(proj(-1.88, 130.15), 10, landPaint);
    canvas.drawCircle(proj(-1.88, 130.15), 10, coastPaint);

    // Biak Numfor
    canvas.drawCircle(proj(-1.21, 136.38), 9, landPaint);
    canvas.drawCircle(proj(-1.21, 136.38), 9, coastPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

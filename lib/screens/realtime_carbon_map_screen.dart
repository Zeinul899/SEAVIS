import 'package:flutter/material.dart';
import '../models/seagrass_report_model.dart';
import '../services/cloudinary_sheets_service.dart';

class RealtimeCarbonMapScreen extends StatefulWidget {
  const RealtimeCarbonMapScreen({super.key});

  @override
  State<RealtimeCarbonMapScreen> createState() => _RealtimeCarbonMapScreenState();
}

class _RealtimeCarbonMapScreenState extends State<RealtimeCarbonMapScreen> {
  String _selectedZoneFilter = 'ALL'; // ALL, HIGH_CARBON, MEDIUM_CARBON, LOW_CARBON
  SeagrassReportModel? _selectedReport;

  List<SeagrassReportModel> get _reports => CloudinarySheetsService.cachedReports;

  List<SeagrassReportModel> get _filteredReports {
    if (_selectedZoneFilter == 'ALL') return _reports;
    return _reports.where((r) => r.carbonZoneCategory == _selectedZoneFilter).toList();
  }

  @override
  void initState() {
    super.initState();
    if (_reports.isNotEmpty) {
      _selectedReport = _reports.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Real-Time Maps & Wilayah Karbon',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              'Sinkronisasi Titik Laporan Lolos AI & Google Sheets',
              style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildFilterBar(),
        ),
      ),
      body: Stack(
        children: [
          // Kanvas Peta Interaktif
          _buildMapCanvas(),

          // Kartu Detail Pin Terpilih di Bawah
          if (_selectedReport != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _buildSelectedReportCard(_selectedReport!),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('Semua Zona (${_reports.length})', 'ALL'),
            const SizedBox(width: 6),
            _filterChip('Karbon Tinggi', 'HIGH_CARBON', color: const Color(0xFF059669)),
            const SizedBox(width: 6),
            _filterChip('Karbon Sedang', 'MEDIUM_CARBON', color: const Color(0xFFD97706)),
            const SizedBox(width: 6),
            _filterChip('Karbon Rendah', 'LOW_CARBON', color: const Color(0xFFDC2626)),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value, {Color? color}) {
    final isSelected = _selectedZoneFilter == value;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedZoneFilter = value;
          });
        }
      },
      avatar: color != null
          ? Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle))
          : null,
      label: Text(
        label,
        style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : const Color(0xFF1E293B)),
      ),
      selectedColor: const Color(0xFF0F4C81),
      backgroundColor: const Color(0xFFF1F5F9),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
    );
  }

  Widget _buildMapCanvas() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFE0F2FE),
      ),
      child: Stack(
        children: [
          // Garis kisi peta / gridlines kelautan
          CustomPaint(
            size: Size.infinite,
            painter: _MarineGridPainter(),
          ),

          // Pesisir Pantai Jawa & Bali Simbolis
          Positioned(
            top: 60,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xCCFFFFFF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Laut Jawa & Selat Madura (WPPNRI 712)',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
            ),
          ),

          // Render Marker Titik-Titik Laporan
          ...List.generate(_filteredReports.length, (index) {
            final report = _filteredReports[index];
            // Posisi visual terdistribusi di peta
            final double topPos = 120.0 + (index * 90.0);
            final double leftPos = 40.0 + (index * 75.0);

            final isSelected = _selectedReport?.reportId == report.reportId;

            Color markerColor = const Color(0xFF059669);
            if (report.carbonZoneCategory == 'MEDIUM_CARBON') {
              markerColor = const Color(0xFFD97706);
            } else if (report.carbonZoneCategory == 'LOW_CARBON') {
              markerColor = const Color(0xFFDC2626);
            }

            return Positioned(
              top: topPos,
              left: leftPos,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedReport = report;
                  });
                },
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Lingkaran zona pelacak karbon
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: isSelected ? 56 : 38,
                          height: isSelected ? 56 : 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: markerColor.withValues(alpha: isSelected ? 0.35 : 0.2),
                            border: Border.all(color: markerColor, width: isSelected ? 2 : 1),
                          ),
                        ),
                        Icon(
                          Icons.location_on_rounded,
                          size: isSelected ? 36 : 28,
                          color: markerColor,
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: const [
                          BoxShadow(color: Color(0x1A000000), blurRadius: 2),
                        ],
                      ),
                      child: Text(
                        report.beachName.split(',').first,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Legenda Peta
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xEBFFFFFF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Legenda Wilayah Karbon:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _legendItem('Tinggi (>= 4.8 kg/m²)', const Color(0xFF059669)),
                  _legendItem('Sedang (3.2 - 4.7 kg/m²)', const Color(0xFFD97706)),
                  _legendItem('Kritis (< 3.2 kg/m²)', const Color(0xFFDC2626)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 8, color: Color(0xFF475569))),
        ],
      ),
    );
  }

  Widget _buildSelectedReportCard(SeagrassReportModel report) {
    Color badgeColor = const Color(0xFF059669);
    String zoneName = 'ZONA KARBON TINGGI';
    if (report.carbonZoneCategory == 'MEDIUM_CARBON') {
      badgeColor = const Color(0xFFD97706);
      zoneName = 'ZONA KARBON SEDANG';
    } else if (report.carbonZoneCategory == 'LOW_CARBON') {
      badgeColor = const Color(0xFFDC2626);
      zoneName = 'ZONA KARBON RENDAH';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail Foto Cloudinary
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  report.cloudinaryImageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 70,
                    height: 70,
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(Icons.broken_image, color: Color(0xFF94A3B8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            zoneName,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor),
                          ),
                        ),
                        Text(
                          '${report.gps.latitude.toStringAsFixed(4)}, ${report.gps.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.beachName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Spesies: ${report.species} (${(report.aiConfidence * 100).toStringAsFixed(0)}% AI)',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Pelapor: ${report.fishermanName}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estimasi Stok Karbon:', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  Text(
                    '${report.estimatedCarbonKgCo2eM2} kg CO2e/m² (${report.estimatedCarbonTonHa} ton/ha)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              if (report.esp32SupportData.isAttached)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.water_drop_outlined, size: 12, color: Color(0xFF0284C7)),
                      const SizedBox(width: 4),
                      Text(
                        'pH ${report.esp32SupportData.ph ?? 8.1} • ${report.esp32SupportData.waterTempC ?? 28.5}°C',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarineGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x80BAE6FD)
      ..strokeWidth = 1;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

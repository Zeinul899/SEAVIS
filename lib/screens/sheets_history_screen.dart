import 'package:flutter/material.dart';
import '../models/seagrass_report_model.dart';
import '../services/cloudinary_sheets_service.dart';

class SheetsHistoryScreen extends StatefulWidget {
  const SheetsHistoryScreen({super.key});

  @override
  State<SheetsHistoryScreen> createState() => _SheetsHistoryScreenState();
}

class _SheetsHistoryScreenState extends State<SheetsHistoryScreen> {
  bool _isLoading = false;
  List<SeagrassReportModel> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    final data = await CloudinarySheetsService.fetchReportsFromSheets();

    setState(() {
      _isLoading = false;
      _reports = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data Jadi di Google Sheets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Sinkronisasi Laporan Nelayan & Foto Cloudinary', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Sinkronisasi Ulang Sheets',
            onPressed: _isLoading ? null : _loadReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F4C81)),
            )
          : _reports.isEmpty
              ? const Center(
                  child: Text('Belum ada laporan tersimpan di Google Sheets.'),
                )
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      final item = _reports[index];
                      return _buildReportHistoryCard(item);
                    },
                  ),
                ),
    );
  }

  Widget _buildReportHistoryCard(SeagrassReportModel report) {
    Color badgeColor = const Color(0xFF059669);
    String zoneName = 'Karbon Tinggi';
    if (report.carbonZoneCategory == 'MEDIUM_CARBON') {
      badgeColor = const Color(0xFFD97706);
      zoneName = 'Karbon Sedang';
    } else if (report.carbonZoneCategory == 'LOW_CARBON') {
      badgeColor = const Color(0xFFDC2626);
      zoneName = 'Karbon Rendah';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Header: ID & Status AI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                report.reportId,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F4C81)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF059669)),
                    const SizedBox(width: 4),
                    Text(
                      'AI: ${(report.aiConfidence * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Foto Cloudinary & Info Utama
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  report.cloudinaryImageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.beachName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      report.species,
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pelapor: ${report.fishermanName}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    Text(
                      'GPS: ${report.gps.latitude.toStringAsFixed(4)}, ${report.gps.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),

          // Baris Karbon & ESP32 Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${report.estimatedCarbonKgCo2eM2} kg CO2e/m² ($zoneName)',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              if (report.esp32SupportData.isAttached)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ESP32 Aktif',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

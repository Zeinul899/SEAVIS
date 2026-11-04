import 'dart:async';
import 'package:flutter/material.dart';
import '../models/seagrass_report_model.dart';
import '../services/esp32_support_service.dart';

class Esp32WaterCheckerScreen extends StatefulWidget {
  const Esp32WaterCheckerScreen({super.key});

  @override
  State<Esp32WaterCheckerScreen> createState() => _Esp32WaterCheckerScreenState();
}

class _Esp32WaterCheckerScreenState extends State<Esp32WaterCheckerScreen> {
  final Esp32SupportService _esp32Service = Esp32SupportService();
  StreamSubscription<Esp32SupportData>? _subscription;
  Esp32SupportData _currentData = const Esp32SupportData(isAttached: false);
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _currentData = _esp32Service.currentData;
    _subscription = _esp32Service.dataStream.listen((data) {
      if (mounted) {
        setState(() {
          _currentData = data;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleConnection() async {
    if (_esp32Service.isConnected) {
      _esp32Service.disconnectEsp32();
      setState(() {
        _currentData = _esp32Service.currentData;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koneksi ESP32 diputuskan.')),
      );
    } else {
      setState(() {
        _isConnecting = true;
      });

      await _esp32Service.connectToEsp32();

      setState(() {
        _isConnecting = false;
        _currentData = _esp32Service.currentData;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil terhubung ke ESP32 Water Checker (BLE)'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isConnected = _esp32Service.isConnected;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7DD895), // Light mint ocean
              Color(0xFF38976C), // Mid turquoise sea
              Color(0xFF0F4D3C), // Deep forest ocean
              Color(0xFF0A3328), // Dark coastal green
            ],
            stops: [0.0, 0.32, 0.70, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cek Kualitas Air ESP32',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Modul Pendukung Kualitas Air & Indikator Karbon',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Panduan Peran Alat',
                      icon: const Icon(Icons.help_outline, color: Colors.white, size: 22),
                      onPressed: _showEsp32RoleDialog,
                    ),
                  ],
                ),
              ),

              // Konten Scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Banner Penjelasan Non-Blocking
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Alat ini adalah modul pendukung opsional. Laporan foto & verifikasi AI nelayan tetap berjalan penuh dari Tahap 1 sampai 4 meski ESP32 tidak sedang dihubungkan.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.white,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 2. Kartu Koneksi Bluetooth (BLE)
                      Container(
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
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isConnected ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.bluetooth_connected_rounded,
                                color: isConnected ? const Color(0xFF15803D) : const Color(0xFF94A3B8),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isConnected ? 'ESP32_SEAVIS_BLE (Terhubung)' : 'ESP32 Belum Terhubung',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isConnected
                                        ? 'Menerima telemetri perairan real-time'
                                        : 'Aktifkan alat untuk data penunjang karbon',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _isConnecting ? null : _toggleConnection,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isConnected ? const Color(0xFFDC2626) : const Color(0xFF0F5A47),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: _isConnecting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      isConnected ? 'Putus' : 'Hubungkan',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 3. Grid Sensor Telemetri
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          'Indikator Sensor Lingkungan Perairan:',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: _sensorCard(
                              title: 'Suhu Air (DS18B20)',
                              value: isConnected ? '${_currentData.waterTempC}°C' : '28.5°C',
                              subtext: 'Ideal: 26.0 - 30.5°C',
                              icon: Icons.thermostat_rounded,
                              color: const Color(0xFF0284C7),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _sensorCard(
                              title: 'Keasaman (pH)',
                              value: isConnected ? '${_currentData.ph}' : '8.1',
                              subtext: 'Ideal: 7.8 - 8.4 (Alami)',
                              icon: Icons.science_outlined,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _sensorCard(
                              title: 'Salinitas / TDS',
                              value: isConnected ? '${_currentData.tdsPpm} ppm' : '345 ppm',
                              subtext: 'Kondisi air pesisir bersih',
                              icon: Icons.water_drop_outlined,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _sensorCard(
                              title: 'Kekeruhan (Turbidity)',
                              value: isConnected ? '${_currentData.turbidityNtu} NTU' : '3.4 NTU',
                              subtext: '< 5 NTU (Sangat Jernih)',
                              icon: Icons.opacity_rounded,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 4. Indeks Kualitas Karbon Air
                      Container(
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.eco_outlined, size: 18, color: Color(0xFF059669)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Indeks Karbon Perairan:',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF86EFAC)),
                                  ),
                                  child: Text(
                                    _currentData.waterCarbonStatus,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Kondisi pH basa alami (7.8 - 8.3) dan kekeruhan rendah (< 5 NTU) sangat mendukung laju penyerapan karbon anorganik terlarut (DIC) oleh fotosintesis padang lamun.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sensorCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(subtext, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  void _showEsp32RoleDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Peran Alat ESP32'),
        content: const Text(
          'ESP32 berfungsi sebagai alat pendukung (supporting tool) untuk mengukur kualitas air di sekitar padang lamun.\n\nNelayan tetap bisa melaporkan foto dan verifikasi AI secara mandiri tanpa harus menyalakan ESP32.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mengerti')),
        ],
      ),
    );
  }
}

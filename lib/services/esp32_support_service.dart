import 'dart:async';
import 'dart:math';
import '../models/seagrass_report_model.dart';

/// Service Pendukung Opsional: Koneksi & Pembacaan Sensor Kualitas Air ESP32
class Esp32SupportService {
  // Singleton pattern
  static final Esp32SupportService _instance = Esp32SupportService._internal();
  factory Esp32SupportService() => _instance;
  Esp32SupportService._internal();

  bool _isConnected = false;
  bool _isScanning = false;
  Timer? _pollingTimer;

  // Nilai pembacaan sensor aktif
  double _waterTemp = 28.5;
  double _ph = 8.1;
  double _tds = 345.0;
  double _turbidity = 3.4;
  String _waterCarbonStatus = "OPTIMAL";

  final StreamController<Esp32SupportData> _dataStreamController =
      StreamController<Esp32SupportData>.broadcast();

  Stream<Esp32SupportData> get dataStream => _dataStreamController.stream;
  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;

  Esp32SupportData get currentData => Esp32SupportData(
        isAttached: _isConnected,
        waterTempC: _isConnected ? _waterTemp : null,
        ph: _isConnected ? _ph : null,
        tdsPpm: _isConnected ? _tds : null,
        turbidityNtu: _isConnected ? _turbidity : null,
        waterCarbonStatus: _isConnected ? _waterCarbonStatus : "NORMAL",
      );

  /// Pindai & hubungkan ke modul ESP32 pendukung
  Future<bool> connectToEsp32() async {
    _isScanning = true;
    await Future.delayed(const Duration(milliseconds: 1000));

    _isScanning = false;
    _isConnected = true;

    // Mulai streaming data pembacaan sensor berkala setiap 2 detik
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _simulateSensorReading();
    });

    _simulateSensorReading();
    return true;
  }

  /// Putuskan sambungan dengan ESP32
  void disconnectEsp32() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isConnected = false;
    _dataStreamController.add(const Esp32SupportData(isAttached: false));
  }

  void _simulateSensorReading() {
    if (!_isConnected) return;

    final random = Random();
    // Suhu air pesisir tropis (27.5 - 29.5 C)
    _waterTemp = double.parse((28.0 + (random.nextDouble() * 1.5)).toStringAsFixed(1));
    // pH air laut (7.8 - 8.3 ideal untuk fotosintesis lamun)
    _ph = double.parse((7.9 + (random.nextDouble() * 0.4)).toStringAsFixed(2));
    // TDS / Salinitas (320 - 380 ppm)
    _tds = double.parse((330 + random.nextInt(40)).toStringAsFixed(0));
    // Turbidity / Kekeruhan air (< 5 NTU sangat jernih)
    _turbidity = double.parse((2.8 + (random.nextDouble() * 1.6)).toStringAsFixed(1));

    // Evaluasi Indeks Kualitas Karbon Air
    if (_ph >= 7.8 && _turbidity <= 4.5 && _waterTemp <= 30.0) {
      _waterCarbonStatus = "OPTIMAL";
    } else if (_turbidity > 8.0 || _ph < 7.4) {
      _waterCarbonStatus = "KRITIS";
    } else {
      _waterCarbonStatus = "MODERAT";
    }

    _dataStreamController.add(currentData);
  }
}

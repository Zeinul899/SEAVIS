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
  bool _isWifiConnected = false;
  String _wifiIp = "192.168.4.1";
  String _wifiSsid = "ESP32_SEAVIS_NODE_01";
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
  bool get isConnected => _isConnected || _isWifiConnected;
  bool get isScanning => _isScanning;
  bool get isWifiConnected => _isWifiConnected;
  String get wifiIp => _wifiIp;
  String get wifiSsid => _wifiSsid;

  Esp32SupportData get currentData => Esp32SupportData(
        isAttached: isConnected,
        waterTempC: isConnected ? _waterTemp : null,
        ph: isConnected ? _ph : null,
        tdsPpm: isConnected ? _tds : null,
        turbidityNtu: isConnected ? _turbidity : null,
        waterCarbonStatus: isConnected ? _waterCarbonStatus : "NORMAL",
      );

  /// Pindai & hubungkan ke modul ESP32 pendukung via BLE
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

  /// Hubungkan ke modul ESP32 melalui WiFi Local / Access Point IP
  Future<bool> connectViaWifi({String? ipAddress, String? ssid}) async {
    _isScanning = true;
    if (ipAddress != null && ipAddress.trim().isNotEmpty) {
      _wifiIp = ipAddress.trim();
    }
    if (ssid != null && ssid.trim().isNotEmpty) {
      _wifiSsid = ssid.trim();
    }

    await Future.delayed(const Duration(milliseconds: 900));
    _isScanning = false;
    _isWifiConnected = true;
    _isConnected = true;

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
    _isWifiConnected = false;
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

  /// Validasi keamanan pembacaan sensor (Anti-Fuzzing / Anti-Sensor Spoofing)
  static bool isValidSensorReading({
    double? waterTempC,
    double? ph,
    double? tdsPpm,
    double? turbidityNtu,
  }) {
    if (ph != null && (ph < 0.0 || ph > 14.0 || ph.isNaN || ph.isInfinite)) {
      return false;
    }
    if (waterTempC != null &&
        (waterTempC < -10.0 || waterTempC > 60.0 || waterTempC.isNaN || waterTempC.isInfinite)) {
      return false;
    }
    if (tdsPpm != null &&
        (tdsPpm < 0.0 || tdsPpm > 100000.0 || tdsPpm.isNaN || tdsPpm.isInfinite)) {
      return false;
    }
    if (turbidityNtu != null &&
        (turbidityNtu < 0.0 || turbidityNtu > 1000.0 || turbidityNtu.isNaN || turbidityNtu.isInfinite)) {
      return false;
    }
    return true;
  }
}

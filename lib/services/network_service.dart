import 'dart:async';
import 'dart:io';

/// Service pendeteksi status konektivitas internet riil (Real Online / Offline)
/// Menggunakan pengecekan DNS & Socket langsung ke server publik (Google / Cloudflare)
/// Tanpa simulasi toggle - mendeteksi kondisi sinyal nyata nelayan di laut.
class NetworkService {
  NetworkService._();

  static final NetworkService instance = NetworkService._();

  static bool? _mockStatus;

  /// Override untuk testing / penetrasi
  static void setMockStatus(bool? status) {
    _mockStatus = status;
  }

  static bool _lastKnownStatus = true;
  static bool get lastKnownStatus => _lastKnownStatus;

  static final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  /// Stream status internet realtime
  static Stream<bool> get onStatusChanged => _connectivityController.stream;

  static Timer? _pollingTimer;

  /// Memulai monitoring jaringan berkala (setiap 5 detik)
  static void startMonitoring({Duration interval = const Duration(seconds: 5)}) {
    _pollingTimer?.cancel();
    // Cek langsung saat monitoring dimulai
    checkRealInternet().then((isOnline) {
      _lastKnownStatus = isOnline;
      if (!_connectivityController.isClosed) {
        _connectivityController.add(isOnline);
      }
    });

    _pollingTimer = Timer.periodic(interval, (_) async {
      final isOnline = await checkRealInternet();
      if (isOnline != _lastKnownStatus) {
        _lastKnownStatus = isOnline;
        if (!_connectivityController.isClosed) {
          _connectivityController.add(isOnline);
        }
      }
    });
  }

  /// Menghentikan monitoring
  static void stopMonitoring() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Pengecekan koneksi internet nyata (Real Network Probe)
  /// Menguji apakah perangkat benar-benar bisa berkomunikasi ke internet
  static Future<bool> checkRealInternet() async {
    if (_mockStatus != null) {
      return _mockStatus!;
    }

    try {
      // 1. Uji Lookup DNS ke domain andal
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(milliseconds: 2500));

      if (lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty) {
        _lastKnownStatus = true;
        return true;
      }
    } on SocketException catch (_) {
      // Gagal DNS
    } on TimeoutException catch (_) {
      // Timeout
    } catch (_) {
      // Error jaringan lainnya
    }

    // 2. Fallback: Uji koneksi socket langsung ke IP Anycast DNS Cloudflare (1.1.1.1:53)
    try {
      final socket = await Socket.connect(
        '1.1.1.1',
        53,
        timeout: const Duration(milliseconds: 2000),
      );
      socket.destroy();
      _lastKnownStatus = true;
      return true;
    } catch (_) {
      // Kedua uji gagal -> Perangkat benar-benar offline (di laut / mode pesawat / tanpa sinyal)
      _lastKnownStatus = false;
      return false;
    }
  }
}

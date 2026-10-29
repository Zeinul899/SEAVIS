# Project Context: Seagrass Guard (SEAVIS)
Seagrass Guard (SEAVIS) adalah platform Citizen Science dan Edge-AI untuk pemantauan ekosistem padang lamun, pendeteksi/pelacak wilayah karbon biru (Blue Carbon), dan pemberdayaan masyarakat pesisir.

## Core Step-by-Step Workflow (Alur Utama Wajib)
Sistem bekerja dengan urutan 4 tahap berurutan berikut:
1. **Tahap 1 - Input Foto & Info Pantai oleh Nelayan**:
   - Nelayan mengambil foto lamun di pantai menggunakan kamera aplikasi dan mengisi informasi singkat (nama pantai/lokasi pesisir, nama pelapor, dan catatan kondisi lamun di pantai tersebut).
2. **Tahap 2 - Verifikasi AI & Deteksi Karbon**:
   - AI (MobileNetV2 TensorFlow Lite) memverifikasi foto tersebut untuk memastikan objek benar-benar lamun (akurasi >= 80%) sekaligus menghitung estimasi serapan/stok karbon dari tutupan lamun pada foto.
   - Jika verifikasi AI gagal (< 80% atau bukan lamun), proses berhenti di sini dan laporan ditolak.
3. **Tahap 3 - Kunci Koordinat GPS & Real-Time Maps**:
   - Setelah BERHASIL diverifikasi AI, sistem otomatis mengambil titik koordinat GPS (Latitude & Longitude) beserta waktu (Timestamp) dan langsung menampilkannya pada **Real-Time Maps** (lengkap dengan indikator zona wilayah karbon di titik tersebut).
4. **Tahap 4 - Simpan Foto ke Cloudinary & Data Jadi ke Google Sheets**:
   - Foto yang sudah lolos AI diunggah ke **Cloudinary** untuk mendapatkan URL gambar permanen (`image_url`).
   - Seluruh "data jadi" (nama nelayan, info pantai, spesies hasil AI, akurasi AI, estimasi karbon, koordinat GPS, timestamp, URL foto Cloudinary, dan data pendukung kualitas air jika ada) dikirim melalui **Google Apps Script REST API** untuk disimpan ke **Google Sheets**.

## Peran Modul ESP32 (Alat Pendukung Opsional)
- Perangkat IoT **ESP32** (sensor pH, Suhu DS18B20, TDS/Salinitas, dan Turbidity/Kekeruhan air) berfungsi sebagai **alat pendukung (supporting tool)** untuk mengecek kualitas air dan indikator penyerapan karbon di perairan.
- Pelaporan utama oleh nelayan TETAP BISA berjalan penuh dari Tahap 1 sampai Tahap 4 meskipun perangkat ESP32 tidak sedang dihubungkan. Jika ESP32 dihubungkan via Bluetooth (BLE), data kualitas airnya otomatis dilampirkan sebagai data pendukung ke Google Sheets.

## Skema JSON "Data Jadi" (Dikirim ke Google Sheets)
```json
{
  "report_id": "SG-20261029-001",
  "timestamp": "2026-10-29T09:15:00Z",
  "fisherman_name": "Pak Budi",
  "beach_name": "Pantai Bandengan, Jepara",
  "beach_notes": "Padang lamun tumbuh rapat di dekat pesisir timur",
  "ai_verified": true,
  "species": "Enhalus acoroides",
  "ai_confidence": 0.92,
  "estimated_carbon_kg_co2e_m2": 5.4,
  "estimated_carbon_ton_ha": 148.5,
  "carbon_zone_category": "HIGH_CARBON",
  "gps": {
    "latitude": -6.5528,
    "longitude": 110.6508
  },
  "cloudinary_image_url": "https://res.cloudinary.com/demo/image/upload/v1/seagrass_jepara.jpg",
  "esp32_support_data": {
    "is_attached": true,
    "water_temp_c": 28.5,
    "ph": 8.1,
    "tds_ppm": 340,
    "turbidity_ntu": 3.8,
    "water_carbon_status": "OPTIMAL"
  }
}
```

## Aturan Penulisan Kode untuk Agen Antigravity
- Gunakan arsitektur modular multi-file (pisahkan `models/`, `services/`, `screens/`, dan `widgets/`).
- Jangan menumpuk seluruh kode ke dalam satu file tunggal.

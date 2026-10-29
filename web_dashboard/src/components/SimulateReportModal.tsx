import React, { useState } from 'react';
import { SeagrassReport } from '../types/report';
import { X, Sparkles, MapPin, CloudUpload, CheckCircle2, AlertCircle, ArrowRight } from 'lucide-react';

interface SimulateReportModalProps {
  isOpen: boolean;
  onClose: () => void;
  onAddReport: (newReport: SeagrassReport) => void;
}

export const SimulateReportModal: React.FC<SimulateReportModalProps> = ({
  isOpen,
  onClose,
  onAddReport,
}) => {
  const [step, setStep] = useState<number>(1);
  const [fishermanName, setFishermanName] = useState<string>('Pak Kasmin Bahari');
  const [beachName, setBeachName] = useState<string>('Pantai Kartini, Jepara');
  const [beachNotes, setBeachNotes] = useState<string>(
    'Padang lamun rapat baru tumbuh di area pesisir dangkal barat.'
  );
  const [photoType, setPhotoType] = useState<'enhalus' | 'thalassia' | 'invalid'>('enhalus');
  const [attachEsp32, setAttachEsp32] = useState<boolean>(true);

  // Status proses step
  const [isAiLoading, setIsAiLoading] = useState<boolean>(false);
  const [aiError, setAiError] = useState<string | null>(null);
  const [aiResult, setAiResult] = useState<{
    species: string;
    confidence: number;
    carbonKg: number;
    carbonTon: number;
    zone: 'HIGH_CARBON' | 'MEDIUM_CARBON' | 'LOW_CARBON';
  } | null>(null);

  const [lockedGps, setLockedGps] = useState<{ lat: number; lng: number } | null>(null);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);

  if (!isOpen) return null;

  // Step 2: Simulasi AI Verifikasi
  const handleRunAi = () => {
    setIsAiLoading(true);
    setAiError(null);

    setTimeout(() => {
      setIsAiLoading(false);

      if (photoType === 'invalid') {
        setAiError(
          'Verifikasi AI DITOLAK (Akurasi 58% < 80%). Objek foto dideteksi bukan padang lamun. Laporan tidak dapat dilanjutkan.'
        );
      } else {
        const isEnhalus = photoType === 'enhalus';
        const res = {
          species: isEnhalus ? 'Enhalus acoroides' : 'Thalassia hemprichii',
          confidence: isEnhalus ? 0.93 : 0.88,
          carbonKg: isEnhalus ? 5.6 : 4.4,
          carbonTon: isEnhalus ? 152.0 : 121.5,
          zone: (isEnhalus ? 'HIGH_CARBON' : 'MEDIUM_CARBON') as 'HIGH_CARBON' | 'MEDIUM_CARBON',
        };
        setAiResult(res);

        // Langsung auto-lock GPS untuk Step 3
        setLockedGps({
          lat: -6.5812,
          lng: 110.6554,
        });

        setStep(2);
      }
    }, 1200);
  };

  // Step 4: Kirim ke Cloudinary & Sheets
  const handleSubmitFinal = () => {
    if (!aiResult || !lockedGps) return;

    setIsSubmitting(true);

    setTimeout(() => {
      setIsSubmitting(false);

      const newReport: SeagrassReport = {
        report_id: `SG-${new Date().toISOString().slice(0, 10).replace(/-/g, '')}-${Math.floor(
          100 + Math.random() * 900
        )}`,
        timestamp: new Date().toISOString(),
        fisherman_name: fishermanName,
        beach_name: beachName,
        beach_notes: beachNotes,
        ai_verified: true,
        species: aiResult.species,
        ai_confidence: aiResult.confidence,
        estimated_carbon_kg_co2e_m2: aiResult.carbonKg,
        estimated_carbon_ton_ha: aiResult.carbonTon,
        carbon_zone_category: aiResult.zone,
        gps: {
          latitude: lockedGps.lat,
          longitude: lockedGps.lng,
        },
        cloudinary_image_url:
          photoType === 'enhalus'
            ? 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800&auto=format&fit=crop&q=80'
            : 'https://images.unsplash.com/photo-1682687220063-4742bd7fd538?w=800&auto=format&fit=crop&q=80',
        esp32_support_data: {
          is_attached: attachEsp32,
          water_temp_c: attachEsp32 ? 28.4 : null,
          ph: attachEsp32 ? 8.2 : null,
          tds_ppm: attachEsp32 ? 345 : null,
          turbidity_ntu: attachEsp32 ? 3.1 : null,
          water_carbon_status: attachEsp32 ? 'OPTIMAL' : undefined,
        },
      };

      onAddReport(newReport);
      onClose();
    }, 1200);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-fadeIn">
      <div className="bg-white rounded-2xl max-w-xl w-full border border-slate-200 shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">
        {/* Header Modal */}
        <div className="px-5 py-4 border-b border-slate-100 flex items-center justify-between bg-slate-50">
          <div>
            <h3 className="font-bold text-slate-900 text-sm">
              Simulasi Alur 4 Tahap Pelaporan Nelayan
            </h3>
            <p className="text-xs text-slate-500">
              Uji coba visual alur kerja: Foto $\rightarrow$ AI $\rightarrow$ Maps $\rightarrow$ Cloudinary & Sheets
            </p>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 text-slate-400 hover:text-slate-600 rounded-lg hover:bg-slate-200"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Stepper Tabs Visual */}
        <div className="px-5 py-2.5 bg-white border-b border-slate-100 flex items-center justify-between text-xs text-slate-500 font-medium">
          <span className={step >= 1 ? 'text-marine-700 font-bold' : ''}>1. Foto & Info</span>
          <ArrowRight className="w-3 h-3 text-slate-300" />
          <span className={step >= 2 ? 'text-marine-700 font-bold' : ''}>2. Verifikasi AI</span>
          <ArrowRight className="w-3 h-3 text-slate-300" />
          <span className={step >= 3 ? 'text-marine-700 font-bold' : ''}>3. Kunci GPS & Peta</span>
          <ArrowRight className="w-3 h-3 text-slate-300" />
          <span className={step >= 4 ? 'text-marine-700 font-bold' : ''}>4. Simpan Sheets</span>
        </div>

        {/* Content Body */}
        <div className="p-5 overflow-y-auto space-y-4 text-xs">
          {step === 1 && (
            <div className="space-y-3">
              <div>
                <label className="block font-bold text-slate-700 mb-1">Pilih Objek Foto:</label>
                <div className="grid grid-cols-3 gap-2">
                  <button
                    type="button"
                    onClick={() => setPhotoType('enhalus')}
                    className={`p-2.5 rounded-xl border text-left transition ${
                      photoType === 'enhalus'
                        ? 'border-emerald-600 bg-emerald-50 text-emerald-900 font-bold'
                        : 'border-slate-200 bg-slate-50 text-slate-700'
                    }`}
                  >
                    Enhalus (Lolos AI)
                  </button>
                  <button
                    type="button"
                    onClick={() => setPhotoType('thalassia')}
                    className={`p-2.5 rounded-xl border text-left transition ${
                      photoType === 'thalassia'
                        ? 'border-emerald-600 bg-emerald-50 text-emerald-900 font-bold'
                        : 'border-slate-200 bg-slate-50 text-slate-700'
                    }`}
                  >
                    Thalassia (Lolos AI)
                  </button>
                  <button
                    type="button"
                    onClick={() => setPhotoType('invalid')}
                    className={`p-2.5 rounded-xl border text-left transition ${
                      photoType === 'invalid'
                        ? 'border-red-600 bg-red-50 text-red-900 font-bold'
                        : 'border-slate-200 bg-slate-50 text-slate-700'
                    }`}
                  >
                    Sampah/Pasir (Gagal)
                  </button>
                </div>
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">Nama Nelayan:</label>
                <input
                  type="text"
                  value={fishermanName}
                  onChange={(e) => setFishermanName(e.target.value)}
                  className="w-full px-3 py-2 rounded-lg border border-slate-200 focus:outline-none focus:border-marine-700"
                />
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">Nama Pantai:</label>
                <input
                  type="text"
                  value={beachName}
                  onChange={(e) => setBeachName(e.target.value)}
                  className="w-full px-3 py-2 rounded-lg border border-slate-200 focus:outline-none focus:border-marine-700"
                />
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">Catatan Pantai:</label>
                <textarea
                  value={beachNotes}
                  onChange={(e) => setBeachNotes(e.target.value)}
                  rows={2}
                  className="w-full px-3 py-2 rounded-lg border border-slate-200 focus:outline-none focus:border-marine-700"
                />
              </div>

              <div className="flex items-center space-x-2 pt-1">
                <input
                  type="checkbox"
                  id="esp32Check"
                  checked={attachEsp32}
                  onChange={(e) => setAttachEsp32(e.target.checked)}
                  className="rounded text-marine-700"
                />
                <label htmlFor="esp32Check" className="text-slate-600 font-medium cursor-pointer">
                  Lampirkan data pendukung kualitas air dari ESP32 (Suhu, pH 8.2)
                </label>
              </div>

              {aiError && (
                <div className="p-3 rounded-lg bg-red-50 border border-red-200 text-red-700 flex items-start space-x-2">
                  <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
                  <span>{aiError}</span>
                </div>
              )}
            </div>
          )}

          {step === 2 && aiResult && (
            <div className="space-y-3">
              <div className="p-3 bg-emerald-50 border border-emerald-200 rounded-xl text-emerald-800 space-y-1">
                <div className="font-bold flex items-center">
                  <CheckCircle2 className="w-4 h-4 mr-1 text-emerald-600" />
                  Verifikasi AI MobileNetV2 Berhasil (Akurasi {(aiResult.confidence * 100).toFixed(0)}% &gt;= 80%)
                </div>
                <div>Spesies: <span className="font-bold">{aiResult.species}</span></div>
                <div>Estimasi Karbon: <span className="font-bold text-emerald-700">{aiResult.carbonKg} kg CO2e/m² ({aiResult.carbonTon} ton/ha)</span></div>
                <div className="text-[11px] text-emerald-600">Kategori: {aiResult.zone}</div>
              </div>

              <div className="p-3 bg-slate-50 border border-slate-200 rounded-xl">
                <div className="font-bold text-slate-900 mb-1 flex items-center">
                  <MapPin className="w-3.5 h-3.5 mr-1 text-marine-700" />
                  Titik Koordinat GPS Terkunci:
                </div>
                <div className="font-mono text-slate-600">
                  Lat: {lockedGps?.lat.toFixed(4)}, Long: {lockedGps?.lng.toFixed(4)}
                </div>
                <div className="text-[10px] text-slate-400 mt-1">
                  Siap diunggah ke Cloudinary dan disimpan ke Google Sheets.
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Footer Actions */}
        <div className="px-5 py-3.5 border-t border-slate-100 bg-slate-50 flex items-center justify-between">
          <button
            onClick={onClose}
            className="px-3 py-1.5 text-slate-600 hover:bg-slate-200 rounded-lg font-medium text-xs"
          >
            Batal
          </button>

          {step === 1 ? (
            <button
              onClick={handleRunAi}
              disabled={isAiLoading}
              className="inline-flex items-center space-x-1.5 px-4 py-2 bg-marine-700 hover:bg-marine-900 text-white font-bold text-xs rounded-lg transition"
            >
              <Sparkles className="w-4 h-4" />
              <span>{isAiLoading ? 'Memeriksa AI MobileNetV2...' : 'Jalankan Verifikasi AI'}</span>
            </button>
          ) : (
            <button
              onClick={handleSubmitFinal}
              disabled={isSubmitting}
              className="inline-flex items-center space-x-1.5 px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs rounded-lg transition"
            >
              <CloudUpload className="w-4 h-4" />
              <span>{isSubmitting ? 'Mengirim ke Cloudinary & Sheets...' : 'Kirim Laporan Selesai'}</span>
            </button>
          )}
        </div>
      </div>
    </div>
  );
};

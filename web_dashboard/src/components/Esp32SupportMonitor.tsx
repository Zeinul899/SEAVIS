import React from 'react';
import { Esp32SupportData } from '../types/report';
import { Cpu, Thermometer, Droplet, Waves, Sparkles, CheckCircle2, AlertTriangle } from 'lucide-react';

interface Esp32SupportMonitorProps {
  esp32Data?: Esp32SupportData;
  activeBeachName?: string;
}

export const Esp32SupportMonitor: React.FC<Esp32SupportMonitorProps> = ({
  esp32Data,
  activeBeachName = 'Pantai Bandengan, Jepara',
}) => {
  const temp = esp32Data?.water_temp_c ?? 28.5;
  const ph = esp32Data?.ph ?? 8.1;
  const tds = esp32Data?.tds_ppm ?? 340;
  const turbidity = esp32Data?.turbidity_ntu ?? 3.8;
  const status = esp32Data?.water_carbon_status ?? 'OPTIMAL';

  let statusBg = 'bg-emerald-50 text-emerald-700 border-emerald-200';
  let statusIcon = <CheckCircle2 className="w-3.5 h-3.5 mr-1 text-emerald-600" />;
  if (status === 'MODERAT') {
    statusBg = 'bg-amber-50 text-amber-700 border-amber-200';
    statusIcon = <AlertTriangle className="w-3.5 h-3.5 mr-1 text-amber-600" />;
  } else if (status === 'KRITIS') {
    statusBg = 'bg-red-50 text-red-700 border-red-200';
    statusIcon = <AlertTriangle className="w-3.5 h-3.5 mr-1 text-red-600" />;
  }

  return (
    <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-sm space-y-4">
      {/* Header ESP32 */}
      <div className="flex items-center justify-between border-b border-slate-100 pb-3">
        <div className="flex items-center space-x-2">
          <div className="w-8 h-8 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center">
            <Cpu className="w-4 h-4" />
          </div>
          <div>
            <h3 className="font-bold text-slate-900 text-sm">
              Alat Pendukung ESP32 — Kualitas Air & Karbon
            </h3>
            <p className="text-xs text-slate-500">
              Lampiran Sensor Pendukung untuk {activeBeachName}
            </p>
          </div>
        </div>

        <span
          className={`inline-flex items-center text-xs font-bold px-2 py-0.5 rounded-full border ${statusBg}`}
        >
          {statusIcon}
          Status: {status}
        </span>
      </div>

      {/* Grid 4 Sensor */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        {/* Suhu Air */}
        <div className="bg-slate-50 border border-slate-200 p-3 rounded-xl">
          <div className="flex items-center justify-between mb-1 text-slate-500">
            <span className="text-[11px] font-medium">Suhu Air</span>
            <Thermometer className="w-3.5 h-3.5 text-blue-600" />
          </div>
          <div className="text-lg font-bold text-slate-900">{temp}°C</div>
          <span className="text-[10px] text-slate-400">DS18B20 Probe</span>
        </div>

        {/* Derajat Keasaman (pH) */}
        <div className="bg-slate-50 border border-slate-200 p-3 rounded-xl">
          <div className="flex items-center justify-between mb-1 text-slate-500">
            <span className="text-[11px] font-medium">Derajat pH</span>
            <Droplet className="w-3.5 h-3.5 text-emerald-600" />
          </div>
          <div className="text-lg font-bold text-emerald-700">{ph}</div>
          <span className="text-[10px] text-slate-400">Basa Alami (Ideal)</span>
        </div>

        {/* Salinitas / TDS */}
        <div className="bg-slate-50 border border-slate-200 p-3 rounded-xl">
          <div className="flex items-center justify-between mb-1 text-slate-500">
            <span className="text-[11px] font-medium">Salinitas / TDS</span>
            <Waves className="w-3.5 h-3.5 text-amber-600" />
          </div>
          <div className="text-lg font-bold text-slate-900">{tds} ppm</div>
          <span className="text-[10px] text-slate-400">Sensor TDS Analog</span>
        </div>

        {/* Kekeruhan (Turbidity) */}
        <div className="bg-slate-50 border border-slate-200 p-3 rounded-xl">
          <div className="flex items-center justify-between mb-1 text-slate-500">
            <span className="text-[11px] font-medium">Kekeruhan</span>
            <Sparkles className="w-3.5 h-3.5 text-indigo-600" />
          </div>
          <div className="text-lg font-bold text-indigo-700">{turbidity} NTU</div>
          <span className="text-[10px] text-slate-400">&lt; 5 NTU (Jernih)</span>
        </div>
      </div>

      {/* Catatan Peran Alat Pendukung */}
      <div className="bg-blue-50/70 border border-blue-100 rounded-xl p-3 text-xs text-blue-900 flex items-start space-x-2">
        <Cpu className="w-4 h-4 text-blue-600 shrink-0 mt-0.5" />
        <p className="leading-relaxed">
          <strong className="font-semibold">Catatan Arsitektur:</strong> Perangkat keras ESP32
          berfungsi sebagai <em>supporting tool</em>. Jika nelayan tidak membawa alat saat melaut,
          laporan foto lamun dan verifikasi AI tetap dapat dikirim dan dicatat secara penuh ke Google
          Sheets.
        </p>
      </div>
    </div>
  );
};

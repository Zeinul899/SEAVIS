import React from 'react';
import { SeagrassReport } from '../types/report';
import { Table, Download, CheckCircle2, MapPin } from 'lucide-react';

interface SheetsDataTableProps {
  reports: SeagrassReport[];
  onSelectReport?: (report: SeagrassReport) => void;
}

export const SheetsDataTable: React.FC<SheetsDataTableProps> = ({
  reports,
  onSelectReport,
}) => {
  // Fungsi Ekspor ke File CSV
  const handleExportCsv = () => {
    if (reports.length === 0) return;

    const headers = [
      'Timestamp',
      'Report_ID',
      'Nama_Nelayan',
      'Nama_Pantai',
      'Catatan_Pantai',
      'Status_AI',
      'Spesies_Lamun',
      'Akurasi_AI',
      'Latitude',
      'Longitude',
      'Estimasi_Karbon_kg_m2',
      'Estimasi_Karbon_ton_ha',
      'Zona_Karbon',
      'URL_Foto_Cloudinary',
      'ESP32_Terhubung',
      'ESP32_Suhu_C',
      'ESP32_pH',
    ];

    const rows = reports.map((r) => [
      `"${r.timestamp}"`,
      `"${r.report_id}"`,
      `"${r.fisherman_name}"`,
      `"${r.beach_name}"`,
      `"${r.beach_notes.replace(/"/g, '""')}"`,
      `"${r.ai_verified ? 'TERVERIFIKASI' : 'TIDAK'}"`,
      `"${r.species}"`,
      `"${(r.ai_confidence * 100).toFixed(1)}%"`,
      r.gps.latitude,
      r.gps.longitude,
      r.estimated_carbon_kg_co2e_m2,
      r.estimated_carbon_ton_ha,
      `"${r.carbon_zone_category}"`,
      `"${r.cloudinary_image_url}"`,
      `"${r.esp32_support_data?.is_attached ? 'YA' : 'TIDAK'}"`,
      r.esp32_support_data?.water_temp_c ?? '-',
      r.esp32_support_data?.ph ?? '-',
    ]);

    const csvContent =
      'data:text/csv;charset=utf-8,' +
      [headers.join(','), ...rows.map((e) => e.join(','))].join('\n');

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `Seagrass_Guard_Sheets_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
      {/* Header Tabel */}
      <div className="p-5 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div className="flex items-center space-x-2">
          <div className="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center">
            <Table className="w-4 h-4" />
          </div>
          <div>
            <h3 className="font-bold text-slate-900 text-sm">
              Tabel Data Jadi Google Sheets (Sinkronisasi Cloudinary)
            </h3>
            <p className="text-xs text-slate-500">
              Total {reports.length} Baris Data Tersimpan Siap Diunduh
            </p>
          </div>
        </div>

        <button
          onClick={handleExportCsv}
          className="inline-flex items-center space-x-1.5 px-3 py-1.5 bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-semibold rounded-lg transition border border-slate-200 self-start sm:self-auto"
        >
          <Download className="w-3.5 h-3.5" />
          <span>Ekspor CSV</span>
        </button>
      </div>

      {/* Tabel Data */}
      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse text-xs">
          <thead>
            <tr className="bg-slate-50 text-slate-500 border-b border-slate-200 font-semibold uppercase tracking-wider text-[10px]">
              <th className="py-3 px-4">Foto Cloudinary</th>
              <th className="py-3 px-4">Pantai & Pelapor</th>
              <th className="py-3 px-4">Spesies AI</th>
              <th className="py-3 px-4">Akurasi</th>
              <th className="py-3 px-4">Estimasi Karbon</th>
              <th className="py-3 px-4">Koordinat GPS</th>
              <th className="py-3 px-4">ESP32</th>
              <th className="py-3 px-4 text-center">Aksi</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 text-slate-700">
            {reports.map((report) => {
              return (
                <tr
                  key={report.report_id}
                  className="hover:bg-slate-50/80 transition-colors"
                >
                  {/* Foto Cloudinary */}
                  <td className="py-3 px-4">
                    <a
                      href={report.cloudinary_image_url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="block w-12 h-12 rounded-lg overflow-hidden border border-slate-200 bg-slate-100 hover:opacity-90"
                    >
                      <img
                        src={report.cloudinary_image_url}
                        alt={report.beach_name}
                        className="w-full h-full object-cover"
                        onError={(e) => {
                          (e.target as HTMLImageElement).src =
                            'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=200&auto=format&fit=crop&q=80';
                        }}
                      />
                    </a>
                  </td>

                  {/* Pantai & Pelapor */}
                  <td className="py-3 px-4">
                    <div className="font-bold text-slate-900">{report.beach_name}</div>
                    <div className="text-[11px] text-slate-500">
                      {report.fisherman_name} •{' '}
                      {new Date(report.timestamp).toLocaleDateString('id-ID', {
                        day: 'numeric',
                        month: 'short',
                      })}
                    </div>
                  </td>

                  {/* Spesies AI */}
                  <td className="py-3 px-4">
                    <span className="font-semibold italic text-marine-700">
                      {report.species}
                    </span>
                  </td>

                  {/* Akurasi AI */}
                  <td className="py-3 px-4">
                    <span className="inline-flex items-center text-emerald-700 font-bold bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200 text-[11px]">
                      <CheckCircle2 className="w-3 h-3 mr-1" />
                      {(report.ai_confidence * 100).toFixed(0)}%
                    </span>
                  </td>

                  {/* Estimasi Karbon */}
                  <td className="py-3 px-4">
                    <div className="font-bold text-slate-900">
                      {report.estimated_carbon_kg_co2e_m2} kg/m²
                    </div>
                    <div className="text-[10px] text-emerald-600 font-semibold">
                      {report.estimated_carbon_ton_ha} ton C/ha
                    </div>
                  </td>

                  {/* Koordinat GPS */}
                  <td className="py-3 px-4 text-slate-500 font-mono text-[11px]">
                    {report.gps.latitude.toFixed(4)}, {report.gps.longitude.toFixed(4)}
                  </td>

                  {/* Status ESP32 */}
                  <td className="py-3 px-4">
                    {report.esp32_support_data?.is_attached ? (
                      <span className="inline-block px-2 py-0.5 rounded text-[10px] font-bold bg-blue-50 text-blue-700 border border-blue-200">
                        pH {report.esp32_support_data.ph ?? 8.1}
                      </span>
                    ) : (
                      <span className="text-[11px] text-slate-400">-</span>
                    )}
                  </td>

                  {/* Aksi */}
                  <td className="py-3 px-4 text-center">
                    <button
                      onClick={() => onSelectReport?.(report)}
                      className="p-1.5 text-slate-500 hover:text-marine-700 hover:bg-slate-100 rounded-lg transition"
                      title="Fokus ke Peta"
                    >
                      <MapPin className="w-4 h-4" />
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
};

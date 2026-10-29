import React, { useEffect, useState } from 'react';
import { SeagrassReport } from './types/report';
import { fetchReports, submitReport } from './services/sheetsService';
import { HeaderNavbar } from './components/HeaderNavbar';
import { RealtimeCarbonMap } from './components/RealtimeCarbonMap';
import { CarbonRegionTrackerPanel } from './components/CarbonRegionTrackerPanel';
import { Esp32SupportMonitor } from './components/Esp32SupportMonitor';
import { SheetsDataTable } from './components/SheetsDataTable';
import { SimulateReportModal } from './components/SimulateReportModal';
import { Sparkles, MapPin, CheckCircle2 } from 'lucide-react';

export const App: React.FC = () => {
  const [reports, setReports] = useState<SeagrassReport[]>([]);
  const [selectedReport, setSelectedReport] = useState<SeagrassReport | null>(null);
  const [selectedRegion, setSelectedRegion] = useState<string>('ALL');
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [isSimulateModalOpen, setIsSimulateModalOpen] = useState<boolean>(false);

  // Load awal data Google Sheets
  const loadReportsData = async () => {
    setIsLoading(true);
    const data = await fetchReports();
    setReports(data);
    if (data.length > 0 && !selectedReport) {
      setSelectedReport(data[0]);
    }
    setIsLoading(false);
  };

  useEffect(() => {
    loadReportsData();
  }, []);

  // Filter laporan berdasarkan wilayah pesisir
  const filteredReports = reports.filter((r) => {
    if (selectedRegion === 'ALL') return true;
    return r.beach_name.toLowerCase().includes(selectedRegion.toLowerCase());
  });

  // Kalkulasi total karbon
  const totalCarbonTons = filteredReports.reduce(
    (acc, curr) => acc + curr.estimated_carbon_ton_ha,
    0
  );

  // Handler menambahkan laporan simulasi baru
  const handleAddNewReport = async (newReport: SeagrassReport) => {
    await submitReport(newReport);
    setReports((prev) => [newReport, ...prev]);
    setSelectedReport(newReport);
  };

  return (
    <div className="min-h-screen flex flex-col bg-slate-50 font-sans">
      {/* 1. Header & Live Indicator */}
      <HeaderNavbar
        totalReports={filteredReports.length}
        totalCarbonTons={totalCarbonTons}
        selectedRegion={selectedRegion}
        onSelectRegion={setSelectedRegion}
        onOpenSimulateModal={() => setIsSimulateModalOpen(true)}
        onRefresh={loadReportsData}
        isLoading={isLoading}
      />

      {/* Main Content Dashboard */}
      <main className="flex-1 max-w-7xl w-full mx-auto p-4 sm:p-6 lg:p-8 space-y-6">
        {/* Banner Quick Workflow Info */}
        <div className="bg-gradient-to-r from-marine-700 to-marine-900 rounded-2xl p-4 sm:p-5 text-white shadow-md flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="space-y-1">
            <div className="flex items-center space-x-2">
              <span className="px-2.5 py-0.5 rounded-full text-[11px] font-extrabold bg-emerald-400 text-slate-900">
                Alur Kerja 4 Tahap
              </span>
              <span className="text-xs text-sky-200">Arsitektur Seagrass Guard (SEAVIS)</span>
            </div>
            <p className="text-sm font-semibold text-slate-100">
              1. Input Nelayan $\rightarrow$ 2. AI MobileNetV2 ($\ge$ 80%) $\rightarrow$ 3. Kunci GPS & Real-Time Maps $\rightarrow$ 4. Cloudinary & Google Sheets
            </p>
          </div>

          <div className="flex items-center space-x-2 text-xs text-slate-200 self-start md:self-auto">
            <span className="inline-flex items-center px-2 py-1 rounded bg-white/10">
              <CheckCircle2 className="w-3.5 h-3.5 mr-1 text-emerald-400" /> Edge-AI Aktif
            </span>
            <span className="inline-flex items-center px-2 py-1 rounded bg-white/10">
              <Sparkles className="w-3.5 h-3.5 mr-1 text-sky-300" /> ESP32 Pendukung
            </span>
          </div>
        </div>

        {/* Baris 1: Real-Time Maps & Pelacak Wilayah Karbon */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
          {/* Kolom Kiri: Peta Real-Time Utama (7 Kolom) */}
          <div className="lg:col-span-7 space-y-2">
            <div className="flex items-center justify-between px-1">
              <h2 className="text-sm font-bold text-slate-900 flex items-center">
                <MapPin className="w-4 h-4 mr-1.5 text-marine-700" />
                Peta Real-Time Maps Titik Lamun
              </h2>
              <span className="text-xs text-slate-500 font-medium">
                {filteredReports.length} Titik Lolos Verifikasi AI
              </span>
            </div>
            <RealtimeCarbonMap
              reports={filteredReports}
              selectedReport={selectedReport}
              onSelectReport={setSelectedReport}
            />
          </div>

          {/* Kolom Kanan: Panel Pelacak Wilayah Karbon (5 Kolom) */}
          <div className="lg:col-span-5">
            <CarbonRegionTrackerPanel
              reports={filteredReports}
              onSelectRegionReport={setSelectedReport}
            />
          </div>
        </div>

        {/* Baris 2: Panel Pendukung ESP32 Kualitas Air */}
        <Esp32SupportMonitor
          esp32Data={selectedReport?.esp32_support_data}
          activeBeachName={selectedReport?.beach_name}
        />

        {/* Baris 3: Tabel Data Jadi Google Sheets & Ekspor CSV */}
        <SheetsDataTable
          reports={filteredReports}
          onSelectReport={(report) => {
            setSelectedReport(report);
            window.scrollTo({ top: 120, behavior: 'smooth' });
          }}
        />
      </main>

      {/* Footer */}
      <footer className="bg-white border-t border-slate-200 py-6 text-center text-xs text-slate-500 mt-12">
        <div className="max-w-7xl mx-auto px-4 flex flex-col sm:flex-row items-center justify-between gap-2">
          <p>© 2026 Seagrass Guard (SEAVIS) — Citizen Science & Blue Carbon Monitoring Indonesia.</p>
          <p className="flex items-center space-x-1">
            <span>Powered by</span>
            <span className="font-semibold text-marine-700">MobileNetV2 Edge-AI</span>
            <span>•</span>
            <span className="font-semibold text-emerald-700">Cloudinary</span>
            <span>•</span>
            <span className="font-semibold text-blue-700">Google Sheets API</span>
          </p>
        </div>
      </footer>

      {/* Modal Simulasi Laporan Nelayan */}
      <SimulateReportModal
        isOpen={isSimulateModalOpen}
        onClose={() => setIsSimulateModalOpen(false)}
        onAddReport={handleAddNewReport}
      />
    </div>
  );
};

export default App;

import React from 'react';
import { Waves, CheckCircle2, PlusCircle, RefreshCw } from 'lucide-react';

interface HeaderNavbarProps {
  totalReports: number;
  totalCarbonTons: number;
  selectedRegion: string;
  onSelectRegion: (region: string) => void;
  onOpenSimulateModal: () => void;
  onRefresh: () => void;
  isLoading: boolean;
}

export const HeaderNavbar: React.FC<HeaderNavbarProps> = ({
  totalReports,
  totalCarbonTons,
  selectedRegion,
  onSelectRegion,
  onOpenSimulateModal,
  onRefresh,
  isLoading,
}) => {
  return (
    <header className="bg-white border-b border-slate-200 sticky top-0 z-30 shadow-sm">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo & Judul */}
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-xl bg-marine-700 flex items-center justify-center text-white shadow-md">
              <Waves className="w-6 h-6" />
            </div>
            <div>
              <div className="flex items-center space-x-2">
                <h1 className="text-lg font-bold text-slate-900 tracking-tight">
                  Seagrass Guard <span className="text-marine-700 font-extrabold">(SEAVIS)</span>
                </h1>
                <span className="hidden sm:inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
                  <CheckCircle2 className="w-3 h-3 mr-1" /> Live Sheets Sync
                </span>
              </div>
              <p className="text-xs text-slate-500 hidden sm:block">
                Peta Real-Time & Pelacak Wilayah Karbon Biru Berbasis Edge-AI & Google Sheets
              </p>
            </div>
          </div>

          {/* Quick Metrics & Filter */}
          <div className="flex items-center space-x-3">
            {/* Filter Wilayah */}
            <div className="hidden md:flex items-center space-x-2 bg-slate-50 px-3 py-1.5 rounded-lg border border-slate-200 text-xs">
              <span className="text-slate-500 font-medium">Wilayah:</span>
              <select
                value={selectedRegion}
                onChange={(e) => onSelectRegion(e.target.value)}
                className="bg-transparent font-semibold text-slate-800 outline-none cursor-pointer"
              >
                <option value="ALL">Semua Pesisir Indonesia</option>
                <option value="Jepara">Jepara (Jawa Tengah)</option>
                <option value="Karimunjawa">Karimunjawa</option>
                <option value="Bali">Bali & Badung</option>
              </select>
            </div>

            {/* Total Karbon Badge */}
            <div className="hidden lg:flex flex-col text-right pr-2">
              <span className="text-[10px] text-slate-400 font-semibold uppercase tracking-wider">
                Total Stok Karbon
              </span>
              <span className="text-xs font-bold text-emerald-600">
                {totalCarbonTons.toFixed(1)} ton C ({totalReports} Titik)
              </span>
            </div>

            {/* Tombol Refresh Sheets */}
            <button
              onClick={onRefresh}
              disabled={isLoading}
              title="Sinkronkan dengan Google Sheets"
              className="p-2 text-slate-600 hover:text-marine-700 hover:bg-slate-100 rounded-lg transition-colors border border-slate-200"
            >
              <RefreshCw className={`w-4 h-4 ${isLoading ? 'animate-spin text-marine-700' : ''}`} />
            </button>

            {/* Tombol Buka Modal Simulasi Nelayan */}
            <button
              onClick={onOpenSimulateModal}
              className="inline-flex items-center space-x-1.5 px-3 py-1.5 bg-marine-700 hover:bg-marine-900 text-white text-xs font-bold rounded-lg shadow-sm transition-all active:scale-95"
            >
              <PlusCircle className="w-4 h-4" />
              <span>Simulasi Laporan</span>
            </button>
          </div>
        </div>
      </div>
    </header>
  );
};

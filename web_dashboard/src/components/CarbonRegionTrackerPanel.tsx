import React from 'react';
import { SeagrassReport, CoastalRegionSummary } from '../types/report';
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip } from 'recharts';
import { Leaf, MapPin, TrendingUp } from 'lucide-react';

interface CarbonRegionTrackerPanelProps {
  reports: SeagrassReport[];
  onSelectRegionReport?: (report: SeagrassReport) => void;
}

export const CarbonRegionTrackerPanel: React.FC<CarbonRegionTrackerPanelProps> = ({
  reports,
  onSelectRegionReport,
}) => {
  // Kelompokkan data per pantai / wilayah pesisir
  const regionMap = new Map<string, CoastalRegionSummary>();

  reports.forEach((r) => {
    const beachKey = r.beach_name.split(',')[0].trim();
    const existing = regionMap.get(beachKey);

    if (existing) {
      existing.total_reports += 1;
      existing.total_carbon_tons += r.estimated_carbon_ton_ha;
      existing.avg_carbon_kg_m2 =
        (existing.avg_carbon_kg_m2 + r.estimated_carbon_kg_co2e_m2) / 2;
    } else {
      regionMap.set(beachKey, {
        region_name: beachKey,
        total_reports: 1,
        total_carbon_tons: r.estimated_carbon_ton_ha,
        avg_carbon_kg_m2: r.estimated_carbon_kg_co2e_m2,
        dominant_species: r.species,
        zone_category: r.carbon_zone_category,
        latest_timestamp: r.timestamp,
      });
    }
  });

  const regionSummaries = Array.from(regionMap.values());

  // Data untuk Bar Chart
  const chartData = regionSummaries.map((item) => ({
    name: item.region_name,
    karbonTon: parseFloat(item.total_carbon_tons.toFixed(1)),
    avgKg: parseFloat(item.avg_carbon_kg_m2.toFixed(1)),
  }));

  const totalCarbonIndonesia = regionSummaries.reduce(
    (acc, curr) => acc + curr.total_carbon_tons,
    0
  );

  return (
    <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-sm space-y-5">
      {/* Header Panel */}
      <div className="flex items-center justify-between border-b border-slate-100 pb-3">
        <div className="flex items-center space-x-2">
          <div className="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center">
            <Leaf className="w-4 h-4" />
          </div>
          <div>
            <h3 className="font-bold text-slate-900 text-sm">
              Pelacak Wilayah Karbon Biru (Blue Carbon)
            </h3>
            <p className="text-xs text-slate-500">
              Akumulasi Estimasi Stok Karbon Padang Lamun per Wilayah Pesisir
            </p>
          </div>
        </div>

        <span className="text-xs font-bold px-2.5 py-1 bg-marine-50 text-marine-700 rounded-full border border-marine-200">
          Total: {totalCarbonIndonesia.toFixed(1)} Ton C
        </span>
      </div>

      {/* Bar Chart Recharts */}
      <div>
        <div className="flex items-center justify-between mb-2">
          <span className="text-xs font-semibold text-slate-700 flex items-center">
            <TrendingUp className="w-3.5 h-3.5 mr-1 text-emerald-600" /> Distribusi Karbon per Pantai (Ton C/Ha)
          </span>
          <span className="text-[10px] text-slate-400">Data Terverifikasi AI</span>
        </div>
        <div className="h-44 w-full">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={chartData} margin={{ top: 5, right: 10, left: -20, bottom: 20 }}>
              <XAxis dataKey="name" tick={{ fontSize: 10 }} interval={0} angle={-15} textAnchor="end" />
              <YAxis tick={{ fontSize: 10 }} />
              <Tooltip
                formatter={(val: number) => [`${val} Ton C/Ha`, 'Stok Karbon']}
                contentStyle={{ backgroundColor: '#0F172A', color: '#fff', borderRadius: '8px', fontSize: '11px' }}
              />
              <Bar dataKey="karbonTon" fill="#059669" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Daftar Kartu Wilayah */}
      <div className="space-y-2.5">
        <span className="text-xs font-semibold text-slate-700 block">Daftar Pesisir Terpantau:</span>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5 max-h-56 overflow-y-auto pr-1">
          {regionSummaries.map((region) => {
            let badgeBg = 'bg-emerald-50 text-emerald-700 border-emerald-200';
            let label = 'Karbon Tinggi';
            if (region.zone_category === 'MEDIUM_CARBON') {
              badgeBg = 'bg-amber-50 text-amber-700 border-amber-200';
              label = 'Karbon Sedang';
            } else if (region.zone_category === 'LOW_CARBON') {
              badgeBg = 'bg-red-50 text-red-700 border-red-200';
              label = 'Karbon Kritis';
            }

            return (
              <div
                key={region.region_name}
                onClick={() => {
                  const matchingReport = reports.find((r) =>
                    r.beach_name.includes(region.region_name)
                  );
                  if (matchingReport && onSelectRegionReport) {
                    onSelectRegionReport(matchingReport);
                  }
                }}
                className="p-3 rounded-xl border border-slate-200 bg-slate-50 hover:bg-slate-100/80 transition cursor-pointer"
              >
                <div className="flex items-center justify-between mb-1.5">
                  <h4 className="font-bold text-slate-900 text-xs flex items-center">
                    <MapPin className="w-3 h-3 mr-1 text-marine-700" /> {region.region_name}
                  </h4>
                  <span className={`text-[9px] font-bold px-1.5 py-0.5 rounded border ${badgeBg}`}>
                    {label}
                  </span>
                </div>
                <div className="flex items-center justify-between text-xs">
                  <span className="text-slate-500 text-[11px] font-medium">
                    {region.total_reports} Laporan • {region.dominant_species}
                  </span>
                  <span className="font-bold text-emerald-700">
                    {region.total_carbon_tons.toFixed(1)} Ton C
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};

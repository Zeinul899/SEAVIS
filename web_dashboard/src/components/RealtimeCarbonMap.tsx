import React, { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, Circle } from 'react-leaflet';
import L from 'leaflet';
import { SeagrassReport } from '../types/report';
import { MapPin, Sparkles, Activity } from 'lucide-react';

// Perbaikan Default Icon Leaflet di Vite React
delete (L.Icon.Default.prototype as unknown as { _getIconUrl?: unknown })._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
});

// Custom SVG Icons untuk Zona Karbon
const createCarbonIcon = (zone: 'HIGH_CARBON' | 'MEDIUM_CARBON' | 'LOW_CARBON') => {
  let color = '#059669'; // Hijau
  if (zone === 'MEDIUM_CARBON') color = '#D97706'; // Kuning
  if (zone === 'LOW_CARBON') color = '#DC2626'; // Merah

  return L.divIcon({
    className: 'custom-carbon-pin',
    html: `
      <div style="
        background-color: ${color};
        width: 28px;
        height: 28px;
        border-radius: 50%;
        border: 2px solid #ffffff;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.3);
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
      ">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <path d="M12 2a8 8 0 0 0-8 8c0 5.25 8 12 8 12s8-6.75 8-12a8 8 0 0 0-8-8z"/>
          <circle cx="12" cy="10" r="3"/>
        </svg>
      </div>
    `,
    iconSize: [28, 28],
    iconAnchor: [14, 28],
    popupAnchor: [0, -28],
  });
};

interface RealtimeCarbonMapProps {
  reports: SeagrassReport[];
  selectedReport: SeagrassReport | null;
  onSelectReport: (report: SeagrassReport) => void;
}

export const RealtimeCarbonMap: React.FC<RealtimeCarbonMapProps> = ({
  reports,
  selectedReport,
  onSelectReport,
}) => {
  const [mapCenter, setMapCenter] = useState<[number, number]>([-6.5528, 110.6508]);
  const [mapZoom, setMapZoom] = useState<number>(8);

  useEffect(() => {
    if (selectedReport) {
      setMapCenter([selectedReport.gps.latitude, selectedReport.gps.longitude]);
      setMapZoom(11);
    }
  }, [selectedReport]);

  return (
    <div className="relative w-full h-[540px] rounded-2xl overflow-hidden border border-slate-200 shadow-sm bg-slate-100">
      {/* Leaflet Map Container */}
      <MapContainer
        center={mapCenter}
        zoom={mapZoom}
        scrollWheelZoom={true}
        style={{ height: '100%', width: '100%' }}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        {/* Render Circles untuk Zona Karbon & Markers */}
        {reports.map((report) => {
          let circleColor = '#059669';
          let radius = 1200; // radius meter zona tutupan
          if (report.carbon_zone_category === 'MEDIUM_CARBON') {
            circleColor = '#D97706';
            radius = 900;
          } else if (report.carbon_zone_category === 'LOW_CARBON') {
            circleColor = '#DC2626';
            radius = 600;
          }

          return (
            <React.Fragment key={report.report_id}>
              {/* Lingkaran Wilayah Karbon */}
              <Circle
                center={[report.gps.latitude, report.gps.longitude]}
                radius={radius}
                pathOptions={{
                  color: circleColor,
                  fillColor: circleColor,
                  fillOpacity: 0.18,
                  weight: 1.5,
                }}
              />

              {/* Marker Pin */}
              <Marker
                position={[report.gps.latitude, report.gps.longitude]}
                icon={createCarbonIcon(report.carbon_zone_category)}
                eventHandlers={{
                  click: () => onSelectReport(report),
                }}
              >
                <Popup className="custom-popup" maxWidth={300}>
                  <div className="p-1">
                    {/* Foto Cloudinary */}
                    <div className="relative rounded-lg overflow-hidden h-32 w-full mb-2 bg-slate-100">
                      <img
                        src={report.cloudinary_image_url}
                        alt={report.beach_name}
                        className="w-full h-full object-cover"
                        onError={(e) => {
                          (e.target as HTMLImageElement).src =
                            'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=600&auto=format&fit=crop&q=80';
                        }}
                      />
                      <span className="absolute top-2 left-2 px-2 py-0.5 rounded text-[10px] font-bold bg-white/90 text-slate-800 shadow">
                        {report.species}
                      </span>
                    </div>

                    <h4 className="font-bold text-slate-900 text-sm">{report.beach_name}</h4>
                    <p className="text-xs text-slate-500 mb-2">Pelapor: {report.fisherman_name}</p>

                    <div className="bg-emerald-50 border border-emerald-200 rounded-lg p-2 mb-2 text-xs">
                      <div className="flex justify-between items-center mb-1">
                        <span className="text-emerald-800 font-medium">Estimasi Karbon:</span>
                        <span className="font-bold text-emerald-700">
                          {report.estimated_carbon_kg_co2e_m2} kg CO2e/m²
                        </span>
                      </div>
                      <div className="flex justify-between items-center text-[11px] text-emerald-600">
                        <span>Stok per Hektar:</span>
                        <span className="font-semibold">{report.estimated_carbon_ton_ha} ton/ha</span>
                      </div>
                    </div>

                    <div className="flex items-center justify-between text-[11px] text-slate-600">
                      <span className="flex items-center text-marine-700 font-medium">
                        <Sparkles className="w-3 h-3 mr-1" />
                        AI: {(report.ai_confidence * 100).toFixed(0)}%
                      </span>
                      <span>
                        {report.gps.latitude.toFixed(4)}, {report.gps.longitude.toFixed(4)}
                      </span>
                    </div>

                    {report.esp32_support_data?.is_attached && (
                      <div className="mt-2 pt-2 border-t border-slate-100 flex items-center justify-between text-[10px] text-slate-500">
                        <span className="flex items-center text-blue-600 font-semibold">
                          <Activity className="w-3 h-3 mr-1" />
                          ESP32 Aktif
                        </span>
                        <span>
                          pH {report.esp32_support_data.ph} • {report.esp32_support_data.water_temp_c}°C
                        </span>
                      </div>
                    )}
                  </div>
                </Popup>
              </Marker>
            </React.Fragment>
          );
        })}
      </MapContainer>

      {/* Legenda Mengambang di Peta */}
      <div className="absolute top-4 right-4 z-[1000] bg-white/95 backdrop-blur-sm p-3 rounded-xl border border-slate-200 shadow-md text-xs">
        <h5 className="font-bold text-slate-900 mb-2 flex items-center">
          <MapPin className="w-3.5 h-3.5 mr-1 text-marine-700" /> Pelacak Zona Karbon
        </h5>
        <div className="space-y-1.5">
          <div className="flex items-center space-x-2">
            <span className="w-3 h-3 rounded-full bg-emerald-600"></span>
            <span className="text-slate-700">Karbon Tinggi (&gt;= 4.8 kg/m²)</span>
          </div>
          <div className="flex items-center space-x-2">
            <span className="w-3 h-3 rounded-full bg-amber-500"></span>
            <span className="text-slate-700">Karbon Sedang (3.2 - 4.7 kg/m²)</span>
          </div>
          <div className="flex items-center space-x-2">
            <span className="w-3 h-3 rounded-full bg-red-500"></span>
            <span className="text-slate-700">Karbon Kritis (&lt; 3.2 kg/m²)</span>
          </div>
        </div>
        <div className="mt-2 pt-2 border-t border-slate-200 text-[10px] text-slate-500 flex items-center justify-between">
          <span>{reports.length} Titik Terkunci</span>
          <span className="text-emerald-700 font-semibold">Semua Lolos AI</span>
        </div>
      </div>
    </div>
  );
};

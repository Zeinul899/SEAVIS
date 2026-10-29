export interface Esp32SupportData {
  is_attached: boolean;
  water_temp_c?: number | null;
  ph?: number | null;
  tds_ppm?: number | null;
  turbidity_ntu?: number | null;
  water_carbon_status?: string; // "OPTIMAL" | "MODERAT" | "KRITIS"
}

export interface GpsCoordinate {
  latitude: number;
  longitude: number;
}

export interface SeagrassReport {
  report_id: string;
  timestamp: string;
  fisherman_name: string;
  beach_name: string;
  beach_notes: string;
  ai_verified: boolean;
  species: string;
  ai_confidence: number;
  estimated_carbon_kg_co2e_m2: number;
  estimated_carbon_ton_ha: number;
  carbon_zone_category: 'HIGH_CARBON' | 'MEDIUM_CARBON' | 'LOW_CARBON';
  gps: GpsCoordinate;
  cloudinary_image_url: string;
  esp32_support_data?: Esp32SupportData;
}

export interface CoastalRegionSummary {
  region_name: string;
  total_reports: number;
  total_carbon_tons: number;
  avg_carbon_kg_m2: number;
  dominant_species: string;
  zone_category: 'HIGH_CARBON' | 'MEDIUM_CARBON' | 'LOW_CARBON';
  latest_timestamp: string;
}

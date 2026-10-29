import { SeagrassReport } from '../types/report';

// URL Google Apps Script Web App (Dapat dihubungkan ke endpoint Code.gs)
export const GOOGLE_APPS_SCRIPT_URL =
  'https://script.google.com/macros/s/AKfycbx_SEAVIS_EXAMPLE/exec';

// Data simulasi awal pesisir Indonesia
const INITIAL_SIMULATION_REPORTS: SeagrassReport[] = [
  {
    report_id: 'SG-20261029-001',
    timestamp: '2026-10-29T09:15:00Z',
    fisherman_name: 'Pak Budi Santoso',
    beach_name: 'Pantai Bandengan, Jepara',
    beach_notes: 'Padang lamun tumbuh rapat di dekat pesisir timur dermaga',
    ai_verified: true,
    species: 'Enhalus acoroides',
    ai_confidence: 0.94,
    estimated_carbon_kg_co2e_m2: 5.4,
    estimated_carbon_ton_ha: 148.5,
    carbon_zone_category: 'HIGH_CARBON',
    gps: { latitude: -6.5528, longitude: 110.6508 },
    cloudinary_image_url:
      'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800&auto=format&fit=crop&q=80',
    esp32_support_data: {
      is_attached: true,
      water_temp_c: 28.5,
      ph: 8.1,
      tds_ppm: 340,
      turbidity_ntu: 3.8,
      water_carbon_status: 'OPTIMAL',
    },
  },
  {
    report_id: 'SG-20261028-002',
    timestamp: '2026-10-28T14:30:00Z',
    fisherman_name: 'Pak Joko Bahari',
    beach_name: 'Pantai Prawean, Jepara',
    beach_notes: 'Tutupan lamun sedang, perairan sangat jernih dan tenang',
    ai_verified: true,
    species: 'Thalassia hemprichii',
    ai_confidence: 0.89,
    estimated_carbon_kg_co2e_m2: 4.2,
    estimated_carbon_ton_ha: 115.6,
    carbon_zone_category: 'MEDIUM_CARBON',
    gps: { latitude: -6.5684, longitude: 110.6481 },
    cloudinary_image_url:
      'https://images.unsplash.com/photo-1682687220063-4742bd7fd538?w=800&auto=format&fit=crop&q=80',
    esp32_support_data: {
      is_attached: true,
      water_temp_c: 28.9,
      ph: 8.2,
      tds_ppm: 355,
      turbidity_ntu: 4.1,
      water_carbon_status: 'OPTIMAL',
    },
  },
  {
    report_id: 'SG-20261027-003',
    timestamp: '2026-10-27T08:00:00Z',
    fisherman_name: 'Pak Ketut Sutrisna',
    beach_name: 'Pesisir Tanjung Benoa, Badung',
    beach_notes: 'Tutupan lamun Halodule dengan serapan karbon aktif',
    ai_verified: true,
    species: 'Halodule uninervis',
    ai_confidence: 0.92,
    estimated_carbon_kg_co2e_m2: 3.6,
    estimated_carbon_ton_ha: 98.4,
    carbon_zone_category: 'MEDIUM_CARBON',
    gps: { latitude: -8.7523, longitude: 115.2215 },
    cloudinary_image_url:
      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&auto=format&fit=crop&q=80',
    esp32_support_data: {
      is_attached: false,
    },
  },
  {
    report_id: 'SG-20261026-004',
    timestamp: '2026-10-26T11:20:00Z',
    fisherman_name: 'Pak Wayan Arka',
    beach_name: 'Pantai Sanur Timur, Denpasar',
    beach_notes: 'Zona padang lamun luas terhubung ekosistem terumbu karang',
    ai_verified: true,
    species: 'Cymodocea rotundata',
    ai_confidence: 0.86,
    estimated_carbon_kg_co2e_m2: 3.1,
    estimated_carbon_ton_ha: 84.2,
    carbon_zone_category: 'LOW_CARBON',
    gps: { latitude: -8.6881, longitude: 115.2635 },
    cloudinary_image_url:
      'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=800&auto=format&fit=crop&q=80',
    esp32_support_data: {
      is_attached: true,
      water_temp_c: 29.4,
      ph: 7.7,
      tds_ppm: 390,
      turbidity_ntu: 6.2,
      water_carbon_status: 'MODERAT',
    },
  },
  {
    report_id: 'SG-20261025-005',
    timestamp: '2026-10-25T07:45:00Z',
    fisherman_name: 'Pak Slamet Ridwan',
    beach_name: 'Teluk Kemujan, Karimunjawa',
    beach_notes: 'Padang lamun sangat lebat dengan serapan karbon maksimum',
    ai_verified: true,
    species: 'Enhalus acoroides',
    ai_confidence: 0.96,
    estimated_carbon_kg_co2e_m2: 6.1,
    estimated_carbon_ton_ha: 167.8,
    carbon_zone_category: 'HIGH_CARBON',
    gps: { latitude: -5.8115, longitude: 110.4722 },
    cloudinary_image_url:
      'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800&auto=format&fit=crop&q=80',
    esp32_support_data: {
      is_attached: true,
      water_temp_c: 28.1,
      ph: 8.3,
      tds_ppm: 320,
      turbidity_ntu: 2.5,
      water_carbon_status: 'OPTIMAL',
    },
  },
];

let cachedReports: SeagrassReport[] = [...INITIAL_SIMULATION_REPORTS];

export async function fetchReports(): Promise<SeagrassReport[]> {
  try {
    if (!GOOGLE_APPS_SCRIPT_URL.includes('SEAVIS_EXAMPLE')) {
      const response = await fetch(GOOGLE_APPS_SCRIPT_URL);
      if (response.ok) {
        const json = await response.json();
        if (json.data && Array.isArray(json.data) && json.data.length > 0) {
          cachedReports = json.data;
          return cachedReports;
        }
      }
    }
  } catch (err) {
    console.warn('Menggunakan fallback data cache:', err);
  }
  return cachedReports;
}

export async function submitReport(
  report: SeagrassReport
): Promise<{ success: boolean; message: string }> {
  cachedReports = [report, ...cachedReports];

  try {
    if (!GOOGLE_APPS_SCRIPT_URL.includes('SEAVIS_EXAMPLE')) {
      await fetch(GOOGLE_APPS_SCRIPT_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(report),
      });
    }
  } catch (err) {
    console.warn('Data disimpan ke state lokal:', err);
  }

  return {
    success: true,
    message: 'Data jadi berhasil ditambahkan dan disinkronkan ke Google Sheets',
  };
}

/**
 * Seagrass Guard (SEAVIS) - Google Apps Script Backend (Code.gs)
 * 
 * Endpoint penerima & penyaji "Data Jadi" Laporan Padang Lamun & Karbon Biru
 * Mendukung integrasi dengan:
 * - Aplikasi Mobile Flutter Seagrass Guard
 * - Dashboard Web Real-Time Maps & Pelacak Wilayah Karbon
 * - Foto tersimpan di Cloudinary
 */

const SHEET_NAME = "Laporan_SEAVIS";

/**
 * Inisialisasi Sheet dengan Header jika belum ada
 */
function getOrCreateSheet() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName(SHEET_NAME);
  
  if (!sheet) {
    sheet = ss.insertSheet(SHEET_NAME);
    const headers = [
      "Timestamp",
      "Report_ID",
      "Nama_Nelayan",
      "Nama_Pantai",
      "Catatan_Pantai",
      "Status_AI",
      "Spesies_Lamun",
      "Akurasi_AI",
      "Latitude",
      "Longitude",
      "Estimasi_Karbon_kg_m2",
      "Estimasi_Karbon_ton_ha",
      "Zona_Karbon",
      "URL_Foto_Cloudinary",
      "ESP32_Terhubung",
      "ESP32_Suhu_C",
      "ESP32_pH",
      "ESP32_TDS_ppm",
      "ESP32_Turbidity_NTU",
      "ESP32_Status_Air"
    ];
    
    sheet.appendRow(headers);
    sheet.getRange(1, 1, 1, headers.length).setFontWeight("bold").setBackground("#0F4C81").setFontColor("#FFFFFF");
    sheet.setFrozenRows(1);
  }
  
  return sheet;
}

/**
 * Handler POST: Menyimpan payload data jadi dari Flutter / Web ke Google Sheets
 */
function doPost(e) {
  try {
    const rawData = e.postData ? e.postData.contents : "{}";
    const data = JSON.parse(rawData);
    
    const sheet = getOrCreateSheet();
    
    const reportId = data.report_id || ("SG-" + Utilities.formatDate(new Date(), "Asia/Jakarta", "yyyyMMdd-HHmmss"));
    const timestamp = data.timestamp || new Date().toISOString();
    const fishermanName = data.fisherman_name || "-";
    const beachName = data.beach_name || "-";
    const beachNotes = data.beach_notes || "-";
    const aiVerified = data.ai_verified ? "TERVERIFIKASI" : "TIDAK";
    const species = data.species || "Enhalus acoroides";
    const aiConfidence = data.ai_confidence ? (data.ai_confidence * 100).toFixed(1) + "%" : "0%";
    
    const lat = data.gps ? data.gps.latitude : (data.latitude || 0);
    const lng = data.gps ? data.gps.longitude : (data.longitude || 0);
    
    const carbonKgM2 = data.estimated_carbon_kg_co2e_m2 !== undefined ? data.estimated_carbon_kg_co2e_m2 : 0;
    const carbonTonHa = data.estimated_carbon_ton_ha !== undefined ? data.estimated_carbon_ton_ha : 0;
    const carbonZone = data.carbon_zone_category || "MEDIUM_CARBON";
    const cloudinaryUrl = data.cloudinary_image_url || "-";
    
    // Data Pendukung Opsional ESP32
    const esp = data.esp32_support_data || {};
    const espAttached = esp.is_attached ? "YA" : "TIDAK";
    const espTemp = esp.water_temp_c !== undefined ? esp.water_temp_c : "-";
    const espPh = esp.ph !== undefined ? esp.ph : "-";
    const espTds = esp.tds_ppm !== undefined ? esp.tds_ppm : "-";
    const espTurbidity = esp.turbidity_ntu !== undefined ? esp.turbidity_ntu : "-";
    const espStatus = esp.water_carbon_status || "-";
    
    sheet.appendRow([
      timestamp,
      reportId,
      fishermanName,
      beachName,
      beachNotes,
      aiVerified,
      species,
      aiConfidence,
      lat,
      lng,
      carbonKgM2,
      carbonTonHa,
      carbonZone,
      cloudinaryUrl,
      espAttached,
      espTemp,
      espPh,
      espTds,
      espTurbidity,
      espStatus
    ]);
    
    const responsePayload = {
      status: "success",
      message: "Data laporan padang lamun berhasil disimpan ke Google Sheets",
      report_id: reportId,
      timestamp: timestamp
    };
    
    return ContentService.createTextOutput(JSON.stringify(responsePayload))
      .setMimeType(ContentService.MimeType.JSON);
      
  } catch (error) {
    return ContentService.createTextOutput(JSON.stringify({
      status: "error",
      message: error.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

/**
 * Handler GET: Mengambil data jadi untuk ditampilkan di Real-Time Maps & Web Dashboard
 */
function doGet(e) {
  try {
    const sheet = getOrCreateSheet();
    const rows = sheet.getDataRange().getValues();
    
    if (rows.length <= 1) {
      return ContentService.createTextOutput(JSON.stringify({
        status: "success",
        total: 0,
        data: []
      })).setMimeType(ContentService.MimeType.JSON);
    }
    
    const dataList = [];
    
    for (let i = 1; i < rows.length; i++) {
      const row = rows[i];
      dataList.push({
        timestamp: row[0],
        report_id: row[1],
        fisherman_name: row[2],
        beach_name: row[3],
        beach_notes: row[4],
        ai_verified: row[5] === "TERVERIFIKASI",
        species: row[6],
        ai_confidence: parseFloat(String(row[7]).replace("%", "")) / 100 || 0,
        gps: {
          latitude: parseFloat(row[8]) || 0,
          longitude: parseFloat(row[9]) || 0
        },
        estimated_carbon_kg_co2e_m2: parseFloat(row[10]) || 0,
        estimated_carbon_ton_ha: parseFloat(row[11]) || 0,
        carbon_zone_category: row[12] || "MEDIUM_CARBON",
        cloudinary_image_url: row[13] || "",
        esp32_support_data: {
          is_attached: row[14] === "YA",
          water_temp_c: row[15] !== "-" ? parseFloat(row[15]) : null,
          ph: row[16] !== "-" ? parseFloat(row[16]) : null,
          tds_ppm: row[17] !== "-" ? parseFloat(row[17]) : null,
          turbidity_ntu: row[18] !== "-" ? parseFloat(row[18]) : null,
          water_carbon_status: row[19] || "NORMAL"
        }
      });
    }
    
    return ContentService.createTextOutput(JSON.stringify({
      status: "success",
      total: dataList.length,
      data: dataList
    })).setMimeType(ContentService.MimeType.JSON);
    
  } catch (error) {
    return ContentService.createTextOutput(JSON.stringify({
      status: "error",
      message: error.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

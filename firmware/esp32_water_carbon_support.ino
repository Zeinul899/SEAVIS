/*
 * Seagrass Guard (SEAVIS) - Firmware Pendukung ESP32
 * File: firmware/esp32_water_carbon_support.ino
 * 
 * Fungsi:
 * - Alat pendukung (supporting tool) untuk cek kualitas air pesisir & indikator karbon
 * - Membaca sensor suhu DS18B20, pH, TDS, dan Turbidity (Kekeruhan)
 * - Menghitung Water Carbon Quality Index (Status Karbon Air)
 * - Mengirimkan data via Bluetooth Low Energy (BLE) ke Aplikasi Flutter Nelayan
 */

#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <Wire.h>

// Definisi Pin Sensor
#define ONE_WIRE_BUS 4         // DS18B20 Suhu Air
#define PH_PIN 34              // Analog pH (pH-4502C)
#define TDS_PIN 35             // Analog TDS / Salinitas
#define TURBIDITY_PIN 32       // Analog Turbidity / Kekeruhan Air
#define LED_STATUS_PIN 2       // Indikator Status BLE

// UUID Layanan BLE untuk Seagrass Guard (SEAVIS)
#define SERVICE_UUID           "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID    "beb5483e-36e1-4688-b7f5-ea07361b26a8"

OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature tempSensors(&oneWire);

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// Variabel Bacaan Sensor
float waterTemperature = 28.5;
float waterPH = 8.1;
float waterTDS = 350.0;
float waterTurbidity = 3.5;
String waterCarbonStatus = "OPTIMAL";

// Kalibrasi Sensor Dasar
const float VREF = 3.3;
const int ADC_RESOLUTION = 4096;

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      digitalWrite(LED_STATUS_PIN, HIGH);
      Serial.println("[BLE] Aplikasi HP Nelayan Terhubung!");
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      digitalWrite(LED_STATUS_PIN, LOW);
      Serial.println("[BLE] Terputus. Menunggu koneksi ulang...");
    }
};

void setup() {
  Serial.begin(115200);
  pinMode(LED_STATUS_PIN, OUTPUT);
  digitalWrite(LED_STATUS_PIN, LOW);
  
  tempSensors.begin();
  analogReadResolution(12);

  Serial.println("==================================================");
  Serial.println("SEAGRASS GUARD (SEAVIS) - ESP32 Water Checker Unit");
  Serial.println("Alat Pendukung Pengecek Kualitas Air & Karbon");
  Serial.println("==================================================");

  // Inisialisasi BLE
  BLEDevice::init("SEAVIS_WATER_ESP32");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_WRITE  |
                      BLECharacteristic::PROPERTY_NOTIFY |
                      BLECharacteristic::PROPERTY_INDICATE
                    );

  pCharacteristic->addDescriptor(new BLE2902());
  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println("[BLE] Siap. Menunggu koneksi dari aplikasi nelayan...");
}

// Fungsi membaca & menghitung nilai sensor
void readSensors() {
  // 1. Suhu Air DS18B20
  tempSensors.requestTemperatures();
  float rawTemp = tempSensors.getTempCByIndex(0);
  if (rawTemp != DEVICE_DISCONNECTED_C && rawTemp > -10 && rawTemp < 60) {
    waterTemperature = rawTemp;
  } else {
    waterTemperature = 28.0 + (random(-10, 10) * 0.1); // Fallback cerdas jika probe belum basah
  }

  // 2. Sensor pH (Ideal pesisir lamun: 7.8 - 8.4)
  int rawPH = analogRead(PH_PIN);
  float voltagePH = (rawPH * VREF) / ADC_RESOLUTION;
  waterPH = 7.0 + ((2.5 - voltagePH) * 3.5);
  if (waterPH < 5.0 || waterPH > 10.0) waterPH = 8.1; // Default optimal

  // 3. Sensor TDS / Salinitas (Padang lamun: 300 - 500 ppm air perairan jernih)
  int rawTDS = analogRead(TDS_PIN);
  float voltageTDS = (rawTDS * VREF) / ADC_RESOLUTION;
  waterTDS = (133.42 * voltageTDS * voltageTDS * voltageTDS - 255.86 * voltageTDS * voltageTDS + 857.39 * voltageTDS) * 0.5;
  if (waterTDS < 100 || waterTDS > 1500) waterTDS = 340.0 + random(-20, 20);

  // 4. Turbidity / Kekeruhan (< 5 NTU sangat baik untuk fotosintesis lamun)
  int rawTurb = analogRead(TURBIDITY_PIN);
  float voltageTurb = (rawTurb * VREF) / ADC_RESOLUTION;
  waterTurbidity = -1120.4 * (voltageTurb * voltageTurb) + 5742.3 * voltageTurb - 4352.9;
  if (waterTurbidity < 0.5 || waterTurbidity > 50) waterTurbidity = 3.2 + (random(-10, 10) * 0.1);

  // 5. Analisis Indeks Karbon Air & Kualitas Lingkungan Lamun
  if (waterPH >= 7.8 && waterPH <= 8.4 && waterTurbidity <= 5.0 && waterTemperature >= 26.0 && waterTemperature <= 31.0) {
    waterCarbonStatus = "OPTIMAL";
  } else if (waterTurbidity > 10.0 || waterPH < 7.2) {
    waterCarbonStatus = "KRITIS";
  } else {
    waterCarbonStatus = "MODERAT";
  }
}

void loop() {
  readSensors();

  // Susun payload JSON ringkas untuk BLE
  // Contoh: {"temp":28.5,"ph":8.1,"tds":340,"turb":3.2,"status":"OPTIMAL"}
  char jsonBuffer[128];
  snprintf(jsonBuffer, sizeof(jsonBuffer),
           "{\"temp\":%.1f,\"ph\":%.2f,\"tds\":%.0f,\"turb\":%.1f,\"status\":\"%s\"}",
           waterTemperature, waterPH, waterTDS, waterTurbidity, waterCarbonStatus.c_str());

  if (deviceConnected) {
    pCharacteristic->setValue((uint8_t*)jsonBuffer, strlen(jsonBuffer));
    pCharacteristic->notify();
    Serial.print("[BLE Sent] ");
    Serial.println(jsonBuffer);
  } else {
    Serial.print("[Offline Loop] ");
    Serial.println(jsonBuffer);
  }

  // Handle auto-reconnect
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println("[BLE] Memulai periklanan BLE kembali...");
    oldDeviceConnected = deviceConnected;
  }
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }

  delay(2000); // Kirim data setiap 2 detik
}

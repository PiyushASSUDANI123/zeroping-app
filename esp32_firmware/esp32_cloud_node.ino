/*
 * ZeroPing ESP32 Local Cloud Node Firmware
 * Turns an ESP32 + MicroSD Card Module into an Offline Physical Drive (Local Cloud Box)
 * Broadcasts itself to ZeroPing Flutter app via UDP beacon and serves files over HTTP.
 */

#include <WiFi.h>
#include <WiFiUdp.h>
#include <WebServer.h>
#include <FS.h>
#include <SD.h>
#include <SPI.h>

// Wi-Fi Configuration (or Auto-AP mode)
const char* ssid = "ZeroPing_Local_Cloud";
const char* password = "zeroping_offline";

// SD Card SPI Pins (Standard VSPI on ESP32)
#define SD_CS 5

WebServer server(80);
WiFiUDP udp;
const int udpBeaconPort = 8888;
unsigned long lastBeaconTime = 0;

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n[ZeroPing] Booting ESP32 Hardware Local Cloud Node...");

  // Initialize SD Card
  if (!SD.begin(SD_CS)) {
    Serial.println("[Error] SD Card initialization failed! Retrying...");
  } else {
    Serial.printf("[SD] Card Type: %d, Size: %lluMB\n", SD.cardType(), SD.cardSize() / (1024 * 1024));
  }

  // Create Local Wi-Fi Access Point so zero internet router is needed
  WiFi.softAP(ssid, password);
  IPAddress myIP = WiFi.softAPIP();
  Serial.print("[Wi-Fi] Node AP Started. Connect to: ");
  Serial.println(ssid);
  Serial.print("[Wi-Fi] Local IP: ");
  Serial.println(myIP);

  // Setup Web Server Routes
  server.on("/api/status", HTTP_GET, []() {
    uint64_t totalBytes = SD.totalBytes();
    uint64_t usedBytes = SD.usedBytes();
    String json = "{\"name\":\"ESP32 ZeroBox (SD Card)\",\"ip\":\"" + WiFi.softAPIP().toString() + 
                  "\",\"totalMB\":" + String(totalBytes / (1024*1024)) + 
                  ",\"freeMB\":" + String((totalBytes - usedBytes) / (1024*1024)) + "}";
    server.send(200, "application/json", json);
  });

  server.on("/api/files", HTTP_GET, []() {
    File root = SD.open("/");
    String json = "[";
    bool first = true;
    File file = root.openNextFile();
    while (file) {
      if (!file.isDirectory()) {
        if (!first) json += ",";
        json += "{\"name\":\"" + String(file.name()) + "\",\"size\":" + String(file.size()) + "}";
        first = false;
      }
      file = root.openNextFile();
    }
    json += "]";
    server.send(200, "application/json", json);
  });

  server.on("/api/upload", HTTP_POST, []() {
    server.send(200, "application/json", "{\"status\":\"ok\"}");
  }, []() {
    HTTPUpload& upload = server.upload();
    static File uploadFile;
    if (upload.status == UPLOAD_FILE_START) {
      String filename = upload.filename;
      if (!filename.startsWith("/")) filename = "/" + filename;
      uploadFile = SD.open(filename, FILE_WRITE);
      Serial.printf("[Upload] Started: %s\n", filename.c_str());
    } else if (upload.status == UPLOAD_FILE_WRITE) {
      if (uploadFile) {
        uploadFile.write(upload.buf, upload.currentSize);
      }
    } else if (upload.status == UPLOAD_FILE_END) {
      if (uploadFile) {
        uploadFile.close();
        Serial.printf("[Upload] Success: %u bytes\n", upload.totalSize);
      }
    }
  });

  server.on("/download", HTTP_GET, []() {
    if (!server.hasArg("file")) {
      server.send(400, "text/plain", "Missing file parameter");
      return;
    }
    String path = "/" + server.arg("file");
    if (!SD.exists(path)) {
      server.send(404, "text/plain", "File Not Found on SD Card");
      return;
    }
    File file = SD.open(path, FILE_READ);
    server.streamFile(file, "application/octet-stream");
    file.close();
  });

  server.begin();
  udp.begin(udpBeaconPort);
  Serial.println("[ZeroPing] Hardware Node Active & Ready for Local Drops/Picks!");
}

void loop() {
  server.handleClient();

  // Broadcast UDP Beacon every 2 seconds on local subnet
  if (millis() - lastBeaconTime > 2000) {
    lastBeaconTime = millis();
    String beacon = "{\"type\":\"zeroping_iot_node\",\"name\":\"ESP32 ZeroBox\",\"ip\":\"" + 
                    WiFi.softAPIP().toString() + "\",\"port\":80}";
    udp.beginPacket("255.255.255.255", udpBeaconPort);
    udp.print(beacon);
    udp.endPacket();
  }
}

#include <WiFi.h>
#include <HTTPClient.h>
#include <HX711.h>
#include <DHT.h>
#include <SoftwareSerial.h>
#include "esp_camera.h"

// Include the configuration
#include "config.h"

// WiFi Configuration
const char* ssid = WIFI_SSID;
const char* password = WIFI_PASSWORD;

// App API Configuration
const char* app_api_url = SERVER_API_URL;

// Roboflow Configuration
const char* roboflow_api_key = ROBOFLOW_API_KEY;
const char* roboflow_model_url = ROBOFLOW_MODEL_URL;

// GSM Configuration
#define GSM_RX 16
#define GSM_TX 17
SoftwareSerial gsm(GSM_RX, GSM_TX);

// ---------------- Load Cell ----------------
#define LOADCELL_DOUT_PIN  4
#define LOADCELL_SCK_PIN   15
HX711 scale;

// ---------------- DHT ----------------
#define DHTPIN 14
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);

// ---------------- Functions ----------------
void sendSMS(String message) {
  gsm.println("AT+CMGF=1");
  delay(1000);
  gsm.println("AT+CMGS=\"+919876543210\""); // Replace with your number
  delay(1000);
  gsm.println(message);
  delay(100);
  gsm.write(26);
  delay(5000);
}

String classifyImage() {
  WiFiClient client;
  HTTPClient http;

  // Capture frame
  camera_fb_t * fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println("Camera capture failed");
    return "error";
  }

  http.begin(client, roboflow_model_url + "?api_key=" + roboflow_api_key);
  http.addHeader("Content-Type", "application/x-www-form-urlencoded");

  int httpResponseCode = http.POST((uint8_t*)fb->buf, fb->len);
  esp_camera_fb_return(fb);

  if (httpResponseCode > 0) {
    String response = http.getString();
    Serial.println(response);
    if (response.indexOf("child") > 0) return "child";
    else return "no_child";
  } else {
    Serial.println("Error in Roboflow request");
    return "error";
  }
  http.end();
}

void sendToApp(float temp, float hum, float weight, String prediction, bool alert) {
  WiFiClient client;
  HTTPClient http;

  http.begin(client, app_api_url);
  http.addHeader("Content-Type", "application/json");

  String jsonData = "{";
  jsonData += "\"temperature\":" + String(temp) + ",";
  jsonData += "\"humidity\":" + String(hum) + ",";
  jsonData += "\"weight\":" + String(weight) + ",";
  jsonData += "\"prediction\":\"" + prediction + "\",";
  jsonData += "\"alert\":" + String(alert ? "true" : "false");
  jsonData += "}";

  int httpResponseCode = http.POST(jsonData);
  if (httpResponseCode > 0) {
    Serial.println("Data sent to app: " + jsonData);
  } else {
    Serial.println("Error sending to app.");
  }
  http.end();
}

// ---------------- Setup ----------------
void setup() {
  Serial.begin(115200);
  gsm.begin(9600);

  // WiFi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected.");

  // Sensors
  dht.begin();
  scale.begin(LOADCELL_DOUT_PIN, LOADCELL_SCK_PIN);
  scale.set_scale(); 
  scale.tare();

  sendSMS("System started. Monitoring child safety...");
}

// ---------------- Loop ----------------
void loop() {
  long weight = scale.get_units(5);
  float temp = dht.readTemperature();
  float hum = dht.readHumidity();

  String prediction = "no_child";
  bool alert = false;

  if (weight > 5.0) { // Child candidate
    Serial.println("Weight detected, running AI check...");
    prediction = classifyImage();

    if (prediction == "child" && temp > 30.0) {
      alert = true;
      sendSMS("⚠ ALERT: Child detected! Temp is above 30C!");
    }
  }

  // Always send live data to app
  sendToApp(temp, hum, weight, prediction, alert);

  delay(10000); // Update every 10 sec
}
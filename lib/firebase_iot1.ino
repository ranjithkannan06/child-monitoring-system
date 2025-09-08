#include <WiFi.h>
#include <HTTPClient.h>
#include <HX711.h>
#include <DHT.h>
#include <ArduinoJson.h>

// WiFi credentials
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// Firebase configuration
const char* firebaseHost = "YOUR_FIREBASE_PROJECT_ID.firebaseio.com";
const char* firebaseAuth = "YOUR_FIREBASE_DATABASE_SECRET";
const char* firebasePath = "/car_monitoring.json?auth=";

// Sensor Pins
#define DHTPIN 14
#define DHTTYPE DHT22
#define LOADCELL_DOUT_PIN 4
#define LOADCELL_SCK_PIN 15

// Initialize sensors
DHT dht(DHTPIN, DHTTYPE);
HX711 scale;

// Variables
unsigned long lastUpdateTime = 0;
const long updateInterval = 10000; // Update every 10 seconds

void setup() {
  Serial.begin(115200);
  
  // Initialize WiFi
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nConnected to WiFi");
  
  // Initialize sensors
  dht.begin();
  scale.begin(LOADCELL_DOUT_PIN, LOADCELL_SCK_PIN);
  scale.set_scale();
  scale.tare();
  
  Serial.println("Initialization complete");
}

void loop() {
  if (millis() - lastUpdateTime >= updateInterval) {
    lastUpdateTime = millis();
    
    // Read sensor data
    float temperature = dht.readTemperature();
    float humidity = dht.readHumidity();
    float weight = scale.get_units(5); // Average of 5 readings
    
    // Check if weight is valid (above noise threshold)
    bool hasWeight = weight > 0.5; // 0.5kg threshold
    
    // Simple AI prediction (replace with your actual AI logic)
    String aiResult = "no_child";
    if (hasWeight) {
      aiResult = "child";
    }
    
    // Check for alert condition
    bool alert = (aiResult == "child" && temperature > 30.0);
    
    // Create JSON payload
    DynamicJsonDocument doc(512);
    doc["temperature"] = temperature;
    doc["humidity"] = humidity;
    doc["weight"] = weight;
    doc["ai_result"] = aiResult;
    doc["alert"] = alert;
    doc["timestamp"] = millis();
    
    // Convert to JSON string
    String jsonData;
    serializeJson(doc, jsonData);
    
    // Send to Firebase
    if (WiFi.status() == WL_CONNECTED) {
      sendToFirebase(jsonData);
    } else {
      Serial.println("WiFi not connected. Attempting to reconnect...");
      WiFi.reconnect();
    }
    
    // Print to serial for debugging
    Serial.print("Data sent: ");
    serializeJson(doc, Serial);
    Serial.println();
  }
}

void sendToFirebase(String jsonData) {
  HTTPClient http;
  
  // Construct Firebase URL
  String url = "https://" + String(firebaseHost) + firebasePath + String(firebaseAuth);
  
  // Send POST request to Firebase
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  
  // Use POST to create a new entry with auto-generated key
  int httpResponseCode = http.POST(jsonData);
  
  if (httpResponseCode > 0) {
    String response = http.getString();
    Serial.print("Firebase response: ");
    Serial.println(response);
  } else {
    Serial.print("Error on sending POST: ");
    Serial.println(httpResponseCode);
  }
  
  http.end();
}

#include "esp_camera.h"
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <base64.h>
#include "soc/soc.h"
#include "soc/rtc_cntl_reg.h"

// Use camera model and pins from board_config.h
#include "board_config.h"

// LED Flash pin definition for AI-Thinker
#define LED_FLASH_PIN 4

// WiFi credentials
const char *ssid = "Redmi";
const char *password = "ranjith@123";

// Gemini API configuration
const char *geminiApiKey = "AIzaSyCTHAQEijXm53a2TsIcQO1NXDdc6gXMsd4"; // Replace with your actual API key
const char *geminiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent";

void startCameraServer();

void captureAndAnalyzeImage();
String sendToGemini(String base64Image);
void controlFlashLED(bool state);

void setup() {
  // Disable brownout detector
  WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0);

  Serial.begin(115200);
  Serial.setDebugOutput(true);
  Serial.println();

  // Initialize Flash LED - Turn ON Always
  pinMode(LED_FLASH_PIN, OUTPUT);
  digitalWrite(LED_FLASH_PIN, LOW); // Turn flash LED ON permanently
  Serial.println("Flash LED turned ON permanently"); add_log("Flash LED ON permanently");
  Serial.println("WARNING: Flash LED will get very hot. Monitor device temperature!");

  // Camera configuration
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sccb_sda = SIOD_GPIO_NUM;
  config.pin_sccb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.frame_size = FRAMESIZE_SVGA; // Reduced for better performance
  config.pixel_format = PIXFORMAT_JPEG;
  config.grab_mode = CAMERA_GRAB_WHEN_EMPTY;
  config.fb_location = CAMERA_FB_IN_PSRAM;
  config.jpeg_quality = 15; // Lower quality for smaller size
  config.fb_count = 1;

  // PSRAM optimization
  if (config.pixel_format == PIXFORMAT_JPEG) {
    if (psramFound()) {
      config.jpeg_quality = 12;
      config.fb_count = 2;
      config.grab_mode = CAMERA_GRAB_LATEST;
    } else {
      config.frame_size = FRAMESIZE_SVGA;
      config.fb_location = CAMERA_FB_IN_DRAM;
    }
  }

  // Initialize camera
  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Camera init failed with error 0x%x", err);
    add_log("Camera init failed");
    return;
  }

  sensor_t *s = esp_camera_sensor_get();
  if (s->id.PID == OV3660_PID) {
    s->set_vflip(s, 1);
    s->set_brightness(s, 1);
    s->set_saturation(s, -2);
  }

  // WiFi connection
  WiFi.begin(ssid, password);
  WiFi.setSleep(false);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("");
  Serial.println("WiFi connected");
  add_log("WiFi connected");

  startCameraServer();
  Serial.print("Camera Ready! Use 'http://");
  Serial.print(WiFi.localIP());
  Serial.println("' to connect");
  add_log("Camera server ready");
}

void loop() {
  // Capture and analyze image every 30 seconds
  static unsigned long lastCapture = 0;
  if (millis() - lastCapture > 30000) {
    captureAndAnalyzeImage();
    lastCapture = millis();
  }
  delay(1000);
}

void captureAndAnalyzeImage() {
  Serial.println("Capturing image with flash LED ON...");
  add_log("Capture start");

  // Take a photo with flash LED already ON
  camera_fb_t *fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println("Camera capture failed");
    add_log("Capture failed");
    return;
  }

  // Convert to base64
  String imageBase64 = base64::encode(fb->buf, fb->len);
  size_t imageSize = fb->len;
  esp_camera_fb_return(fb);

  Serial.printf("Image captured, size: %d bytes, base64 length: %d\n", (int)imageSize, (int)imageBase64.length());

  // Send to Gemini API
  String result = sendToGemini(imageBase64);
  Serial.println("Gemini Response: " + result);
  add_log((String)"Gemini: " + result);
}

String sendToGemini(String base64Image) {
  if (WiFi.status() != WL_CONNECTED) {
    return "WiFi not connected";
  }

  HTTPClient http;
  http.begin(String(geminiEndpoint) + "?key=" + String(geminiApiKey));
  http.addHeader("Content-Type", "application/json");
  http.setTimeout(30000); // 30 second timeout

  // Create JSON payload for child detection
  DynamicJsonDocument doc(8192);
  JsonArray contents = doc.createNestedArray("contents");
  JsonObject content = contents.createNestedObject();
  JsonArray parts = content.createNestedArray("parts");

  // Add text prompt
  JsonObject textPart = parts.createNestedObject();
  textPart["text"] = "Analyze this image carefully and determine if there is a child (person under 18 years old) present in the image. Respond with only 'CHILD PRESENT' if you detect a child, or 'NO CHILD' if no child is detected. Be very specific and accurate in your detection.";

  // Add image data
  JsonObject imagePart = parts.createNestedObject();
  JsonObject inlineData = imagePart.createNestedObject("inline_data");
  inlineData["mime_type"] = "image/jpeg";
  inlineData["data"] = base64Image;

  // Safety settings for child detection
  JsonArray safetySettings = doc.createNestedArray("safetySettings");
  JsonObject safety1 = safetySettings.createNestedObject();
  safety1["category"] = "HARM_CATEGORY_HARASSMENT";
  safety1["threshold"] = "BLOCK_NONE";

  JsonObject safety2 = safetySettings.createNestedObject();
  safety2["category"] = "HARM_CATEGORY_HATE_SPEECH";
  safety2["threshold"] = "BLOCK_NONE";

  String jsonString;
  serializeJson(doc, jsonString);

  Serial.println("Sending request to Gemini API...");
  int httpResponseCode = http.POST(jsonString);
  String response = "";

  if (httpResponseCode > 0) {
    response = http.getString();
    Serial.printf("HTTP Response code: %d\n", httpResponseCode);

    // Parse response
    DynamicJsonDocument responseDoc(4096);
    DeserializationError err = deserializeJson(responseDoc, response);
    if (err) {
      http.end();
      return String("Parse error: ") + err.c_str();
    }

    if (responseDoc.containsKey("candidates")) {
      JsonArray candidates = responseDoc["candidates"];
      if (candidates.size() > 0) {
        JsonObject candidate = candidates[0];
        if (candidate.containsKey("content")) {
          JsonObject content = candidate["content"];
          if (content.containsKey("parts")) {
            JsonArray parts = content["parts"];
            if (parts.size() > 0) {
              JsonObject part = parts[0];
              if (part.containsKey("text")) {
                String detectionResult = part["text"].as<String>();
                detectionResult.trim();
                http.end();
                return detectionResult;
              }
            }
          }
        }
      }
    } else if (responseDoc.containsKey("error")) {
      JsonObject error = responseDoc["error"];
      String errorMessage = error["message"].as<String>();
      http.end();
      return "Error: " + errorMessage;
    }
  } else {
    String errMsg = String("HTTP Error: ") + String(httpResponseCode);
    http.end();
    return errMsg;
  }

  http.end();
  return response;
}

// Optional function to turn LED ON/OFF manually
void controlFlashLED(bool state) {
  digitalWrite(LED_FLASH_PIN, state ? HIGH : LOW);
  Serial.println(state ? "Flash LED turned ON" : "Flash LED turned OFF");
}

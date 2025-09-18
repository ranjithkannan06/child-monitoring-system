#ifndef APP_CONFIG_H
#define APP_CONFIG_H

// WiFi Configuration
#define WIFI_SSID "Redmi note 13 pro"
#define WIFI_PASSWORD "your_wifi_password"

// Server Configuration
#define SERVER_API_URL "https://your-server.com/update"

// Roboflow Configuration
#define ROBOFLOW_API_KEY "your_roboflow_api_key"
#define ROBOFLOW_MODEL_URL "https://detect.roboflow.com/child-monitoring/1"

// Emergency Contacts (comma-separated with country code, no + or 00)
#define EMERGENCY_NUMBERS "911,1234567890"

// Alert Thresholds
#define TEMP_ALERT_THRESHOLD 30.0  // °C
#define WEIGHT_THRESHOLD 5.0       // kg

// Pin Definitions
#define LOADCELL_DOUT_PIN 4
#define LOADCELL_SCK_PIN 15
#define DHT_PIN 14
#define GSM_RX 16
#define GSM_TX 17

// Update Intervals (milliseconds)
#define SENSOR_UPDATE_INTERVAL 10000  // 10 seconds
#define CAMERA_CHECK_INTERVAL 300000  // 5 minutes

#endif // APP_CONFIG_H

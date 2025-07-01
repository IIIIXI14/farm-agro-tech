#include <ESP8266WiFi.h>
#include <FirebaseESP8266.h>
#include <DHT.h>
#include <NTPClient.h>
#include <WiFiUdp.h>
#include <ArduinoJson.h>

// ----------------------- 🔧 Configuration -----------------------
#define WIFI_SSID "AirFiber-zeo6Da"
#define WIFI_PASSWORD "zeo6Dein0aichaa2"
#define FIREBASE_HOST "farmagrotech-7a3cf.firebaseio.com"
#define FIREBASE_AUTH "AIzaSyBlgom7hmUl3bclgcI7Byu1INlhqk3Eafo"

#define DHTPIN D4
#define DHTTYPE DHT11
#define RELAY_MOTOR D5

String deviceId = "device_001";
String userId = "6k7g4heczJTxvAAZMLD4PEDmL482";

// Declare function used later in checkAutomationRules
void setActuatorState(bool state, unsigned long duration = 0, String source = "manual");

// ----------------------- 📡 Firebase + NTP -----------------------
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org");

// ----------------------- 🌡️ DHT Sensor -----------------------
DHT dht(DHTPIN, DHTTYPE);

// ----------------------- 🔁 Timers -----------------------
#define SENSOR_UPDATE_INTERVAL 60000       // 1 min
#define HISTORY_UPDATE_INTERVAL 300000     // 5 mins
#define SCHEDULE_CHECK_INTERVAL 30000      // 30s
#define AUTOMATION_CHECK_INTERVAL 10000    // 10s
#define DURATION_CHECK_INTERVAL 1000       // 1s
#define SENSOR_RETRY_INTERVAL 5000         // 5s for sensor retry
#define FIREBASE_RETRY_INTERVAL 30000      // 30s for Firebase retry

unsigned long lastSensorUpdate = 0;
unsigned long lastHistoryUpdate = 0;
unsigned long lastScheduleCheck = 0;
unsigned long lastAutomationCheck = 0;
unsigned long lastDurationCheck = 0;
unsigned long lastSensorRetry = 0;
unsigned long lastFirebaseRetry = 0;

// ----------------------- ⚙️ Actuator State -----------------------
struct ActuatorState {
  bool isOn;
  unsigned long startTime;
  unsigned long duration;  // in ms
  bool isTestMode;
  String triggerSource;
};

ActuatorState motor = {false, 0, 0, false, ""};

// ----------------------- 📊 Sensor State -----------------------
struct SensorState {
  float temperature;
  float humidity;
  bool isValid;
  unsigned long lastValidRead;
  int consecutiveFailures;
};

SensorState sensor = {0, 0, false, 0, 0};

// ----------------------- 🔗 Connection State -----------------------
bool firebaseConnected = false;
int firebaseRetryCount = 0;

// ----------------------- 📝 Logging Functions -----------------------
void logActuatorTrigger(bool state, String source) {
  if (!firebaseConnected) {
    Serial.println("⚠️  Firebase not connected, skipping trigger log");
    return;
  }
  
  FirebaseJson json;
  json.set("actuator", "motor");
  json.set("state", state ? "ON" : "OFF");
  json.set("source", source);
  json.set("temperature", sensor.temperature);
  json.set("humidity", sensor.humidity);
  json.set("timestamp", "/.sv/timestamp");
  
  if (Firebase.pushJSON(fbdo, "/users/" + userId + "/devices/" + deviceId + "/triggerLog", json)) {
    Serial.println("📝 motor " + String(state ? "ON" : "OFF") + " by " + source);
  } else {
    Serial.println("❌ Failed to log trigger to Firebase");
  }
}

void logAutomationEvent(String condition, String operator, float threshold, float currentValue, bool triggered) {
  if (!firebaseConnected) {
    Serial.println("⚠️  Firebase not connected, skipping automation log");
    return;
  }
  
  FirebaseJson json;
  json.set("actuator", "motor");
  json.set("condition", condition);
  json.set("operator", operator);
  json.set("threshold", threshold);
  json.set("currentValue", currentValue);
  json.set("triggered", triggered);
  json.set("timestamp", "/.sv/timestamp");
  
  if (Firebase.pushJSON(fbdo, "/users/" + userId + "/devices/" + deviceId + "/automationLog", json)) {
    Serial.println("📊 motor " + condition + " " + operator + " " + String(threshold) +
                  " (Current: " + String(currentValue) + ") -> " + String(triggered ? "TRIGGERED" : "No action"));
  } else {
    Serial.println("❌ Failed to log automation event to Firebase");
  }
}

void printActuatorStatus() {
  String status = motor.isOn ? "🟢 ON" : "🔴 OFF";
  String source = motor.triggerSource;
  String duration = motor.duration > 0 ? " (Duration: " + String(motor.duration/1000) + "s)" : "";
  String testMode = motor.isTestMode ? " [TEST]" : "";
  Serial.println("🎛️  Motor: " + status + " by " + source + duration + testMode);
}

void updateActuatorState() {
  if (!firebaseConnected) {
    Serial.println("⚠️  Firebase not connected, skipping actuator state update");
    return;
  }
  
  FirebaseJson stateJson;
  stateJson.set("isOn", motor.isOn);
  stateJson.set("duration", motor.duration);
  stateJson.set("remainingTime", motor.duration > 0 ? max(0L, (long)(motor.duration - (millis() - motor.startTime))) : 0);
  stateJson.set("isTestMode", motor.isTestMode);
  stateJson.set("triggerSource", motor.triggerSource);
  FirebaseJson json;
  json.set("motor", stateJson);
  
  if (Firebase.setJSON(fbdo, "/users/" + userId + "/devices/" + deviceId + "/actuatorStates", json)) {
    // Success
  } else {
    Serial.println("❌ Failed to update actuator state in Firebase");
  }
}

// ----------------------- 🌡️ Sensor Functions -----------------------
bool readSensor() {
  float temp = dht.readTemperature();
  float hum = dht.readHumidity();
  
  // Check if readings are valid
  if (isnan(temp) || isnan(hum) || temp < -40 || temp > 80 || hum < 0 || hum > 100) {
    sensor.consecutiveFailures++;
    Serial.println("❌ Sensor read failed (Attempt " + String(sensor.consecutiveFailures) + ")");
    
    // If too many failures, mark sensor as invalid
    if (sensor.consecutiveFailures > 5) {
      sensor.isValid = false;
      Serial.println("⚠️  Sensor marked as invalid after multiple failures");
    }
    return false;
  }
  
  // Valid reading
  sensor.temperature = temp;
  sensor.humidity = hum;
  sensor.isValid = true;
  sensor.lastValidRead = millis();
  sensor.consecutiveFailures = 0;
  
  Serial.println("✅ Sensor read successful: " + String(temp, 1) + "°C, " + String(hum, 1) + "%");
  return true;
}

// ----------------------- 🔗 Connection Functions -----------------------
bool connectToFirebase() {
  Serial.println("🔗 Attempting to connect to Firebase...");
  
  config.host = FIREBASE_HOST;
  config.signer.tokens.legacy_token = FIREBASE_AUTH;
  
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  
  // Test connection
  if (Firebase.setString(fbdo, "/users/" + userId + "/devices/" + deviceId + "/status", "online")) {
    firebaseConnected = true;
    firebaseRetryCount = 0;
    Serial.println("✅ Firebase connected successfully");
    return true;
  } else {
    firebaseConnected = false;
    firebaseRetryCount++;
    Serial.println("❌ Firebase connection failed (Attempt " + String(firebaseRetryCount) + ")");
    return false;
  }
}

// ----------------------- 🚀 Setup -----------------------
void setup() {
  Serial.begin(115200);
  Serial.println("🚀 Day 11: Smart Automation Engine Starting...");
  Serial.println("🎯 ESP8266 Farm Control with Firestore Automation");
  Serial.println("📡 Connecting to WiFi and Firebase...");
  
  // Initialize sensor
  dht.begin();
  delay(2000); // Give DHT11 time to stabilize
  
  // Initialize relay
  pinMode(RELAY_MOTOR, OUTPUT);
  digitalWrite(RELAY_MOTOR, LOW);
  
  // Connect to WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("📡 Connecting WiFi");
  int wifiAttempts = 0;
  while (WiFi.status() != WL_CONNECTED && wifiAttempts < 20) {
    Serial.print(".");
    delay(500);
    wifiAttempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi connected");
    Serial.println("📶 IP: " + WiFi.localIP().toString());
  } else {
    Serial.println("\n❌ WiFi connection failed");
    ESP.restart();
  }
  
  // Initialize NTP
  timeClient.begin();
  timeClient.setTimeOffset(19800); // +5:30 IST
  
  // Connect to Firebase
  if (connectToFirebase()) {
    Serial.println("✅ Day 11 Automation Engine Ready!");
  } else {
    Serial.println("⚠️  Firebase connection failed, continuing with limited functionality");
  }
  
  Serial.println("🎛️  Actuator: Motor (D5)");
  Serial.println("📊 Sensor: DHT11 on D4");
  Serial.println("🔄 Automation check every 10 seconds");
  Serial.println("📝 Logging all triggers to Firebase");
  Serial.println("---");
  
  // Initial sensor read
  if (readSensor()) {
    Serial.println("✅ Initial sensor read successful");
  } else {
    Serial.println("⚠️  Initial sensor read failed, will retry");
  }
}

// ----------------------- 🔁 Main Loop -----------------------
void loop() {
  unsigned long now = millis();
  
  // Sensor retry logic
  if (!sensor.isValid && now - lastSensorRetry >= SENSOR_RETRY_INTERVAL) {
    readSensor();
    lastSensorRetry = now;
  }
  
  // Firebase retry logic
  if (!firebaseConnected && now - lastFirebaseRetry >= FIREBASE_RETRY_INTERVAL) {
    connectToFirebase();
    lastFirebaseRetry = now;
  }
  
  // Regular intervals
  if (now - lastSensorUpdate >= SENSOR_UPDATE_INTERVAL) {
    if (readSensor()) {
      updateSensorData();
    }
    lastSensorUpdate = now;
  }
  
  if (now - lastHistoryUpdate >= HISTORY_UPDATE_INTERVAL) {
    if (sensor.isValid) {
      updateHistoricalData();
    }
    lastHistoryUpdate = now;
  }
  
  if (now - lastScheduleCheck >= SCHEDULE_CHECK_INTERVAL) {
    checkSchedule();
    checkTestModeUpdate();
    lastScheduleCheck = now;
  }
  
  if (now - lastAutomationCheck >= AUTOMATION_CHECK_INTERVAL) {
    if (sensor.isValid) {
      checkAutomationRule();
    } else {
      Serial.println("⚠️  Skipping automation check - sensor not valid");
    }
    lastAutomationCheck = now;
  }
  
  if (now - lastDurationCheck >= DURATION_CHECK_INTERVAL) {
    checkDuration();
    lastDurationCheck = now;
  }
  
  checkActuatorUpdate();
  
  // Small delay to prevent watchdog issues
  delay(100);
}

// ----------------------- 🌡️ Sensor Update -----------------------
void updateSensorData() {
  if (!sensor.isValid) {
    Serial.println("⚠️  Cannot update sensor data - sensor not valid");
    return;
  }
  
  FirebaseJson json;
  json.set("temperature", sensor.temperature);
  json.set("humidity", sensor.humidity);
  json.set("timestamp", "/.sv/timestamp");
  
  if (firebaseConnected && Firebase.setJSON(fbdo, "/users/" + userId + "/devices/" + deviceId + "/sensorData", json)) {
    Serial.println("📊 Sensor data updated: " + String(sensor.temperature, 1) + "°C, " + String(sensor.humidity, 1) + "%");
  } else {
    Serial.println("❌ Failed to update sensor data in Firebase");
  }
}

void updateHistoricalData() {
  if (!sensor.isValid) return;
  
  FirebaseJson json;
  json.set("temperature", sensor.temperature);
  json.set("humidity", sensor.humidity);
  json.set("timestamp", "/.sv/timestamp");
  
  if (firebaseConnected) {
    Firebase.pushJSON(fbdo, "/users/" + userId + "/devices/" + deviceId + "/history", json);
  }
}

// ----------------------- 🕒 Automation Rule -----------------------
void checkAutomationRule() {
  if (!sensor.isValid) {
    Serial.println("❌ Cannot check automation - sensor not valid");
    return;
  }
  
  if (!firebaseConnected) {
    Serial.println("⚠️  Cannot check automation - Firebase not connected");
    return;
  }
  
  String path = "/users/" + userId + "/devices/" + deviceId + "/automationRules";
  if (!Firebase.getJSON(fbdo, path)) {
    Serial.println("❌ Failed to fetch automation rules");
    return;
  }
  
  Serial.println("🔄 Checking automation rule...");
  Serial.println("📊 Current: Temp=" + String(sensor.temperature, 1) + "°C, Humidity=" + String(sensor.humidity, 1) + "%");
  
  FirebaseJson* json = fbdo.jsonObjectPtr();
  FirebaseJsonData result;
  
  if (json->get(result, "motor")) {
    FirebaseJson ruleJson;
    ruleJson.setJsonData(result.stringValue);
    
    ruleJson.get(result, "when");
    String cond = result.stringValue;
    float sensorValue = (cond == "temperature") ? sensor.temperature : sensor.humidity;
    
    ruleJson.get(result, "operator");
    String op = result.stringValue;
    
    ruleJson.get(result, "value");
    float threshold = result.floatValue;
    
    ruleJson.get(result, "duration");
    unsigned long dur = result.success ? result.intValue * 1000 : 0;
    
    bool trigger = (op == ">" && sensorValue > threshold) ||
                   (op == "<" && sensorValue < threshold) ||
                   (op == ">=" && sensorValue >= threshold) ||
                   (op == "<=" && sensorValue <= threshold) ||
                   (op == "==" && abs(sensorValue - threshold) < 0.1);
    
    if (!motor.isTestMode) {
      setActuatorState(trigger, dur, "automation");
      logAutomationEvent(cond, op, threshold, sensorValue, trigger);
    } else {
      Serial.println("🧪 motor skipped (test mode active)");
    }
    
    Serial.println("🔍 Rule: motor (" + cond + " " + op + " " + String(threshold) + (cond == "temperature" ? "°C" : "%") + ")");
    Serial.println("   📊 Current: " + String(sensorValue, 1) + (cond == "temperature" ? "°C" : "%"));
    Serial.println("   ⚡ Action: " + String(trigger ? "🟢 ON" : "🔴 OFF") + (dur > 0 ? " (Duration: " + String(dur/1000) + "s)" : ""));
  }
  
  updateActuatorState();
  printActuatorStatus();
}

// ----------------------- 🧠 Actuator State -----------------------
void setActuatorState(bool state, unsigned long duration, String source) {
  // Only change state if it's different or if turning ON
  if (motor.isOn != state || state) {
    digitalWrite(RELAY_MOTOR, state ? HIGH : LOW);
    motor.isOn = state;
    motor.startTime = state ? millis() : 0;
    motor.duration = duration;
    motor.isTestMode = false;
    motor.triggerSource = source;
    
    logActuatorTrigger(state, source);
    
    if (firebaseConnected && Firebase.setBool(fbdo, "/users/" + userId + "/devices/" + deviceId + "/actuators/motor", state)) {
      Serial.println("🚦 motor => " + String(state ? "ON" : "OFF") + " (Source: " + source + (duration > 0 ? ", Duration: " + String(duration/1000) + "s" : "") + ")");
    } else {
      Serial.println("⚠️  Failed to update actuator state in Firebase");
    }
  }
}

// ----------------------- ⏱️ Duration Timeout -----------------------
void checkDuration() {
  unsigned long now = millis();
  if (motor.isOn && motor.duration > 0 && now - motor.startTime >= motor.duration) {
    setActuatorState(false, 0, motor.triggerSource + "_timeout");
  }
}

// ----------------------- 🕒 Scheduling -----------------------
void checkSchedule() {
  if (!firebaseConnected) return;
  
  String path = "/users/" + userId + "/devices/" + deviceId + "/schedules";
  if (!Firebase.getJSON(fbdo, path)) return;
  
  FirebaseJson* json = fbdo.jsonObjectPtr();
  FirebaseJsonData result;
  
  if (json->get(result, "motor")) {
    FirebaseJson schedJson;
    schedJson.setJsonData(result.stringValue);
    
    schedJson.get(result, "isActive");
    if (!result.boolValue) return;
    
    schedJson.get(result, "actuator");
    String name = result.stringValue;
    
    schedJson.get(result, "value");
    bool state = result.boolValue;
    
    schedJson.get(result, "startTime");
    int start = result.intValue;
    
    schedJson.get(result, "endTime");
    int end = result.intValue;
    
    timeClient.update();
    int nowSec = timeClient.getHours() * 3600 + timeClient.getMinutes() * 60 + timeClient.getSeconds();
    
    if (nowSec >= start && nowSec <= end) {
      setActuatorState(state, 0, "schedule");
    }
  }
}

// ----------------------- ⚙️ Test Mode & Manual -----------------------
void checkTestModeUpdate() {
  if (!firebaseConnected) return;
  
  String path = "/users/" + userId + "/devices/" + deviceId + "/testMode";
  if (!Firebase.getJSON(fbdo, path)) return;
  
  FirebaseJson* json = fbdo.jsonObjectPtr();
  FirebaseJsonData result;
  
  if (json->get(result, "motor")) {
    bool newTestMode = result.boolValue;
    if (newTestMode != motor.isTestMode) {
      motor.isTestMode = newTestMode;
      Serial.println("🧪 motor test mode: " + String(newTestMode ? "ON" : "OFF"));
    }
  }
}

void checkActuatorUpdate() {
  if (!firebaseConnected) return;
  
  String path = "/users/" + userId + "/devices/" + deviceId + "/actuators";
  if (!Firebase.getJSON(fbdo, path)) return;
  
  FirebaseJson* json = fbdo.jsonObjectPtr();
  FirebaseJsonData result;
  
  if (json->get(result, "motor") && result.boolValue != motor.isOn) {
    setActuatorState(result.boolValue, 0, "manual");
  }
}

// ----------------------- 🧪 Test Function -----------------------
void testAutomationSystem() {
  Serial.println("🧪 Testing Automation System...");
  Serial.println("Testing motor...");
  setActuatorState(true, 2000, "test"); // 2 seconds
  delay(2500);
  Serial.println("✅ Automation test complete!");
} 
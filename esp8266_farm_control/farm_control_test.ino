#include <ESP8266WiFi.h>
#include <FirebaseESP8266.h>
#include <DHT.h>

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

// ----------------------- 📡 Firebase + DHT -----------------------
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
DHT dht(DHTPIN, DHTTYPE);

// ----------------------- 📊 Test Variables -----------------------
int testCounter = 0;
bool firebaseConnected = false;

// ----------------------- 🌡️ Improved Sensor Read -----------------------
bool readSensorWithRetry() {
  Serial.println("🔍 Attempting to read sensor...");
  
  for (int attempt = 1; attempt <= 5; attempt++) {
    Serial.print("   Attempt " + String(attempt) + ": ");
    
    // Read sensor
    float temp = dht.readTemperature();
    float hum = dht.readHumidity();
    
    // Validate readings
    if (!isnan(temp) && !isnan(hum) && temp > -40 && temp < 80 && hum >= 0 && hum <= 100) {
      Serial.println("✅ Success! Temp: " + String(temp, 1) + "°C, Humidity: " + String(hum, 1) + "%");
      
      // Update Firebase if connected
      if (firebaseConnected) {
        FirebaseJson json;
        json.set("temperature", temp);
        json.set("humidity", hum);
        json.set("timestamp", "/.sv/timestamp");
        
        if (Firebase.setJSON(fbdo, "/users/" + userId + "/devices/" + deviceId + "/sensorData", json)) {
          Serial.println("📊 Data sent to Firebase successfully");
        } else {
          Serial.println("❌ Failed to send data to Firebase");
        }
      }
      
      return true;
    } else {
      Serial.println("❌ Failed (Temp: " + String(temp) + ", Hum: " + String(hum) + ")");
      delay(1000); // Wait 1 second between attempts
    }
  }
  
  Serial.println("❌ All sensor read attempts failed");
  return false;
}

// ----------------------- 🔗 Firebase Connection -----------------------
bool connectToFirebase() {
  Serial.println("🔗 Testing Firebase connection...");
  
  config.host = FIREBASE_HOST;
  config.signer.tokens.legacy_token = FIREBASE_AUTH;
  
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  
  // Test with a simple write
  if (Firebase.setString(fbdo, "/users/" + userId + "/devices/" + deviceId + "/status", "testing")) {
    firebaseConnected = true;
    Serial.println("✅ Firebase connection successful");
    return true;
  } else {
    firebaseConnected = false;
    Serial.println("❌ Firebase connection failed: " + fbdo.errorReason());
    return false;
  }
}

// ----------------------- 🚀 Setup -----------------------
void setup() {
  Serial.begin(115200);
  Serial.println("\n🚀 Day 11 Test Mode Starting...");
  Serial.println("🎯 Testing Sensor and Firebase Connection");
  Serial.println("==========================================");
  
  // Initialize sensor with longer delay
  Serial.println("📡 Initializing DHT11 sensor...");
  dht.begin();
  delay(3000); // Give sensor more time to stabilize
  Serial.println("✅ DHT11 initialized");
  
  // Initialize relay
  pinMode(RELAY_MOTOR, OUTPUT);
  digitalWrite(RELAY_MOTOR, LOW);
  Serial.println("✅ Relay initialized");
  
  // Connect to WiFi
  Serial.println("📡 Connecting to WiFi...");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  int wifiAttempts = 0;
  while (WiFi.status() != WL_CONNECTED && wifiAttempts < 30) {
    Serial.print(".");
    delay(500);
    wifiAttempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi connected successfully");
    Serial.println("📶 IP Address: " + WiFi.localIP().toString());
    Serial.println("📶 Signal Strength: " + String(WiFi.RSSI()) + " dBm");
  } else {
    Serial.println("\n❌ WiFi connection failed");
    Serial.println("🔧 Please check your WiFi credentials");
    return;
  }
  
  // Test Firebase connection
  if (connectToFirebase()) {
    Serial.println("✅ Firebase connection test passed");
  } else {
    Serial.println("⚠️  Firebase connection failed, continuing with sensor test only");
  }
  
  Serial.println("\n🧪 Starting sensor test...");
  Serial.println("==========================================");
}

// ----------------------- 🔁 Main Loop -----------------------
void loop() {
  testCounter++;
  Serial.println("\n🔄 Test Cycle #" + String(testCounter));
  Serial.println("------------------------------------------");
  
  // Test sensor reading
  if (readSensorWithRetry()) {
    Serial.println("✅ Sensor test PASSED");
  } else {
    Serial.println("❌ Sensor test FAILED");
  }
  
  // Test relay
  Serial.println("🧪 Testing relay...");
  digitalWrite(RELAY_MOTOR, HIGH);
  Serial.println("   Relay ON");
  delay(1000);
  digitalWrite(RELAY_MOTOR, LOW);
  Serial.println("   Relay OFF");
  Serial.println("✅ Relay test completed");
  
  // Test Firebase if connected
  if (firebaseConnected) {
    Serial.println("🧪 Testing Firebase...");
    FirebaseJson testJson;
    testJson.set("testCounter", testCounter);
    testJson.set("timestamp", "/.sv/timestamp");
    
    if (Firebase.pushJSON(fbdo, "/users/" + userId + "/devices/" + deviceId + "/testLog", testJson)) {
      Serial.println("✅ Firebase test PASSED");
    } else {
      Serial.println("❌ Firebase test FAILED: " + fbdo.errorReason());
    }
  }
  
  Serial.println("⏰ Waiting 10 seconds before next test...");
  Serial.println("==========================================");
  delay(10000);
}

// ----------------------- 🆘 Emergency Functions -----------------------
void emergencyStop() {
  Serial.println("🚨 EMERGENCY STOP ACTIVATED");
  digitalWrite(RELAY_MOTOR, LOW);
  Serial.println("✅ All actuators turned OFF");
}

// ----------------------- 📊 Status Functions -----------------------
void printSystemStatus() {
  Serial.println("\n📊 System Status:");
  Serial.println("   WiFi: " + String(WiFi.status() == WL_CONNECTED ? "Connected" : "Disconnected"));
  Serial.println("   IP: " + WiFi.localIP().toString());
  Serial.println("   Firebase: " + String(firebaseConnected ? "Connected" : "Disconnected"));
  Serial.println("   Test Cycles: " + String(testCounter));
} 
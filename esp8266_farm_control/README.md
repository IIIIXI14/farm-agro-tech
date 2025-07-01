# 🚀 ESP8266 Farm Control - Day 11: Smart Automation Engine

## 🎯 Overview

This ESP8266-based farm control system now features a **Smart Automation Engine** that automatically controls actuators based on sensor readings and rules stored in Firebase Firestore. The system can operate completely autonomously without manual intervention.

## 🔧 Hardware Setup

### Required Components
- ESP8266 NodeMCU or Wemos D1 Mini
- DHT11 Temperature & Humidity Sensor
- 4-Channel Relay Module (5V)
- Power Supply (5V/2A recommended)
- Connecting wires

### Pin Connections
```
ESP8266 Pin    →    Component
D4             →    DHT11 Data
D5             →    Motor Relay
D6             →    Water Pump Relay  
D7             →    Light Relay
D8             →    Siren Relay
3.3V           →    DHT11 VCC
5V             →    Relay Module VCC
GND            →    DHT11 GND + Relay Module GND
```

## 🌐 Firestore Structure

The automation system uses this Firestore structure:

```json
/users/{UID}/devices/{DEVICE_ID}/
{
  "sensorData": {
    "temperature": 25.6,
    "humidity": 65.4
  },
  "actuators": {
    "motor": false,
    "water": false,
    "light": false,
    "siren": false
  },
  "automationRules": {
    "motor": {
      "when": "temperature",
      "operator": ">",
      "value": 35,
      "duration": 300
    },
    "water": {
      "when": "humidity", 
      "operator": "<",
      "value": 40
    }
  },
  "actuatorStates": {
    "motor": {
      "isOn": true,
      "duration": 300000,
      "remainingTime": 250000,
      "isTestMode": false,
      "triggerSource": "automation"
    }
  },
  "triggerLog": [
    {
      "actuator": "motor",
      "state": "ON",
      "source": "automation",
      "temperature": 36.2,
      "humidity": 45.1,
      "timestamp": "2024-01-15T10:30:00Z"
    }
  ],
  "automationLog": [
    {
      "actuator": "motor",
      "condition": "temperature",
      "operator": ">",
      "threshold": 35,
      "currentValue": 36.2,
      "triggered": true,
      "timestamp": "2024-01-15T10:30:00Z"
    }
  ],
  "status": "online"
}
```

## 🔄 Automation Rules

### Rule Structure
Each automation rule has these properties:
- `when`: Sensor to monitor ("temperature" or "humidity")
- `operator`: Comparison operator (">", "<", ">=", "<=", "==")
- `value`: Threshold value (float)
- `duration`: Optional auto-off duration in seconds

### Supported Operators
- `>`: Greater than
- `<`: Less than  
- `>=`: Greater than or equal
- `<=`: Less than or equal
- `==`: Equal to (with 0.1 tolerance)

### Example Rules

**Temperature-based motor control:**
```json
{
  "motor": {
    "when": "temperature",
    "operator": ">",
    "value": 35,
    "duration": 300
  }
}
```
*Turns motor ON when temperature > 35°C for 5 minutes*

**Humidity-based watering:**
```json
{
  "water": {
    "when": "humidity",
    "operator": "<",
    "value": 40
  }
}
```
*Turns water pump ON when humidity < 40% (stays on until condition changes)*

## ⚙️ System Features

### 🔄 Automatic Operation
- Checks automation rules every 10 seconds
- Compares sensor readings with thresholds
- Automatically activates/deactivates actuators
- Logs all actions to Firebase

### 📊 Comprehensive Logging
- **Trigger Log**: Records every actuator state change
- **Automation Log**: Records rule evaluations and decisions
- **Actuator States**: Real-time status of all actuators

### 🧪 Test Mode
- Individual actuators can be put in test mode
- Test mode actuators are ignored by automation rules
- Useful for manual testing without interference

### ⏱️ Duration Control
- Optional auto-off timers for actuators
- Prevents continuous operation
- Configurable per rule

### 🔒 Safety Features
- All relays start in OFF state
- Test mode protection
- Comprehensive error logging
- WiFi reconnection handling

## 📱 Flutter App Integration

The Flutter app provides:
- Real-time actuator control
- Automation rule creation/editing
- Live sensor data display
- Historical data charts
- Test mode toggles
- Trigger history viewing

## 🚀 Getting Started

### 1. Configuration
Update these constants in `farm_control.ino`:
```cpp
#define WIFI_SSID "YOUR_WIFI_SSID"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"
#define FIREBASE_HOST "YOUR_FIREBASE_HOST"
#define FIREBASE_AUTH "YOUR_FIREBASE_AUTH"
String deviceId = "YOUR_DEVICE_ID";
String userId = "YOUR_USER_ID";
```

### 2. Upload Code
1. Open Arduino IDE
2. Install required libraries:
   - ESP8266WiFi
   - FirebaseESP8266
   - DHT sensor library
   - ArduinoJson
   - NTPClient
3. Upload to ESP8266

### 3. Monitor Serial Output
The system provides detailed logging:
```
🚀 Day 11: Smart Automation Engine Starting...
🎯 ESP8266 Farm Control with Firestore Automation
📡 Connecting to WiFi and Firebase...
Connected to WiFi
✅ Day 11 Automation Engine Ready!
🎛️  Actuators: Motor(D5), Water(D6), Light(D7), Siren(D8)
📊 Sensors: DHT11 on D4
🔄 Automation check every 10 seconds
📝 Logging all triggers to Firebase
---
🔄 Checking automation rules...
📊 Current: Temp=36.2°C, Humidity=45.1%
🔍 Rule: motor (temperature > 35°C)
   📊 Current: 36.2°C
   ⚡ Action: 🟢 ON (Duration: 300s)
🚦 motor => ON (Source: automation, Duration: 300s)
📝 Trigger logged: motor ON by automation
📊 Automation logged: motor temperature > 35 (Current: 36.2) -> TRIGGERED
🎛️  Current Actuator Status:
   motor: 🟢 ON by automation (Duration: 300s)
   water: 🔴 OFF by manual
   light: 🔴 OFF by manual
   siren: 🔴 OFF by manual
```

## 🔧 Troubleshooting

### Common Issues

1. **WiFi Connection Problems**
   - Check SSID and password
   - Ensure ESP8266 is within range
   - Monitor Serial output for connection status

2. **Firebase Connection Issues**
   - Verify Firebase credentials
   - Check Firestore security rules
   - Ensure proper project configuration

3. **Sensor Reading Failures**
   - Check DHT11 connections
   - Verify 3.3V power supply
   - Try different DHT11 library version

4. **Relay Not Responding**
   - Check 5V power supply
   - Verify pin connections
   - Test relays individually

5. **Automation Not Working**
   - Check Firestore rules structure
   - Verify sensor readings are valid
   - Monitor automation logs in Firebase

### Debug Mode
Enable detailed logging by monitoring Serial output at 115200 baud rate.

## 📈 Performance

- **Sensor Update**: Every 60 seconds
- **Automation Check**: Every 10 seconds
- **Schedule Check**: Every 30 seconds
- **Duration Check**: Every 1 second
- **History Update**: Every 5 minutes

## 🔮 Future Enhancements

- [ ] MQTT support for local control
- [ ] Multiple sensor support
- [ ] Advanced scheduling (sunrise/sunset)
- [ ] Weather API integration
- [ ] Mobile push notifications
- [ ] Data export functionality
- [ ] Web dashboard
- [ ] Machine learning optimization

## 📄 License

This project is open source and available under the MIT License.

---

**🎉 Day 11 Complete! Your farm is now fully automated! 🎉** 
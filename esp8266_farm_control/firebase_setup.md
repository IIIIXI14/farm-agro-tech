# 🔥 Firebase Firestore Setup Guide - Day 11

## 🎯 Overview

This guide will help you set up the Firebase Firestore collections and documents needed for your Day 11 Smart Automation Engine.

## 📁 Collection Structure

```
/users/{userId}/devices/{deviceId}/
├── sensorData
├── actuators
├── automationRules
├── actuatorStates
├── triggerLog
├── automationLog
├── history
├── schedules
├── testMode
└── status
```

## 🚀 Setup Instructions

### 1. Firebase Console Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `farmagrotech-7a3cf`
3. Go to **Firestore Database**
4. Make sure you're in **Native mode** (not Datastore mode)

### 2. Security Rules

Update your Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Devices under each user
      match /devices/{deviceId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
        
        // Subcollections
        match /{document=**} {
          allow read, write: if request.auth != null && request.auth.uid == userId;
        }
      }
    }
  }
}
```

## 📊 Document Creation

### 1. Create User Document

**Path**: `/users/6k7g4heczJTxvAAZMLD4PEDmL482`

```json
{
  "email": "your-email@example.com",
  "name": "Farm Owner",
  "createdAt": "2024-01-15T10:00:00Z",
  "lastLogin": "2024-01-15T10:00:00Z"
}
```

### 2. Create Device Document

**Path**: `/users/6k7g4heczJTxvAAZMLD4PEDmL482/devices/device_001`

```json
{
  "name": "Main Farm Controller",
  "status": "online",
  "createdAt": "2024-01-15T10:00:00Z",
  "lastUpdate": "2024-01-15T10:00:00Z",
  "location": "Greenhouse 1",
  "description": "Primary automation controller for main farm area"
}
```

### 3. Sensor Data Document

**Path**: `/users/6k7g4heczJTxvAAZMLD4PEDmL482/devices/device_001/sensorData`

```json
{
  "temperature": 25.6,
  "humidity": 65.4,
  "lastUpdate": "2024-01-15T10:00:00Z"
}
```

### 4. Actuators Document

**Path**: `/users/6k7g4heczJTxvAAZMLD4PEDmL482/devices/device_001/actuators`

```json
{
  "motor": false,
  "water": false,
  "light": false,
  "siren": false
}
```

### 5. Automation Rules Document

**Path**: `/users/6k7g4heczJTxvAAZMLD4PEDmL482/devices/device_001/automationRules`

```json
{
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
  },
  "light": {
    "when": "temperature",
    "operator": "<",
    "value": 20
  },
  "siren": {
    "when": "temperature",
    "operator": ">=",
    "value": 40
  }
}
```

### 6. Actuator States Document

**Path**: `/users/6k7g4heczJTxvAAZMLD4PEDmL482/devices/device_001/actuatorStates`

```json
{
  "motor": {
    "isOn": false,
    "duration": 0,
    "remainingTime": 0,
    "isTestMode": false,
    "triggerSource": "manual"
  },
  "water": {
    "isOn": false,
    "duration": 0,
    "remainingTime": 0,
    "isTestMode": false,
    "triggerSource": "manual"
  },
  "light": {
    "isOn": false,
    "duration": 0,
    "remainingTime": 0,
    "isTestMode": false,
    "triggerSource": "manual"
  },
  "siren": {
    "isOn": false,
    "duration": 0,
    "remainingTime": 0,
    "isTestMode": false,
    "triggerSource": "manual"
  }
}
```

### 7. Test Mode Document

**Path**: `/users/6k7g4heczJTxvAAZMLD4PEDmL482/devices/device_001/testMode`

```json
{
  "motor": false,
  "water": false,
  "light": false,
  "siren": false
}
```

### 8. Schedules Document

**Path**: `/users/6k7g4heczJTxvAAZMLD4PEDmL482/devices/device_001/schedules`

```json
{
  "morning_light": {
    "isActive": true,
    "actuator": "light",
    "value": true,
    "startTime": 21600,
    "endTime": 28800,
    "days": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
  },
  "evening_water": {
    "isActive": true,
    "actuator": "water",
    "value": true,
    "startTime": 64800,
    "endTime": 68400,
    "days": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
  }
}
```

## 📝 Collections (Auto-created)

These collections will be automatically created by the ESP8266:

### 1. History Collection

**Path**: `/users/6k7g4heczJTxvAAZMLD4PEDmL482/devices/device_001/history`

Sample document:
```json
{
  "temperature": 25.6,
  "humidity": 65.4,
  "timestamp": "2024-01-15T10:00:00Z"
}
```

### 2. Trigger Log Collection

**Path**: `/users/6k7g4heczJTxvAAZMLD4PEDmL482/devices/device_001/triggerLog`

Sample document:
```json
{
  "actuator": "motor",
  "state": "ON",
  "source": "automation",
  "temperature": 36.2,
  "humidity": 45.1,
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### 3. Automation Log Collection

**Path**: `/users/6k7g4heczJTxvAAZMLD4PEDmL482/devices/device_001/automationLog`

Sample document:
```json
{
  "actuator": "motor",
  "condition": "temperature",
  "operator": ">",
  "threshold": 35,
  "currentValue": 36.2,
  "triggered": true,
  "timestamp": "2024-01-15T10:30:00Z"
}
```

## 🔧 Manual Setup Steps

### Step 1: Create User Document

1. In Firebase Console, go to Firestore Database
2. Click **Start collection** (if no collections exist)
3. Collection ID: `users`
4. Document ID: `6k7g4heczJTxvAAZMLD4PEDmL482`
5. Add fields:
   - `email` (string): your email
   - `name` (string): "Farm Owner"
   - `createdAt` (timestamp): current time
   - `lastLogin` (timestamp): current time

### Step 2: Create Device Document

1. Click on the user document
2. Click **Start collection**
3. Collection ID: `devices`
4. Document ID: `device_001`
5. Add the device fields as shown above

### Step 3: Create Sub-documents

1. Click on the device document
2. Create each sub-document:
   - `sensorData` (document)
   - `actuators` (document)
   - `automationRules` (document)
   - `actuatorStates` (document)
   - `testMode` (document)
   - `schedules` (document)

### Step 4: Add Sample Automation Rules

In the `automationRules` document, add:

```json
{
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
}
```

## 🧪 Test Automation Rules

### Test Rule 1: Temperature-based Motor
```json
{
  "motor": {
    "when": "temperature",
    "operator": ">",
    "value": 30,
    "duration": 60
  }
}
```

### Test Rule 2: Humidity-based Water
```json
{
  "water": {
    "when": "humidity",
    "operator": "<",
    "value": 50
  }
}
```

### Test Rule 3: Multiple Conditions
```json
{
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
  },
  "light": {
    "when": "temperature",
    "operator": "<",
    "value": 20
  },
  "siren": {
    "when": "temperature",
    "operator": ">=",
    "value": 40
  }
}
```

## 🔍 Verification

After setup, verify:

1. **User document** exists with correct UID
2. **Device document** exists with correct device ID
3. **All sub-documents** are created
4. **Automation rules** are properly formatted
5. **Security rules** allow read/write access

## 🚨 Troubleshooting

### Common Issues:

1. **Permission Denied**
   - Check security rules
   - Verify user authentication
   - Ensure UID matches

2. **Document Not Found**
   - Check collection/document paths
   - Verify document IDs
   - Ensure proper nesting

3. **Data Not Updating**
   - Check ESP8266 WiFi connection
   - Verify Firebase credentials
   - Monitor Serial output

## ✅ Success Indicators

Your Firebase setup is working when:

1. ✅ ESP8266 connects to WiFi
2. ✅ Firebase connection established
3. ✅ Sensor data updates every minute
4. ✅ Automation rules are fetched
5. ✅ Actuator states update in real-time
6. ✅ Trigger logs are created
7. ✅ Automation logs are generated

---

**🎉 Your Firebase Firestore is now ready for Day 11 automation! 🎉** 
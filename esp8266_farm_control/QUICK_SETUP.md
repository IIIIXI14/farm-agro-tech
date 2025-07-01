# 🚀 Quick Firebase Setup Guide - Day 11

## ⚡ Fast Setup (Choose One Method)

### Method 1: Manual Setup (5 minutes)
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: `farmagrotech-7a3cf`
3. Go to **Firestore Database**
4. Follow the manual steps in `firebase_setup.md`

### Method 2: Node.js Script (2 minutes)
```bash
# Install dependencies
npm install

# Download service account key from Firebase Console
# Project Settings > Service Accounts > Generate New Private Key
# Save as serviceAccountKey.json in this folder

# Run setup
npm run setup
```

### Method 3: Python Script (2 minutes)
```bash
# Install dependencies
pip install -r requirements.txt

# Download service account key from Firebase Console
# Project Settings > Service Accounts > Generate New Private Key
# Save as serviceAccountKey.json in this folder

# Run setup
python firebase_setup.py
```

## 🔑 Get Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `farmagrotech-7a3cf`
3. Go to **Project Settings** (gear icon)
4. Click **Service Accounts** tab
5. Click **Generate New Private Key**
6. Save the JSON file as `serviceAccountKey.json` in this folder

## 📊 What Gets Created

The setup creates these collections and documents:

```
/users/6k7g4heczJTxvAAZMLD4PEDmL482/
├── devices/device_001/
│   ├── sensorData/current
│   ├── actuators/current
│   ├── automationRules/current
│   ├── actuatorStates/current
│   ├── testMode/current
│   ├── schedules/current
│   └── status/current
```

## 🧪 Test Automation Rules

The setup includes these test rules:

```json
{
  "motor": {
    "when": "temperature",
    "operator": ">",
    "value": 30,
    "duration": 60
  },
  "water": {
    "when": "humidity",
    "operator": "<",
    "value": 50
  }
}
```

## ✅ Verification

After setup, verify in Firebase Console:
- ✅ User document exists
- ✅ Device document exists
- ✅ Automation rules are present
- ✅ All sub-collections are created

## 🚀 Ready to Go!

Once setup is complete:
1. Upload your ESP8266 code
2. Monitor Serial output
3. Watch automation begin!

---

**🎉 Your Firebase is ready for Day 11 automation! 🎉** 
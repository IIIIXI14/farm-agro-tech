// Firebase Firestore Setup Script for Day 11 Automation
// Run with: node firebase_setup.js

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
// You'll need to download your service account key from Firebase Console
// Project Settings > Service Accounts > Generate New Private Key
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://farmagrotech-7a3cf.firebaseio.com"
});

const db = admin.firestore();

// Configuration
const USER_ID = "6k7g4heczJTxvAAZMLD4PEDmL482";
const DEVICE_ID = "device_001";

async function setupFirebase() {
  console.log("🚀 Setting up Firebase Firestore for Day 11 Automation...");
  
  try {
    // 1. Create User Document
    console.log("📝 Creating user document...");
    await db.collection('users').doc(USER_ID).set({
      email: "farm-owner@example.com",
      name: "Farm Owner",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLogin: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log("✅ User document created");

    // 2. Create Device Document
    console.log("📝 Creating device document...");
    await db.collection('users').doc(USER_ID).collection('devices').doc(DEVICE_ID).set({
      name: "Main Farm Controller",
      status: "online",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
      location: "Greenhouse 1",
      description: "Primary automation controller for main farm area"
    });
    console.log("✅ Device document created");

    // 3. Create Sensor Data Document
    console.log("📝 Creating sensor data document...");
    await db.collection('users').doc(USER_ID).collection('devices').doc(DEVICE_ID).collection('sensorData').doc('current').set({
      temperature: 25.6,
      humidity: 65.4,
      lastUpdate: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log("✅ Sensor data document created");

    // 4. Create Actuators Document
    console.log("📝 Creating actuators document...");
    await db.collection('users').doc(USER_ID).collection('devices').doc(DEVICE_ID).collection('actuators').doc('current').set({
      motor: false,
      water: false,
      light: false,
      siren: false
    });
    console.log("✅ Actuators document created");

    // 5. Create Automation Rules Document
    console.log("📝 Creating automation rules document...");
    await db.collection('users').doc(USER_ID).collection('devices').doc(DEVICE_ID).collection('automationRules').doc('current').set({
      motor: {
        when: "temperature",
        operator: ">",
        value: 35,
        duration: 300
      },
      water: {
        when: "humidity",
        operator: "<",
        value: 40
      },
      light: {
        when: "temperature",
        operator: "<",
        value: 20
      },
      siren: {
        when: "temperature",
        operator: ">=",
        value: 40
      }
    });
    console.log("✅ Automation rules document created");

    // 6. Create Actuator States Document
    console.log("📝 Creating actuator states document...");
    await db.collection('users').doc(USER_ID).collection('devices').doc(DEVICE_ID).collection('actuatorStates').doc('current').set({
      motor: {
        isOn: false,
        duration: 0,
        remainingTime: 0,
        isTestMode: false,
        triggerSource: "manual"
      },
      water: {
        isOn: false,
        duration: 0,
        remainingTime: 0,
        isTestMode: false,
        triggerSource: "manual"
      },
      light: {
        isOn: false,
        duration: 0,
        remainingTime: 0,
        isTestMode: false,
        triggerSource: "manual"
      },
      siren: {
        isOn: false,
        duration: 0,
        remainingTime: 0,
        isTestMode: false,
        triggerSource: "manual"
      }
    });
    console.log("✅ Actuator states document created");

    // 7. Create Test Mode Document
    console.log("📝 Creating test mode document...");
    await db.collection('users').doc(USER_ID).collection('devices').doc(DEVICE_ID).collection('testMode').doc('current').set({
      motor: false,
      water: false,
      light: false,
      siren: false
    });
    console.log("✅ Test mode document created");

    // 8. Create Schedules Document
    console.log("📝 Creating schedules document...");
    await db.collection('users').doc(USER_ID).collection('devices').doc(DEVICE_ID).collection('schedules').doc('current').set({
      morning_light: {
        isActive: true,
        actuator: "light",
        value: true,
        startTime: 21600, // 6:00 AM
        endTime: 28800,   // 8:00 AM
        days: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
      },
      evening_water: {
        isActive: true,
        actuator: "water",
        value: true,
        startTime: 64800, // 6:00 PM
        endTime: 68400,   // 7:00 PM
        days: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
      }
    });
    console.log("✅ Schedules document created");

    // 9. Create Status Document
    console.log("📝 Creating status document...");
    await db.collection('users').doc(USER_ID).collection('devices').doc(DEVICE_ID).collection('status').doc('current').set({
      status: "online",
      lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
      ipAddress: "192.168.1.100",
      firmwareVersion: "1.0.0"
    });
    console.log("✅ Status document created");

    console.log("\n🎉 Firebase Firestore setup completed successfully!");
    console.log("\n📊 Created Collections:");
    console.log("   - /users/" + USER_ID);
    console.log("   - /users/" + USER_ID + "/devices/" + DEVICE_ID);
    console.log("   - /users/" + USER_ID + "/devices/" + DEVICE_ID + "/sensorData");
    console.log("   - /users/" + USER_ID + "/devices/" + DEVICE_ID + "/actuators");
    console.log("   - /users/" + USER_ID + "/devices/" + DEVICE_ID + "/automationRules");
    console.log("   - /users/" + USER_ID + "/devices/" + DEVICE_ID + "/actuatorStates");
    console.log("   - /users/" + USER_ID + "/devices/" + DEVICE_ID + "/testMode");
    console.log("   - /users/" + USER_ID + "/devices/" + DEVICE_ID + "/schedules");
    console.log("   - /users/" + USER_ID + "/devices/" + DEVICE_ID + "/status");
    console.log("\n📝 Auto-created Collections (by ESP8266):");
    console.log("   - /users/" + USER_ID + "/devices/" + DEVICE_ID + "/history");
    console.log("   - /users/" + USER_ID + "/devices/" + DEVICE_ID + "/triggerLog");
    console.log("   - /users/" + USER_ID + "/devices/" + DEVICE_ID + "/automationLog");

  } catch (error) {
    console.error("❌ Error setting up Firebase:", error);
  }
}

// Function to add test automation rules
async function addTestRules() {
  console.log("\n🧪 Adding test automation rules...");
  
  try {
    await db.collection('users').doc(USER_ID).collection('devices').doc(DEVICE_ID).collection('automationRules').doc('current').update({
      motor: {
        when: "temperature",
        operator: ">",
        value: 30,
        duration: 60
      },
      water: {
        when: "humidity",
        operator: "<",
        value: 50
      }
    });
    console.log("✅ Test rules added successfully");
  } catch (error) {
    console.error("❌ Error adding test rules:", error);
  }
}

// Function to verify setup
async function verifySetup() {
  console.log("\n🔍 Verifying Firebase setup...");
  
  try {
    const userDoc = await db.collection('users').doc(USER_ID).get();
    const deviceDoc = await db.collection('users').doc(USER_ID).collection('devices').doc(DEVICE_ID).get();
    const rulesDoc = await db.collection('users').doc(USER_ID).collection('devices').doc(DEVICE_ID).collection('automationRules').doc('current').get();
    
    if (userDoc.exists) {
      console.log("✅ User document exists");
    } else {
      console.log("❌ User document missing");
    }
    
    if (deviceDoc.exists) {
      console.log("✅ Device document exists");
    } else {
      console.log("❌ Device document missing");
    }
    
    if (rulesDoc.exists) {
      console.log("✅ Automation rules exist");
      const rules = rulesDoc.data();
      console.log("   Rules found:", Object.keys(rules));
    } else {
      console.log("❌ Automation rules missing");
    }
    
  } catch (error) {
    console.error("❌ Error verifying setup:", error);
  }
}

// Main execution
async function main() {
  await setupFirebase();
  await addTestRules();
  await verifySetup();
  
  console.log("\n🚀 Your ESP8266 is ready to connect!");
  console.log("📡 Upload the Arduino code and watch the automation begin!");
  
  process.exit(0);
}

// Run the setup
main().catch(console.error); 
#!/usr/bin/env python3
"""
Firebase Firestore Setup Script for Day 11 Automation
Run with: python firebase_setup.py
"""

import firebase_admin
from firebase_admin import credentials, firestore
import json
from datetime import datetime

# Configuration
USER_ID = "6k7g4heczJTxvAAZMLD4PEDmL482"
DEVICE_ID = "device_001"

def setup_firebase():
    """Set up Firebase Firestore collections and documents"""
    print("🚀 Setting up Firebase Firestore for Day 11 Automation...")
    
    try:
        # Initialize Firebase Admin SDK
        # You'll need to download your service account key from Firebase Console
        # Project Settings > Service Accounts > Generate New Private Key
        cred = credentials.Certificate("serviceAccountKey.json")
        firebase_admin.initialize_app(cred, {
            'databaseURL': 'https://farmagrotech-7a3cf.firebaseio.com'
        })
        
        db = firestore.client()
        
        # 1. Create User Document
        print("📝 Creating user document...")
        user_ref = db.collection('users').document(USER_ID)
        user_ref.set({
            'email': 'farm-owner@example.com',
            'name': 'Farm Owner',
            'createdAt': firestore.SERVER_TIMESTAMP,
            'lastLogin': firestore.SERVER_TIMESTAMP
        })
        print("✅ User document created")

        # 2. Create Device Document
        print("📝 Creating device document...")
        device_ref = db.collection('users').document(USER_ID).collection('devices').document(DEVICE_ID)
        device_ref.set({
            'name': 'Main Farm Controller',
            'status': 'online',
            'createdAt': firestore.SERVER_TIMESTAMP,
            'lastUpdate': firestore.SERVER_TIMESTAMP,
            'location': 'Greenhouse 1',
            'description': 'Primary automation controller for main farm area'
        })
        print("✅ Device document created")

        # 3. Create Sensor Data Document
        print("📝 Creating sensor data document...")
        sensor_ref = db.collection('users').document(USER_ID).collection('devices').document(DEVICE_ID).collection('sensorData').document('current')
        sensor_ref.set({
            'temperature': 25.6,
            'humidity': 65.4,
            'lastUpdate': firestore.SERVER_TIMESTAMP
        })
        print("✅ Sensor data document created")

        # 4. Create Actuators Document
        print("📝 Creating actuators document...")
        actuators_ref = db.collection('users').document(USER_ID).collection('devices').document(DEVICE_ID).collection('actuators').document('current')
        actuators_ref.set({
            'motor': False,
            'water': False,
            'light': False,
            'siren': False
        })
        print("✅ Actuators document created")

        # 5. Create Automation Rules Document
        print("📝 Creating automation rules document...")
        rules_ref = db.collection('users').document(USER_ID).collection('devices').document(DEVICE_ID).collection('automationRules').document('current')
        rules_ref.set({
            'motor': {
                'when': 'temperature',
                'operator': '>',
                'value': 35,
                'duration': 300
            },
            'water': {
                'when': 'humidity',
                'operator': '<',
                'value': 40
            },
            'light': {
                'when': 'temperature',
                'operator': '<',
                'value': 20
            },
            'siren': {
                'when': 'temperature',
                'operator': '>=',
                'value': 40
            }
        })
        print("✅ Automation rules document created")

        # 6. Create Actuator States Document
        print("📝 Creating actuator states document...")
        states_ref = db.collection('users').document(USER_ID).collection('devices').document(DEVICE_ID).collection('actuatorStates').document('current')
        states_ref.set({
            'motor': {
                'isOn': False,
                'duration': 0,
                'remainingTime': 0,
                'isTestMode': False,
                'triggerSource': 'manual'
            },
            'water': {
                'isOn': False,
                'duration': 0,
                'remainingTime': 0,
                'isTestMode': False,
                'triggerSource': 'manual'
            },
            'light': {
                'isOn': False,
                'duration': 0,
                'remainingTime': 0,
                'isTestMode': False,
                'triggerSource': 'manual'
            },
            'siren': {
                'isOn': False,
                'duration': 0,
                'remainingTime': 0,
                'isTestMode': False,
                'triggerSource': 'manual'
            }
        })
        print("✅ Actuator states document created")

        # 7. Create Test Mode Document
        print("📝 Creating test mode document...")
        test_ref = db.collection('users').document(USER_ID).collection('devices').document(DEVICE_ID).collection('testMode').document('current')
        test_ref.set({
            'motor': False,
            'water': False,
            'light': False,
            'siren': False
        })
        print("✅ Test mode document created")

        # 8. Create Schedules Document
        print("📝 Creating schedules document...")
        schedules_ref = db.collection('users').document(USER_ID).collection('devices').document(DEVICE_ID).collection('schedules').document('current')
        schedules_ref.set({
            'morning_light': {
                'isActive': True,
                'actuator': 'light',
                'value': True,
                'startTime': 21600,  # 6:00 AM
                'endTime': 28800,    # 8:00 AM
                'days': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
            },
            'evening_water': {
                'isActive': True,
                'actuator': 'water',
                'value': True,
                'startTime': 64800,  # 6:00 PM
                'endTime': 68400,    # 7:00 PM
                'days': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
            }
        })
        print("✅ Schedules document created")

        # 9. Create Status Document
        print("📝 Creating status document...")
        status_ref = db.collection('users').document(USER_ID).collection('devices').document(DEVICE_ID).collection('status').document('current')
        status_ref.set({
            'status': 'online',
            'lastUpdate': firestore.SERVER_TIMESTAMP,
            'ipAddress': '192.168.1.100',
            'firmwareVersion': '1.0.0'
        })
        print("✅ Status document created")

        print("\n🎉 Firebase Firestore setup completed successfully!")
        print("\n📊 Created Collections:")
        print(f"   - /users/{USER_ID}")
        print(f"   - /users/{USER_ID}/devices/{DEVICE_ID}")
        print(f"   - /users/{USER_ID}/devices/{DEVICE_ID}/sensorData")
        print(f"   - /users/{USER_ID}/devices/{DEVICE_ID}/actuators")
        print(f"   - /users/{USER_ID}/devices/{DEVICE_ID}/automationRules")
        print(f"   - /users/{USER_ID}/devices/{DEVICE_ID}/actuatorStates")
        print(f"   - /users/{USER_ID}/devices/{DEVICE_ID}/testMode")
        print(f"   - /users/{USER_ID}/devices/{DEVICE_ID}/schedules")
        print(f"   - /users/{USER_ID}/devices/{DEVICE_ID}/status")
        print("\n📝 Auto-created Collections (by ESP8266):")
        print(f"   - /users/{USER_ID}/devices/{DEVICE_ID}/history")
        print(f"   - /users/{USER_ID}/devices/{DEVICE_ID}/triggerLog")
        print(f"   - /users/{USER_ID}/devices/{DEVICE_ID}/automationLog")

    except Exception as error:
        print(f"❌ Error setting up Firebase: {error}")

def add_test_rules():
    """Add test automation rules"""
    print("\n🧪 Adding test automation rules...")
    
    try:
        db = firestore.client()
        rules_ref = db.collection('users').document(USER_ID).collection('devices').document(DEVICE_ID).collection('automationRules').document('current')
        rules_ref.update({
            'motor': {
                'when': 'temperature',
                'operator': '>',
                'value': 30,
                'duration': 60
            },
            'water': {
                'when': 'humidity',
                'operator': '<',
                'value': 50
            }
        })
        print("✅ Test rules added successfully")
    except Exception as error:
        print(f"❌ Error adding test rules: {error}")

def verify_setup():
    """Verify the Firebase setup"""
    print("\n🔍 Verifying Firebase setup...")
    
    try:
        db = firestore.client()
        
        user_doc = db.collection('users').document(USER_ID).get()
        device_doc = db.collection('users').document(USER_ID).collection('devices').document(DEVICE_ID).get()
        rules_doc = db.collection('users').document(USER_ID).collection('devices').document(DEVICE_ID).collection('automationRules').document('current').get()
        
        if user_doc.exists:
            print("✅ User document exists")
        else:
            print("❌ User document missing")
        
        if device_doc.exists:
            print("✅ Device document exists")
        else:
            print("❌ Device document missing")
        
        if rules_doc.exists:
            print("✅ Automation rules exist")
            rules = rules_doc.to_dict()
            print(f"   Rules found: {list(rules.keys())}")
        else:
            print("❌ Automation rules missing")
        
    except Exception as error:
        print(f"❌ Error verifying setup: {error}")

def main():
    """Main execution function"""
    setup_firebase()
    add_test_rules()
    verify_setup()
    
    print("\n🚀 Your ESP8266 is ready to connect!")
    print("📡 Upload the Arduino code and watch the automation begin!")

if __name__ == "__main__":
    main() 
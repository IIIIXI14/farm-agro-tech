# 🧪 Day 11 Automation System Test Guide

## 🎯 Test Objectives

Verify that the ESP8266 Smart Automation Engine correctly:
1. Fetches automation rules from Firestore
2. Compares sensor values with thresholds
3. Activates/deactivates actuators based on conditions
4. Logs all actions to Firebase
5. Handles duration-based auto-off

## 📋 Pre-Test Setup

### 1. Hardware Verification
- [ ] ESP8266 connected to WiFi
- [ ] DHT11 sensor working (check Serial output)
- [ ] All relays connected to correct pins
- [ ] Power supply stable

### 2. Firebase Configuration
- [ ] Device document exists in Firestore
- [ ] Automation rules are set up
- [ ] Firestore security rules allow read/write

### 3. Test Rules Setup
Add these test rules to your device in Firestore:

```json
{
  "automationRules": {
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
}
```

## 🔍 Test Scenarios

### Test 1: Temperature-Based Motor Control
**Objective**: Verify motor turns ON when temperature > 30°C

**Steps**:
1. Set room temperature above 30°C (or use heat source)
2. Monitor Serial output for automation check
3. Verify motor relay activates
4. Check Firebase triggerLog and automationLog
5. Wait 60 seconds for auto-off
6. Verify motor turns OFF automatically

**Expected Output**:
```
🔄 Checking automation rules...
📊 Current: Temp=31.5°C, Humidity=45.1%
🔍 Rule: motor (temperature > 30°C)
   📊 Current: 31.5°C
   ⚡ Action: 🟢 ON (Duration: 60s)
🚦 motor => ON (Source: automation, Duration: 60s)
📝 Trigger logged: motor ON by automation
📊 Automation logged: motor temperature > 30 (Current: 31.5) -> TRIGGERED
```

### Test 2: Humidity-Based Water Control
**Objective**: Verify water pump turns ON when humidity < 50%

**Steps**:
1. Reduce humidity below 50% (use dehumidifier or heat)
2. Monitor automation check
3. Verify water relay activates
4. Increase humidity above 50%
5. Verify water pump turns OFF

**Expected Output**:
```
🔍 Rule: water (humidity < 50%)
   📊 Current: 45.2%
   ⚡ Action: 🟢 ON
🚦 water => ON (Source: automation)
```

### Test 3: Multiple Conditions
**Objective**: Test multiple actuators simultaneously

**Steps**:
1. Set temperature to 35°C and humidity to 40%
2. Verify motor and water activate
3. Check actuator status summary
4. Verify all logs are created

### Test 4: Test Mode Protection
**Objective**: Verify test mode prevents automation

**Steps**:
1. Enable test mode for motor in Flutter app
2. Trigger motor automation condition
3. Verify motor does NOT activate
4. Check Serial output shows "skipped (test mode active)"

### Test 5: Duration Control
**Objective**: Verify auto-off timers work

**Steps**:
1. Set short duration (10 seconds) for light
2. Trigger light automation
3. Verify light turns ON
4. Wait 10 seconds
5. Verify light turns OFF automatically

## 📊 Verification Checklist

### Serial Output Verification
- [ ] Day 11 startup message appears
- [ ] WiFi connection successful
- [ ] Firebase connection successful
- [ ] Automation rules fetched successfully
- [ ] Sensor readings displayed
- [ ] Rule evaluations logged
- [ ] Actuator status updates shown
- [ ] Trigger logging confirmed

### Firebase Verification
- [ ] `triggerLog` collection has new entries
- [ ] `automationLog` collection has new entries
- [ ] `actuatorStates` updated correctly
- [ ] `actuators` field reflects current states
- [ ] `sensorData` updated regularly

### Hardware Verification
- [ ] Motor relay responds to automation
- [ ] Water relay responds to automation
- [ ] Light relay responds to automation
- [ ] Siren relay responds to automation
- [ ] All relays start in OFF state
- [ ] Duration-based auto-off works

## 🚨 Troubleshooting

### Common Test Issues

1. **Automation Not Triggering**
   - Check sensor readings are valid
   - Verify rule syntax in Firestore
   - Check operator comparison logic
   - Monitor Serial for error messages

2. **Relay Not Responding**
   - Verify pin connections
   - Check power supply
   - Test relay manually first
   - Verify relay module is 5V compatible

3. **Firebase Connection Issues**
   - Check WiFi connection
   - Verify Firebase credentials
   - Check Firestore security rules
   - Monitor Serial for connection errors

4. **Duration Not Working**
   - Verify duration value is in seconds
   - Check millis() overflow handling
   - Monitor duration check interval
   - Verify duration field in rule

## 📈 Performance Metrics

Record these metrics during testing:
- **Response Time**: Time from condition change to actuator activation
- **Accuracy**: Percentage of correct automation decisions
- **Reliability**: System uptime and error rate
- **Logging**: Completeness of Firebase logs

## ✅ Success Criteria

The automation system is working correctly if:
1. All test scenarios pass
2. Serial output shows proper logging
3. Firebase logs are complete and accurate
4. Actuators respond within 10 seconds
5. Duration controls work as expected
6. Test mode protection functions correctly

## 🎉 Test Completion

Once all tests pass:
1. Document any issues found
2. Note performance metrics
3. Verify all safety features work
4. Confirm system is ready for production use

**🎯 Day 11 Automation Engine Test Complete! 🎯** 
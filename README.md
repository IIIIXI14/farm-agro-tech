# 🌱 Farm Agro Tech - Enhanced Edition

A comprehensive IoT-based smart farm monitoring and control system built with Flutter and ESP8266. This enhanced version provides advanced automation, weather integration, and intelligent analytics for modern precision agriculture.

## 🚀 Features (current)

- **Authentication**: Email/password login and registration screens.
- **Device onboarding**: Add device via in-app WebView or external portal (`DEVICE_PORTAL_URL`).
- **Realtime monitoring (RTDB)**: Reads `Users/{uid}/devices/{deviceId}/Sensor_Data` (temperature, humidity, soilMoisture, waterTemperature).
- **Actuator control**: Writes to `Users/{uid}/devices/{deviceId}/Actuators/relayN` (ON/OFF/AUTO) and shows `Actuator_Status`.
- **Thresholds & schedules**: Manage `Sensor_Threshold` and `Schedules/Schedule_1/Which_Relay` entries.
- **History charts**: Prefer RTDB `.../History`; fallback to Firestore `users/{uid}/devices/{deviceId}/history`.
- **Device status banner**: Displays ONLINE/OFFLINE and last seen from `DeviceStatus`.
- **Admin dashboard (basic)**: Screens present; functionality limited to the current RTDB paths.
- **Config via .env**: RTDB URL and device portal URL are configurable.

## ✨ Features

### 📱 Mobile App
- **User Authentication**
  - Email/password login and registration
  - Account activation system
  - Role-based access control (Admin/User)
  - Enhanced security with biometric authentication

- **Smart Dashboard**
  - Real-time analytics and insights
  - Device status overview with quick actions
  - Recent activity tracking
  - Performance metrics and trends

- **Device Management**
  - Real-time sensor data monitoring
  - Device status tracking (Online/Offline)
  - Advanced device control capabilities
  - Historical data visualization with charts
  - Device automation rules management

- **Weather Integration**
  - Real-time weather data integration
  - Weather-based automation decisions
  - Crop-specific weather recommendations
  - Weather alerts and notifications

- **Smart Notifications**
  - Customizable notification preferences
  - Sensor alert notifications
  - Device offline alerts
  - Automation trigger notifications
  - Weather-based alerts

- **Admin Dashboard**
  - User management (Activate/Deactivate accounts)
  - Admin role assignment
  - System-wide device monitoring
  - System statistics and logs
  - Automated inactive device cleanup
  - Advanced analytics and reporting

### 🔧 IoT Device (ESP8266)
- **Extended Sensor Support**
  - Temperature and humidity monitoring
  - Soil moisture sensing
  - pH level monitoring
  - CO2 concentration detection
  - Light intensity measurement
  - Air quality monitoring

- **Advanced Features**
  - Real-time data transmission
  - Automatic reconnection handling
  - Status LED indicators
  - OTA (Over-The-Air) updates support
  - Weather-aware automation
  - Advanced logging and diagnostics
  - Power management optimization

## 🚀 Getting Started

### Prerequisites
- Flutter (latest version)
- Firebase account
- Arduino IDE (for ESP8266)
- ESP8266 development board
- OpenWeatherMap API key (for weather integration)
- Internet connection for real-time features

### Mobile App Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/farm_agro_tech.git
   cd farm_agro_tech
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project and add Android/iOS apps
   - Download and place the configuration files:
     - Android: `android/app/google-services.json`
     - iOS: `ios/Runner/GoogleService-Info.plist`
   - Enable Authentication and Realtime Database
   - (Optional) Enable Firestore for history fallback

4. **Environment (.env)**
   - Create a `.env` file at project root:
     ```
     FIREBASE_RTDB_URL=https://<your-project-id>-default-rtdb.firebaseio.com
     DEVICE_PORTAL_URL=http://192.168.4.1
     ```
   - Run `flutter clean && flutter pub get` after changing `.env`

5. **Run the app**
   ```bash
   flutter run
   ```

### Facebook App ID configuration (Android)

To avoid committing secrets, the Android Facebook App ID is injected at build time. The `android/app/src/main/res/values/strings.xml` file contains empty placeholders for `facebook_app_id` and `fb_login_protocol_scheme`, and the real values are provided by Gradle during the build.

Configure one of the following (checked in this order):

- Gradle property when invoking the build:
  ```bash
  ./gradlew assembleDebug -PFACEBOOK_APP_ID=123456789012345
  ```
- `local.properties` (not committed):
  ```
  FACEBOOK_APP_ID=123456789012345
  ```
- Environment variable (useful in CI):
  ```bash
  export FACEBOOK_APP_ID=123456789012345
  ```

The build script injects these into Android string resources:
- `facebook_app_id` → `123456789012345` (or empty string if missing)
- `fb_login_protocol_scheme` → `fb123456789012345` (or empty string if missing)

If the property is missing, the app will build with empty values. Some Facebook SDK features may not function without a valid App ID.

> Note: Do not commit your real Facebook App ID to version control. The repository uses placeholders only.

#### Removing sensitive IDs from history

If a real Facebook App ID was ever committed, remove it from git history and rotate the secret in the Facebook developer portal:

```bash
# Example using git filter-repo (recommended)
pip install git-filter-repo
git filter-repo --path android/app/src/main/res/values/strings.xml --invert-paths

# Or surgically replace the ID in history across the repo
git filter-repo --replace-text replace-rules.txt

# Force-push rewritten history
git push --force --all
git push --force --tags
```

Then invalidate any cached clones and re-add the secret only via the mechanisms above.

### Environment configuration (.env)

Create a `.env` file at the project root (see `.env.example`) and set:

```
FIREBASE_RTDB_URL=https://<your-project-id>-default-rtdb.firebaseio.com
DEVICE_PORTAL_URL=http://192.168.4.1
```

6. **Configure App Settings**
   - Open the app and go to Settings
   - Configure notification preferences
   - Set up weather integration
   - Customize theme and language preferences

### ESP32/ESP8266 Setup (device)

1. Navigate to the ESP8266 directory:
   ```bash
   cd esp8266_farm_control
   ```

2. Ensure your firmware writes to RTDB paths:
   - `Users/{uid}/devices/{deviceId}/Sensor_Data` (temperature, humidity, soilMoisture, waterTemperature)
   - `Users/{uid}/devices/{deviceId}/Actuators/relayN`
   - `Users/{uid}/devices/{deviceId}/Actuator_Status/relayN/status`
   - `Users/{uid}/devices/{deviceId}/Sensor_Threshold`
   - `Users/{uid}/devices/{deviceId}/Schedules/Schedule_1/Which_Relay`
   - `Users/{uid}/devices/{deviceId}/DeviceStatus/state|last_seen`
   - (Optional) `Users/{uid}/devices/{deviceId}/History` array or map entries

3. Flash the code to your ESP8266 using Arduino IDE

4. **Configure Additional Sensors** (Optional)
   - Connect soil moisture sensor to analog pin
   - Connect pH sensor to analog pin
   - Connect light sensor to analog pin
   - Update pin configurations in the code

## 📱 App Screenshots

[Add screenshots here]

## 🏗 Project Structure

```
farm_agro_tech/
├── lib/
│   ├── screens/          # UI screens
│   ├── services/         # Business logic
│   └── widgets/          # Reusable components
├── esp8266_farm_control/ # IoT device code
└── test/                 # Unit and widget tests
```

## 🔌 Realtime Database structure

The app expects the ESP device to use the following RTDB paths:

```
Users/{uid}/devices/{deviceId}/
  Sensor_Data/
    temperature: number
    humidity: number
    soilMoisture: number
    waterTemperature: number
  Actuators/
    relay1: "ON" | "OFF" | "AUTO"
  Actuator_Status/
    relay1/status: string
  Sensor_Threshold/
    Moisture_Thres: number
    Temperature_Thres: number
    Humidity_Thres: number
  Schedules/
    Schedule_1/
      Which_Relay/
        relay1/{entryId}: { day, startHour, startMinute, stopHour, stopMinute }
  DeviceStatus/
    state: "ONLINE" | "OFFLINE"
    last_seen: unix ms or server timestamp
  History: [ { temperature, humidity, timestamp } ] or map
```

The app prefers RTDB for history under `Users/{uid}/devices/{deviceId}/History`, and will fallback to Firestore `users/{uid}/devices/{deviceId}/history` if needed.

## 🛡 Stability improvements (app)

- Defensive parsing of sensor values in My Devices screen.
- History screen prefers RTDB with safe parsing and sorts by timestamp; Firestore fallback retained.
- Add Device Wait screen uses `.env` RTDB URL and guards null/invalid payloads.
- RTDB paths aligned to `Users/{uid}/devices/{deviceId}` across services and screens that read live data.

## 🔒 Security Features

- Secure user authentication with Firebase Auth
- Role-based access control (Admin/User)
- Device ownership verification
- Data encryption in transit and at rest
- Regular security updates
- Biometric authentication support
- Secure API key management
- Offline data protection

## 🛠 Technical Stack

- **Frontend**: Flutter with Material Design 3
- **Backend**: Firebase
  - Authentication
  - Cloud Firestore
  - Real-time Database
  - Cloud Functions (for advanced features)
- **IoT**: ESP8266 (Arduino)
- **External APIs**: OpenWeatherMap
- **Local Storage**: Hive for offline data
- **State Management**: Provider pattern
- **Charts**: FL Chart for data visualization

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Your Name** - *Initial work* - [YourGithub](https://github.com/yourusername)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for the robust backend services
- ESP8266 community for IoT support
- All contributors who helped with the project

## 📞 Support

For support, email your-email@example.com or create an issue in the repository.

## 🔄 Updates

The project is actively maintained. Check the [releases](https://github.com/yourusername/farm_agro_tech/releases) page for updates.

## 🎯 Roadmap

### Upcoming Features
- [ ] Machine learning-based crop recommendations
- [ ] Advanced scheduling with sunrise/sunset integration
- [ ] Multi-language support (Spanish, French, etc.)
- [ ] Data export to CSV/Excel
- [ ] Web dashboard for desktop access
- [ ] Mobile push notifications with FCM
- [ ] Advanced analytics with predictive insights
- [ ] Integration with agricultural APIs
- [ ] Support for multiple farm locations
- [ ] Advanced automation with conditional logic

### Performance Improvements
- [ ] Optimized data caching
- [ ] Reduced API calls with smart polling
- [ ] Enhanced offline functionality
- [ ] Improved battery optimization for IoT devices

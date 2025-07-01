# 🌱 Farm Agro Tech

A modern IoT-based farm monitoring and control system built with Flutter and ESP8266. This project helps farmers monitor and control their agricultural environment in real-time.

## ✨ Features

### 📱 Mobile App
- **User Authentication**
  - Email/password login and registration
  - Account activation system
  - Role-based access control (Admin/User)

- **Device Management**
  - Real-time sensor data monitoring
  - Device status tracking (Online/Offline)
  - Device control capabilities
  - Historical data visualization

- **Admin Dashboard**
  - User management (Activate/Deactivate accounts)
  - Admin role assignment
  - System-wide device monitoring
  - System statistics and logs
  - Automated inactive device cleanup

### 🔧 IoT Device (ESP8266)
- Temperature and humidity monitoring
- Real-time data transmission
- Automatic reconnection handling
- Status LED indicators
- OTA (Over-The-Air) updates support

## 🚀 Getting Started

### Prerequisites
- Flutter (latest version)
- Firebase account
- Arduino IDE (for ESP8266)
- ESP8266 development board

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
   - Create a new Firebase project
   - Add Android and iOS apps in Firebase console
   - Download and place the configuration files:
     - Android: `android/app/google-services.json`
     - iOS: `ios/Runner/GoogleService-Info.plist`

4. **Run the app**
   ```bash
   flutter run
   ```

### ESP8266 Setup

1. Navigate to the ESP8266 directory:
   ```bash
   cd esp8266_farm_control
   ```

2. Update the configuration in `farm_control.ino`:
   ```cpp
   // WiFi credentials
   const char* WIFI_SSID = "your_wifi_ssid";
   const char* WIFI_PASSWORD = "your_wifi_password";

   // Firebase configuration
   const char* FIREBASE_HOST = "your-project.firebaseio.com";
   const char* FIREBASE_AUTH = "your-firebase-auth-token";
   ```

3. Flash the code to your ESP8266 using Arduino IDE

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

## 🔒 Security Features

- Secure user authentication
- Role-based access control
- Device ownership verification
- Data encryption in transit
- Regular security updates

## 🛠 Technical Stack

- **Frontend**: Flutter
- **Backend**: Firebase
  - Authentication
  - Cloud Firestore
  - Real-time Database
- **IoT**: ESP8266 (Arduino)

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

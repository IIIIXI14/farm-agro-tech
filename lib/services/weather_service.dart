import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WeatherData {
  final double temperature;
  final double humidity;
  final double windSpeed;
  final double rainfall;
  final String condition;
  final double uvIndex;
  final double visibility;
  final DateTime timestamp;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.rainfall,
    required this.condition,
    required this.uvIndex,
    required this.visibility,
    required this.timestamp,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['main']?['temp'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['main']?['humidity'] as num?)?.toDouble() ?? 0.0,
      windSpeed: (json['wind']?['speed'] as num?)?.toDouble() ?? 0.0,
      rainfall: (json['rain']?['1h'] as num?)?.toDouble() ?? 0.0,
      condition: json['weather']?[0]?['main'] ?? 'Unknown',
      uvIndex: 0.0, // Would need separate UV API
      visibility: (json['visibility'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'rainfall': rainfall,
      'condition': condition,
      'uvIndex': uvIndex,
      'visibility': visibility,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // OpenWeatherMap API configuration
  static String get _apiKey => AppConfig.weatherApiKey;
  static String get _baseUrl => AppConfig.weatherApiBaseUrl;

  // Get current weather for a location
  Future<WeatherData?> getCurrentWeather(double latitude, double longitude) async {
    try {
      final url = '$_baseUrl/weather?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        print('Weather API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching weather data: $e');
      return null;
    }
  }

  // Get weather forecast for a location
  Future<List<WeatherData>> getWeatherForecast(double latitude, double longitude) async {
    try {
      final url = '$_baseUrl/forecast?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['list'] as List;
        
        return list.map((item) => WeatherData.fromJson(item)).toList();
      } else {
        print('Weather forecast API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching weather forecast: $e');
      return [];
    }
  }

  // Save weather data to Firestore for a device
  Future<void> saveWeatherData(String deviceId, WeatherData weatherData) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .doc(deviceId)
          .collection('weatherData')
          .add(weatherData.toJson());
    } catch (e) {
      print('Error saving weather data: $e');
    }
  }

  // Get weather history for a device
  Stream<QuerySnapshot> getWeatherHistory(String deviceId) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('devices')
        .doc(deviceId)
        .collection('weatherData')
        .orderBy('timestamp', descending: true)
        .limit(24) // Last 24 readings
        .snapshots();
  }

  // Check if weather conditions require action
  Map<String, bool> checkWeatherAlerts(WeatherData weatherData) {
    return {
      'highTemperature': weatherData.temperature > 35,
      'lowTemperature': weatherData.temperature < 5,
      'highHumidity': weatherData.humidity > 90,
      'lowHumidity': weatherData.humidity < 20,
      'highWindSpeed': weatherData.windSpeed > 20,
      'rainfall': weatherData.rainfall > 10,
      'storm': weatherData.condition.toLowerCase().contains('storm'),
      'fog': weatherData.visibility < 1000,
    };
  }

  // Get weather-based recommendations
  List<String> getWeatherRecommendations(WeatherData weatherData) {
    final recommendations = <String>[];

    if (weatherData.temperature > 35) {
      recommendations.add('High temperature detected. Consider increasing irrigation.');
    }

    if (weatherData.temperature < 5) {
      recommendations.add('Low temperature detected. Consider activating heating systems.');
    }

    if (weatherData.humidity < 20) {
      recommendations.add('Low humidity detected. Increase misting or irrigation.');
    }

    if (weatherData.humidity > 90) {
      recommendations.add('High humidity detected. Consider ventilation to prevent mold.');
    }

    if (weatherData.windSpeed > 20) {
      recommendations.add('High wind speed detected. Secure equipment and structures.');
    }

    if (weatherData.rainfall > 10) {
      recommendations.add('Heavy rainfall detected. Check drainage systems.');
    }

    if (weatherData.condition.toLowerCase().contains('storm')) {
      recommendations.add('Storm conditions detected. Secure all equipment and structures.');
    }

    if (weatherData.visibility < 1000) {
      recommendations.add('Low visibility due to fog. Monitor systems carefully.');
    }

    return recommendations;
  }

  // Get weather icon based on condition
  static String getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
        return '🌧️';
      case 'snow':
        return '❄️';
      case 'thunderstorm':
        return '⛈️';
      case 'drizzle':
        return '🌦️';
      case 'mist':
      case 'fog':
        return '🌫️';
      default:
        return '🌤️';
    }
  }

  // Get weather color based on condition
  static int getWeatherColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return 0xFFFFD700; // Gold
      case 'clouds':
        return 0xFF87CEEB; // Sky blue
      case 'rain':
        return 0xFF4682B4; // Steel blue
      case 'snow':
        return 0xFFF0F8FF; // Alice blue
      case 'thunderstorm':
        return 0xFF483D8B; // Dark slate blue
      case 'drizzle':
        return 0xFFB0C4DE; // Light steel blue
      case 'mist':
      case 'fog':
        return 0xFFD3D3D3; // Light grey
      default:
        return 0xFF87CEEB; // Sky blue
    }
  }

  // Calculate weather-based irrigation needs
  double calculateIrrigationNeed(WeatherData weatherData, double soilMoisture) {
    double need = 0.0;

    // Base need on soil moisture
    if (soilMoisture < 30) {
      need += 0.5;
    } else if (soilMoisture < 50) {
      need += 0.3;
    } else if (soilMoisture < 70) {
      need += 0.1;
    }

    // Adjust for temperature
    if (weatherData.temperature > 30) {
      need += 0.3;
    } else if (weatherData.temperature > 25) {
      need += 0.2;
    } else if (weatherData.temperature < 10) {
      need -= 0.2;
    }

    // Adjust for humidity
    if (weatherData.humidity < 40) {
      need += 0.2;
    } else if (weatherData.humidity > 80) {
      need -= 0.2;
    }

    // Adjust for rainfall
    if (weatherData.rainfall > 5) {
      need -= 0.5;
    } else if (weatherData.rainfall > 2) {
      need -= 0.3;
    }

    // Adjust for wind speed
    if (weatherData.windSpeed > 15) {
      need += 0.1;
    }

    return need.clamp(0.0, 1.0);
  }

  // Get optimal growing conditions for common crops
  Map<String, Map<String, dynamic>> getOptimalConditions() {
    return {
      'tomatoes': {
        'temperature': {'min': 18, 'max': 30, 'optimal': 24},
        'humidity': {'min': 50, 'max': 80, 'optimal': 65},
        'soilMoisture': {'min': 60, 'max': 80, 'optimal': 70},
      },
      'lettuce': {
        'temperature': {'min': 10, 'max': 25, 'optimal': 18},
        'humidity': {'min': 60, 'max': 90, 'optimal': 75},
        'soilMoisture': {'min': 70, 'max': 90, 'optimal': 80},
      },
      'peppers': {
        'temperature': {'min': 20, 'max': 35, 'optimal': 28},
        'humidity': {'min': 40, 'max': 70, 'optimal': 55},
        'soilMoisture': {'min': 50, 'max': 75, 'optimal': 65},
      },
      'herbs': {
        'temperature': {'min': 15, 'max': 28, 'optimal': 22},
        'humidity': {'min': 50, 'max': 80, 'optimal': 65},
        'soilMoisture': {'min': 60, 'max': 80, 'optimal': 70},
      },
    };
  }

  // Check if conditions are optimal for a specific crop
  Map<String, bool> checkCropConditions(String crop, WeatherData weatherData, double soilMoisture) {
    final conditions = getOptimalConditions()[crop];
    if (conditions == null) return {};

    return {
      'temperature': weatherData.temperature >= conditions['temperature']['min'] && 
                    weatherData.temperature <= conditions['temperature']['max'],
      'humidity': weatherData.humidity >= conditions['humidity']['min'] && 
                  weatherData.humidity <= conditions['humidity']['max'],
      'soilMoisture': soilMoisture >= conditions['soilMoisture']['min'] && 
                      soilMoisture <= conditions['soilMoisture']['max'],
    };
  }
} 
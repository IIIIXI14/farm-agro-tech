import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../firebase_options.dart';

class AppConfig {
  AppConfig._();

  static String get realtimeDbUrl {
    try {
      final customUrl = dotenv.env['FIREBASE_RTDB_URL']?.trim();
      if (customUrl != null && customUrl.isNotEmpty) {
        return customUrl;
      }
    } catch (e) {
      // dotenv not initialized, use fallback
    }
    // Fallback to Firebase options database URL
    return DefaultFirebaseOptions.currentPlatform.databaseURL ?? '';
  }

  static String get devicePortalUrl {
    try {
      return dotenv.env['DEVICE_PORTAL_URL']?.trim() ?? 'http://192.168.4.1';
    } catch (e) {
      return 'http://192.168.4.1';
    }
  }

  static String get weatherApiBaseUrl {
    try {
      return dotenv.env['WEATHER_API_BASE_URL']?.trim() ?? 'https://api.openweathermap.org/data/2.5';
    } catch (e) {
      return 'https://api.openweathermap.org/data/2.5';
    }
  }

  static String get weatherApiKey {
    try {
      return dotenv.env['WEATHER_API_KEY']?.trim() ?? '';
    } catch (e) {
      return '';
    }
  }

  static bool get isRealtimeDbConfigured {
    final url = realtimeDbUrl;
    return url.isNotEmpty && url.startsWith('https://');
  }

  static bool get enableAppCheck {
    try {
      final raw = dotenv.env['ENABLE_APP_CHECK']?.trim().toLowerCase();
      if (raw == 'true' || raw == '1' || raw == 'yes') return true;
      if (raw == 'false' || raw == '0' || raw == 'no') return false;
    } catch (_) {}
    return false; // default disabled to avoid onboarding issues on captive portals
  }
}



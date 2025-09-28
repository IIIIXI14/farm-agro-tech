import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/add_device_intro_screen.dart';
import 'screens/add_device_config_screen.dart';
import 'screens/add_device_wait_screen.dart';
import 'screens/add_device_webview_screen.dart';
import 'screens/my_devices_screen.dart';
import 'screens/about_screen.dart';
import 'services/theme_service.dart';
import 'services/local_storage_service.dart';
import 'services/notification_service.dart';
import 'services/push_messaging_service.dart';
import 'services/stream_manager.dart';
// app_config not needed here after unconditional App Check activation
import 'package:flutter/foundation.dart';
import 'models/sensor_reading.dart';
import 'models/device_state.dart';
import 'models/automation_rule.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Prevent network fetches for Google Fonts on captive/offline networks
  GoogleFonts.config.allowRuntimeFetching = false;
  // Enable Firebase App Check only if google domain resolves (avoid captive portal issues)
  try {
    final addrs = await InternetAddress.lookup('firebaseappcheck.googleapis.com');
    if (addrs.isNotEmpty) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
        appleProvider: kReleaseMode ? AppleProvider.deviceCheck : AppleProvider.debug,
        webProvider: ReCaptchaV3Provider('unused-for-mobile'),
      );
    }
  } catch (_) {
    // Skip App Check if DNS fails (likely device AP). Proceed without it.
  }
  
  // Initialize timezone
  tz.initializeTimeZones();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Register Hive adapters
  Hive.registerAdapter(SensorReadingAdapter());
  Hive.registerAdapter(DeviceStateAdapter());
  Hive.registerAdapter(AutomationRuleAdapter());
  
  // Open Hive boxes for different data types
  await Hive.openBox<DeviceState>('deviceBox');
  await Hive.openBox<SensorReading>('sensorBox');
  await Hive.openBox<AutomationRule>('ruleBox');
  await Hive.openBox('userBox');
  
  // Initialize local storage service
  await LocalStorageService().initialize();
  
  // Initialize notification services
  await NotificationService().initialize();
  await PushMessagingService.initialize();
  
  final themeService = await ThemeService.init();
  runApp(
    ChangeNotifierProvider.value(
      value: themeService,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Dispose streams only when app is actually closing
    StreamManager.disposeStreamsOnAppClose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.detached) {
      // App is being closed, dispose streams
      StreamManager.disposeStreamsOnAppClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        return MaterialApp(
          title: 'Farm Agro Tech',
          theme: themeService.lightTheme,
          darkTheme: themeService.darkTheme,
          themeMode: themeService.themeMode,
          home: const AuthWrapper(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/admin': (context) => const AdminDashboardScreen(),
            '/add-device/intro': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              return AddDeviceIntroScreen(uid: args?['uid'] ?? '');
            },
            '/add-device/config': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              return AddDeviceConfigScreen(uid: args?['uid'] ?? '');
            },
            '/add-device/wait': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              return AddDeviceWaitScreen(uid: args?['uid'] ?? '');
            },
            '/add-device/webview': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              return AddDeviceWebViewScreen(uid: args?['uid'] ?? '');
            },
            '/my-devices': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              return MyDevicesScreen(uid: args?['uid'] ?? '');
            },
            '/about': (context) => const AboutScreen(),
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data != null) {
          return HomeScreen(uid: snapshot.data!.uid);
        }

        return const LoginScreen();
      },
    );
  }
}

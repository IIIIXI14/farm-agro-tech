import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_config.dart';

class FirebaseDatabaseService {
  static FirebaseDatabase? _database;
  static bool _isInitialized = false;

  /// Initialize Firebase Database with error handling
  static Future<FirebaseDatabase?> initializeDatabase() async {
    if (_isInitialized && _database != null) return _database;
    
    try {
      final url = AppConfig.realtimeDbUrl;
      print('FirebaseDatabaseService: Initializing with URL: $url');
      
      _database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: url.isNotEmpty ? url : null,
      );
      _isInitialized = true;
      print('FirebaseDatabaseService: Database initialized successfully');
      return _database;
    } catch (e) {
      print('FirebaseDatabaseService: Failed to initialize with custom URL: $e');
      // If the default URL fails, try without specifying URL
      try {
        _database = FirebaseDatabase.instanceFor(app: Firebase.app());
        _isInitialized = true;
        print('FirebaseDatabaseService: Database initialized with default URL');
        return _database;
      } catch (e2) {
        print('FirebaseDatabaseService: Database initialization failed completely: $e2');
        // Database is not available, ensure we retry next time
        _database = null;
        _isInitialized = false;
        return null;
      }
    }
  }

  /// Check if database is available
  static bool get isAvailable => _database != null;

  /// Test database connection using allowed locations under current user
  static Future<bool> testConnection({String? uid}) async {
    try {
      final db = await initializeDatabase();
      if (db == null) return false;

      // 1) Try a simple read on a user-scoped path to avoid cross-user denial
      if (uid != null && uid.isNotEmpty) {
        try {
          await db.ref('Users/$uid/devices').limitToFirst(1).get();
          print('FirebaseDatabaseService: Read probe successful (user path)');
          return true;
        } catch (_) {
          // ignore and try write probe
        }
      }

      // 2) Try a write probe that satisfies rules (requires userId)
      uid = uid ?? FirebaseAuth.instance.currentUser?.uid;
      try {
        final probePath = (uid != null && uid.isNotEmpty)
            ? 'Users/$uid/__probe'
            : 'devices/__probe_${FirebaseAuth.instance.currentUser?.uid ?? 'anon'}';
        final testRef = db.ref(probePath);
        await testRef.set({'ts': ServerValue.timestamp, if (probePath.startsWith('devices/')) 'userId': uid});
        await testRef.remove();
        print('FirebaseDatabaseService: Write probe successful');
        return true;
      } catch (_) {
        // Both probes failed
        return false;
      }
    } catch (e) {
      print('FirebaseDatabaseService: Connection test failed: $e');
      return false;
    }
  }

  /// Get device data from Realtime Database with fallback
  static Future<Map<String, dynamic>?> getDeviceData(
    String uid, 
    String deviceId,
  ) async {
    try {
      final db = await initializeDatabase();
      if (db == null) {
        // Database not available, return null
        return null;
      }

      // Read from the new user-scoped structure only
      final oldRef = db.ref('Users/$uid/Devices/$deviceId');
      final oldSnapshot = await oldRef.get();
      
      if (oldSnapshot.exists) {
        final data = oldSnapshot.value as Map<dynamic, dynamic>?;
        return data?.cast<String, dynamic>();
      }
      return null;
    } catch (e) {
      // Database error, return null
      return null;
    }
  }

  /// Update device data in Realtime Database with fallback
  static Future<bool> updateDeviceData(
    String uid,
    String deviceId,
    Map<String, dynamic> data,
  ) async {
    try {
      final db = await initializeDatabase();
      if (db == null) {
        // Database not available, return false
        return false;
      }

      final ref = db.ref('Users/$uid/Devices/$deviceId');
      await ref.update(data);
      return true;
    } catch (e) {
      // Database error, return false
      return false;
    }
  }

  /// Stream device data from Realtime Database with fallback
  static Stream<DatabaseEvent>? streamDeviceData(
    String uid,
    String deviceId,
  ) {
    try {
      if (_database == null) return null;
      
      final ref = _database!.ref('Users/$uid/Devices/$deviceId');
      return ref.onValue;
    } catch (e) {
      return null;
    }
  }

  // Note: Firestore fallback removed to enforce RTDB-only flow

  /// Get all devices for a user from the new devices collection
  static Future<Map<String, Map<String, dynamic>>> getUserDevices(String uid) async {
    try {
      final db = await initializeDatabase();
      if (db == null) return {};

      final ref = db.ref('devices');
      final snapshot = await ref.get();
      
      if (!snapshot.exists) return {};
      
      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return {};
      
      final devices = <String, Map<String, dynamic>>{};
      
      for (final entry in data.entries) {
        final deviceId = entry.key as String;
        final deviceData = Map<String, dynamic>.from(entry.value as Map);
        
        // Only include devices that belong to this user
        if (deviceData['userId'] == uid) {
          devices[deviceId] = deviceData;
        }
      }
      
      return devices;
    } catch (e) {
      return {};
    }
  }

  /// Create initial device data structure in Realtime Database
  static Future<bool> createDeviceDataStructure(
    String uid,
    String deviceId,
    Map<String, dynamic> initialData,
  ) async {
    try {
      final db = await initializeDatabase();
      if (db == null) {
        print('FirebaseDatabaseService: Database initialization failed');
        return false;
      }

      print('FirebaseDatabaseService: Creating device $deviceId for user $uid');
      print('FirebaseDatabaseService: Initial data: $initialData');

      // Build structure exactly as requested under Users/{uid}/Devices/{deviceId}
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final sensorData = <String, dynamic>{
        'temperature': (initialData['Sensor_Data']?['temperature'] ?? 0).toDouble(),
        'humidity': (initialData['Sensor_Data']?['humidity'] ?? 0).toDouble(),
        'soilMoisture': (initialData['Sensor_Data']?['soilMoisture'] ?? 0).toInt(),
        'waterTemperature': (initialData['Sensor_Data']?['waterTemperature'] ?? 0).toDouble(),
      };

      final schedules = Map<String, dynamic>.from(
        (initialData['Schedules'] as Map?) ??
            {
              'Schedule_1': {
                'Which_Relay': {
                  'relay1': {},
                  'relay2': {},
                  'relay3': {},
                  'relay4': {},
                  'relay5': {},
                }
              }
            },
      );

      final actuatorStatus = Map<String, dynamic>.from(
        (initialData['Actuator_Status'] as Map?) ??
            {
              'relay1': {'status': 'OFF'},
              'relay2': {'status': 'OFF'},
              'relay3': {'status': 'OFF'},
              'relay4': {'status': 'OFF'},
              'relay5': {'status': 'OFF'},
            },
      );

      final sensorThreshold = Map<String, dynamic>.from(
        (initialData['Sensor_Threshold'] as Map?) ??
            {
              'Humidity_Thres': 50.0,
              'Moisture_Thres': 40,
              'Temperature_Thres': 30.0,
            },
      );

      final actuators = Map<String, dynamic>.from(
        (initialData['Actuators'] as Map?) ??
            {
              'relay1': 'OFF',
              'relay2': 'OFF',
              'relay3': 'OFF',
              'relay4': 'OFF',
              'relay5': 'OFF',
            },
      );

      print('FirebaseDatabaseService: Prepared device structure for $deviceId (user: $uid)');

      // Write only to Users/{uid}/Devices/{deviceId}
      final deviceRef = db.ref('Users/$uid/Devices/$deviceId');
      bool legacyWriteOk = false;
      try {
        await deviceRef.set({
          'Sensor_Data': sensorData,
          'Schedules': schedules,
          'Actuator_Status': actuatorStatus,
          'Sensor_Threshold': sensorThreshold,
          'Actuators': actuators,
          'deviceStatus': initialData['deviceStatus'] ?? 'offline',
          'lastSeen': nowMs,
        });
        legacyWriteOk = true;
        print('FirebaseDatabaseService: Successfully wrote to Users/$uid/Devices/$deviceId');
      } catch (e) {
        print('FirebaseDatabaseService: Users path write failed: $e');
      }
      
      if (legacyWriteOk) {
        print('FirebaseDatabaseService: Device $deviceId created successfully');
        return true;
      }
      print('FirebaseDatabaseService: Both writes failed');
      return false;
    } catch (e, stackTrace) {
      print('FirebaseDatabaseService: Error creating device $deviceId: $e');
      print('FirebaseDatabaseService: Stack trace: $stackTrace');
      return false;
    }
  }
}

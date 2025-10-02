import 'package:flutter/material.dart';
import 'device_detail_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/app_config.dart';

class MyDevicesScreen extends StatelessWidget {
  final String uid;

  const MyDevicesScreen({super.key, required this.uid});

  // Helper to safely extract a bool from dynamic
  bool getBool(dynamic value) => value is bool ? value : false;

  Map<String, dynamic> _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  // Removed add button; the FAB in HomeScreen is the single entry point for adding devices

  Widget _buildDeviceCard(
    BuildContext context,
    String deviceId,
    Map<String, dynamic> deviceRoot,
  ) {
    final meta = _asMap(deviceRoot['Meta']);
    final name = (meta['name'] ?? deviceRoot['name'] ?? 'Device $deviceId').toString();
    
    // Device is considered online if sensor data is being updated regularly
    bool isOnline = false;
    // Try to get the most recent timestamp from sensor data or fallback
    final sensorDataRaw = deviceRoot['Sensor_Data'] is Map ? deviceRoot['Sensor_Data'] : deviceRoot['sensorData'];
    final sensorData = _asMap(sensorDataRaw);
    final sensorTimestamp = sensorData['timestamp'] ?? sensorData['lastUpdate'] ?? deviceRoot['lastSeen'] ?? 0;
    int sensorTimestampMs = 0;
    if (sensorTimestamp is int) {
      sensorTimestampMs = sensorTimestamp;
    } else if (sensorTimestamp is double) {
      sensorTimestampMs = sensorTimestamp.toInt();
    } else if (sensorTimestamp is String) {
      final parsed = DateTime.tryParse(sensorTimestamp);
      if (parsed != null) {
        sensorTimestampMs = parsed.millisecondsSinceEpoch;
      }
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    isOnline = sensorTimestampMs > 0 && (now - sensorTimestampMs) <= 60000;

    final actuators = _asMap(deviceRoot['Actuator_Status'] ?? {});

    // Determine primary icon based on actuator status
    IconData primaryIcon;
    Color primaryColor;
    
    // Count active actuators
    int activeCount = 0;
    final actuatorTypes = ['motor', 'light', 'water', 'siren'];
    for (String type in actuatorTypes) {
      if (actuators.containsKey(type) && getBool(actuators[type])) {
        activeCount++;
      }
    }
    
    if (activeCount == 0) {
      primaryIcon = Icons.device_hub;
      primaryColor = Colors.grey;
    } else if (activeCount == actuatorTypes.length) {
      primaryIcon = Icons.power;
      primaryColor = Colors.green;
    } else {
      primaryIcon = Icons.power_settings_new;
      primaryColor = Colors.orange;
    }

    // Use StreamBuilder to listen to Realtime Database for live sensor data
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: AppConfig.realtimeDbUrl,
      ).ref('Users/$uid/Devices/$deviceId').onValue.asBroadcastStream(),
      builder: (context, snapshot) {
        double temp = 0.0;
        double hum = 0.0;
        double soilMoisture = 0.0;
        Map<String, dynamic> realTimeActuators = {};
        bool realTimeIsOnline = isOnline; // Default to initial calculation
        
        if (snapshot.hasData && snapshot.data!.snapshot.value is Map) {
          final root = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final sensorDataRaw = root['Sensor_Data'] is Map ? root['Sensor_Data'] : root['sensorData'];
          final sensorData = _asMap(sensorDataRaw);
          final dynamic tRaw = sensorData['temperature'];
          final dynamic hRaw = sensorData['humidity'];
          final dynamic smRaw = sensorData['soilMoisture'] ?? sensorData['Soil Moisture'];
          if (tRaw is num) temp = tRaw.toDouble();
          if (tRaw is String) temp = double.tryParse(tRaw) ?? temp;
          if (hRaw is num) hum = hRaw.toDouble();
          if (hRaw is String) hum = double.tryParse(hRaw) ?? hum;
          if (smRaw is num) soilMoisture = smRaw.toDouble();
          if (smRaw is String) soilMoisture = double.tryParse(smRaw) ?? soilMoisture;
          
          // Get real-time actuator status
          realTimeActuators = _asMap(root['Actuator_Status'] ?? {});
          
          // Get real-time device status from DeviceStatus/state
          final realTimeDeviceStatus = _asMap(root['DeviceStatus'] ?? {});
          final realTimeStateValue = realTimeDeviceStatus['state']?.toString().toUpperCase();
          final realTimeLast = realTimeDeviceStatus['last_seen'] ?? 0;
          
          if (realTimeStateValue == 'ONLINE') {
            if (realTimeLast is int && realTimeLast > 0) {
              realTimeIsOnline = DateTime.now().millisecondsSinceEpoch - realTimeLast <= 60000;
            } else {
              realTimeIsOnline = true;
            }
          } else if (realTimeStateValue == 'OFFLINE') {
            realTimeIsOnline = false;
          }
        }
        return Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeviceDetailScreen(
                    uid: uid,
                    deviceId: deviceId,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10), // Further reduced from 12
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16, // Reduced from 18
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 10, // Reduced from 12
                                  color: realTimeIsOnline ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    realTimeIsOnline ? 'ONLINE' : 'OFFLINE',
                                    style: TextStyle(
                                      fontSize: 11, // Reduced from 12
                                      color: realTimeIsOnline ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha:0.12),
                          borderRadius: BorderRadius.circular(10), // Reduced from 12
                        ),
                        padding: const EdgeInsets.all(6), // Reduced from 8
                        child: Icon(
                          primaryIcon,
                          size: 24, // Reduced from 28
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8), // Further reduced from 12
                  IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.thermostat, color: Colors.orange, size: 14),
                              const SizedBox(height: 2),
                              Text(
                                '${temp.toStringAsFixed(1)}°C',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Temp',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.water_drop, color: Colors.blue, size: 14),
                              const SizedBox(height: 2),
                              Text(
                                '${hum.toStringAsFixed(1)}%',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Humidity',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.grass, color: Colors.green, size: 14),
                              const SizedBox(height: 2),
                              Text(
                                '${soilMoisture.toStringAsFixed(1)}%',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Soil',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6), // Further reduced from 12
                  Flexible(
                    child: _buildActuatorStatusIndicator(realTimeActuators),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActuatorStatusIndicator(Map<String, dynamic> actuators) {
    // Define 5 relay names and their display names
    final relayInfo = {
      'relay1': {'name': 'Motor', 'icon': Icons.settings, 'shortName': 'M1'},
      'relay2': {'name': 'Water', 'icon': Icons.water_drop, 'shortName': 'W2'},
      'relay3': {'name': 'Light', 'icon': Icons.lightbulb, 'shortName': 'L3'},
      'relay4': {'name': 'Siren', 'icon': Icons.campaign, 'shortName': 'S4'},
      'relay5': {'name': 'Fan', 'icon': Icons.air, 'shortName': 'F5'},
    };
    
    // Alternative naming conventions for data lookup
    final alternativeNames = {
      'motor': 'relay1',
      'water': 'relay2', 
      'light': 'relay3',
      'siren': 'relay4',
      'fan': 'relay5',
    };
    
    // Debug: Print actuator data to see what we're getting
    print('Actuator data received: $actuators');
    
    // Create a compact grid layout for 5 relays that fits within card boundaries
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // First row with 3 relays
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: relayInfo.entries.take(3).map((entry) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    child: _buildCompactRelayIndicator(entry, actuators, alternativeNames),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 2),
          // Second row with 2 relays
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Add empty space to center the 2 relays
                const Spacer(),
                ...relayInfo.entries.skip(3).take(2).map((entry) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      child: _buildCompactRelayIndicator(entry, actuators, alternativeNames),
                    ),
                  );
                }).toList(),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRelayIndicator(MapEntry<String, Map<String, dynamic>> entry, Map<String, dynamic> actuators, Map<String, String> alternativeNames) {
    final relayKey = entry.key;
    final relayIcon = entry.value['icon'] as IconData;
    final shortName = entry.value['shortName'] as String;
    
    // Check if this relay exists in the actuator data and is ON
    // Try both naming conventions
    bool isOn = false;
    bool hasData = false;
    
    if (actuators.containsKey(relayKey)) {
      isOn = getBool(actuators[relayKey]);
      hasData = true;
    } else {
      // Try alternative naming using the map
      for (String altKey in alternativeNames.keys) {
        if (alternativeNames[altKey] == relayKey && actuators.containsKey(altKey)) {
          isOn = getBool(actuators[altKey]);
          hasData = true;
          break;
        }
      }
    }
    
    // Debug output
    print('Relay $relayKey: isOn=$isOn, hasData=$hasData, actuators=$actuators');
    
    // Define colors based on status with enhanced visual design
    Color statusColor;
    Color borderColor;
    List<BoxShadow>? shadow;
    Gradient? backgroundGradient;
    
    if (isOn) {
      // ON state - Vibrant green with gradient and glow
      statusColor = Colors.green.shade700;
      borderColor = Colors.green.shade300;
      backgroundGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.green.shade100,
          Colors.green.shade50,
        ],
      );
      shadow = [
        BoxShadow(
          color: Colors.green.withValues(alpha:0.3),
          blurRadius: 8,
          spreadRadius: 1,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.green.withValues(alpha:0.1),
          blurRadius: 4,
          spreadRadius: 0,
          offset: const Offset(0, 1),
        ),
      ];
    } else if (hasData) {
      // OFF state - Warm red with subtle gradient
      statusColor = Colors.red.shade700;
      borderColor = Colors.red.shade300;
      backgroundGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.red.shade100,
          Colors.red.shade50,
        ],
      );
      shadow = [
        BoxShadow(
          color: Colors.red.withValues(alpha:0.1),
          blurRadius: 4,
          spreadRadius: 0,
          offset: const Offset(0, 1),
        ),
      ];
    } else {
      // No data - Elegant grey with subtle gradient
      statusColor = Colors.grey.shade600;
      borderColor = Colors.grey.shade300;
      backgroundGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.grey.shade100,
          Colors.grey.shade50,
        ],
      );
      shadow = [
        BoxShadow(
          color: Colors.grey.withValues(alpha:0.1),
          blurRadius: 2,
          spreadRadius: 0,
          offset: const Offset(0, 1),
        ),
      ];
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: backgroundGradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: shadow,
      ),
      child: Stack(
        children: [
          // Relay icon in center with enhanced styling
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor.withValues(alpha:0.2), width: 0.5),
              ),
              child: Icon(
                relayIcon,
                size: 16,
                color: statusColor,
              ),
            ),
          ),
          // Status indicator in top-right corner with power symbol
          Positioned(
            top: 2,
            right: 2,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    statusColor,
                    statusColor.withValues(alpha:0.8),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: isOn ? [
                  BoxShadow(
                    color: statusColor.withValues(alpha:0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ] : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.1),
                    blurRadius: 2,
                    spreadRadius: 0,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                isOn ? Icons.power : Icons.power_off,
                size: 6,
                color: Colors.white,
              ),
            ),
          ),
          // Relay number in bottom-left corner
          Positioned(
            bottom: 2,
            left: 2,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    statusColor.withValues(alpha:0.15),
                    statusColor.withValues(alpha:0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: statusColor.withValues(alpha:0.3), width: 0.5),
              ),
              child: Text(
                shortName,
                style: TextStyle(
                  fontSize: 7,
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConfig.realtimeDbUrl,
    );

    return StreamBuilder<DatabaseEvent>(
      stream: db.ref('Users/$uid/Devices').onValue.asBroadcastStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.devices,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No devices found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        final root = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        // Devices already scoped to this user
        final entries = root.entries
            .where((e) => e.value is Map)
            .map((e) => MapEntry(e.key, Map<String, dynamic>.from(e.value as Map)))
            .toList();

        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.devices, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No devices found', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72, // Slightly increased to accommodate 3 sensor readings
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _buildDeviceCard(context, entry.key, entry.value);
          },
        );
      },
    );
  }
}


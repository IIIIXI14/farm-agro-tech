import 'package:flutter/material.dart';
// Firestore kept only for optional logs; device metadata uses RTDB now
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import '../widgets/sensor_chart.dart';
import '../services/device_service.dart';
import '../services/log_service.dart';
import '../services/app_config.dart';

class DeviceDetailScreen extends StatefulWidget {
  final String uid;
  final String deviceId;

  const DeviceDetailScreen({
    super.key,
    required this.uid,
    required this.deviceId,
  });

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isEditingRelayNames = false;
  final Map<int, TextEditingController> _relayNameControllers = {};
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _refreshData() async {
    setState(() {
      _refreshKey++;
    });
    // Small delay to show refresh indicator
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    for (var controller in _relayNameControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _asMap(dynamic v) => v is Map
      ? Map<String, dynamic>.from(v)
      : <String, dynamic>{};

  String _getRelayName(int relayNumber, Map<String, dynamic> actuatorNames) {
    return (actuatorNames['relay$relayNumber'] ?? 'Relay $relayNumber').toString();
  }

  void _toggleRelayNameEditing() {
    setState(() {
      _isEditingRelayNames = !_isEditingRelayNames;
      if (_isEditingRelayNames) {
        // Initialize controllers for all relays
        for (int i = 1; i <= 5; i++) {
          if (!_relayNameControllers.containsKey(i)) {
            _relayNameControllers[i] = TextEditingController();
          }
        }
      }
    });
  }

  void _saveRelayNames(Map<String, dynamic> actuatorNames) async {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConfig.realtimeDbUrl,
    );
    
    final updates = <String, dynamic>{};
    for (int i = 1; i <= 5; i++) {
      final controller = _relayNameControllers[i];
      if (controller != null && controller.text.trim().isNotEmpty) {
        updates['relay$i'] = controller.text.trim();
      }
    }
    
    if (updates.isNotEmpty) {
      // Update in new devices collection
      await db.ref('devices/${widget.deviceId}/Actuator_Names').update(updates);
      // Also update in old structure for backward compatibility
      await db.ref('Users/${widget.uid}/devices/${widget.deviceId}/Actuator_Names').update(updates);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relay names updated')),
        );
      }
    }
    
    setState(() {
      _isEditingRelayNames = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isRealtimeDbConfigured) {
      return Scaffold(
        appBar: AppBar(title: const Text('Device Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Database Configuration Error',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Firebase Realtime Database URL is not configured properly.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    final dbUrl = AppConfig.realtimeDbUrl;
    
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: dbUrl,
    );

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DatabaseEvent>(
          key: ValueKey('device_title_${widget.deviceId}_$_refreshKey'),
          stream: db.ref('devices/${widget.deviceId}').onValue.asBroadcastStream(),
          builder: (context, snapshot) {
            final root = snapshot.hasData && snapshot.data!.snapshot.value is Map
                ? Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map)
                : <String, dynamic>{};
            final meta = _asMap(root['Meta']);
            final name = (meta['name'] ?? root['name'] ?? 'Device').toString();
            return Text(name);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _toggleEditMode(),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Sensors', icon: Icon(Icons.sensors)),
            Tab(text: 'Control', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          KeepAliveWrapper(child: _buildOverviewTab(db)),
          KeepAliveWrapper(child: _buildSensorsTab()),
          KeepAliveWrapper(child: _buildControlTab()),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(FirebaseDatabase db) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDeviceOnlineBanner(db),
          const SizedBox(height: 16),
          _buildDeviceStatusCard(db),
          const SizedBox(height: 16),
          _buildSensorSummaryCards(),
          const SizedBox(height: 24),
          _buildRecentActivityCard(),
          const SizedBox(height: 16),
          _buildAutomationRulesCard(),
        ],
      ),
    );
  }

  Widget _buildDeviceOnlineBanner(FirebaseDatabase db) {
    return StreamBuilder<DatabaseEvent>(
      stream: db.ref('devices/${widget.deviceId}').onValue.asBroadcastStream(),
      builder: (context, snapshot) {
        final root = snapshot.hasData && snapshot.data!.snapshot.value is Map
            ? Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map)
            : <String, dynamic>{};
        final meta = _asMap(root['Meta']);
        final deviceStatus = _asMap(root['deviceStatus']);
        final last = deviceStatus['last_seen'] ?? meta['updatedAtMs'];
        int lastMs = 0;
        if (last is int) lastMs = last;
        if (last is double) lastMs = last.toInt();
        if (last is String) {
          final d = DateTime.tryParse(last);
          if (d != null) lastMs = d.millisecondsSinceEpoch;
        }
        final bool isOnline = lastMs > 0 && (DateTime.now().millisecondsSinceEpoch - lastMs) <= 30000;
        DateTime? lastSeen = lastMs > 0 ? DateTime.fromMillisecondsSinceEpoch(lastMs) : null;

        if (root.isEmpty) return const SizedBox.shrink();

        return Card(
          color: isOnline ? Colors.green.withValues(alpha: 0.08) : Colors.red.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 12,
                  color: isOnline ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  isOnline ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isOnline ? Colors.green : Colors.red,
                  ),
                ),
                const Spacer(),
                if (lastSeen != null)
                  Text(
                    'Last seen: ${DateFormat('MMM dd, HH:mm').format(lastSeen)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeviceStatusCard(FirebaseDatabase db) {
    return StreamBuilder<DatabaseEvent>(
      key: ValueKey('device_status_${widget.deviceId}_$_refreshKey'),
      stream: db.ref('devices/${widget.deviceId}').onValue.asBroadcastStream().timeout(
        const Duration(seconds: 10),
        onTimeout: (eventSink) {
          eventSink.addError('Connection timeout. Please check your internet connection.');
        },
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(child: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Error loading device data: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.device_unknown, color: Colors.orange, size: 48),
                  const SizedBox(height: 16),
                  const Text('No device data available'),
                  const SizedBox(height: 8),
                  const Text('This device may not exist or you may not have access to it.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        final root = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        final meta = _asMap(root['Meta']);
        final deviceStatus = _asMap(root['deviceStatus']);
        final last = deviceStatus['last_seen'] ?? meta['updatedAtMs'] ?? 0;
        int lastMs = 0;
        if (last is int) lastMs = last;
        if (last is double) lastMs = last.toInt();
        if (last is String) {
          final d = DateTime.tryParse(last);
          if (d != null) lastMs = d.millisecondsSinceEpoch;
        }
        final bool isOnline = lastMs > 0 && (DateTime.now().millisecondsSinceEpoch - lastMs) <= 30000;
        final createdMs = (meta['createdAtMs'] ?? 0) as int;
        final updatedMs = (meta['updatedAtMs'] ?? createdMs) as int;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: isOnline ? Colors.green : Colors.red,
                      size: 12,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'deviceStatus: ${isOnline ? 'ONLINE' : 'OFFLINE'}',
                      style: TextStyle(
                        color: isOnline ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (_isEditing)
                      IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: _saveDeviceName,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_isEditing)
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Device Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 8),
                if (updatedMs > 0)
                  Text(
                    'Last Update: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(updatedMs))}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (createdMs > 0)
                  Text(
                    'Created: ${DateFormat('MMM dd, yyyy').format(DateTime.fromMillisecondsSinceEpoch(createdMs))}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSensorSummaryCards() {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: AppConfig.realtimeDbUrl,
      )
      .ref('devices/${widget.deviceId}')
      .onValue
      .asBroadcastStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('No sensor data available')),
            ),
          );
        }
    final root = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
    final sensorMapDynamic = root['Sensor_Data'] ?? root['sensorData'];
    final sensorData = sensorMapDynamic is Map
        ? Map<String, dynamic>.from(sensorMapDynamic)
        : <String, dynamic>{};

    if (sensorData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Center(child: Text('No sensor data available')),
        ),
      );
    }

    final temperature = ((sensorData['temperature'] ?? 0) as num).toDouble();
    final humidity = ((sensorData['humidity'] ?? 0) as num).toDouble();
    final soilMoisture = ((sensorData['Soil Moisture'] ?? 0) as num).toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 380;
        final bool veryCompact = constraints.maxWidth < 300;
        
        if (veryCompact) {
          // Stack vertically for very small screens
          return Column(
            children: [
              _buildSensorCard(
                'Temperature',
                temperature,
                '°C',
                Icons.thermostat,
                temperature >= 10 && temperature <= 40 ? Colors.green : Colors.red,
                compact: true,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildSensorCard(
                      'Humidity',
                      humidity,
                      '%',
                      Icons.water_drop,
                      humidity >= 30 && humidity <= 80 ? Colors.green : Colors.red,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSensorCard(
                      'Soil Moisture',
                      soilMoisture,
                      '%',
                      Icons.water_drop,
                      soilMoisture >= 30 && soilMoisture <= 80 ? Colors.green : Colors.red,
                      compact: true,
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        
        return Row(
          children: [
            Expanded(
              child: _buildSensorCard(
                'Temperature',
                temperature,
                '°C',
                Icons.thermostat,
                temperature >= 10 && temperature <= 40 ? Colors.green : Colors.red,
                compact: compact,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSensorCard(
                'Humidity',
                humidity,
                '%',
                Icons.water_drop,
                humidity >= 30 && humidity <= 80 ? Colors.green : Colors.red,
                compact: compact,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSensorCard(
                'Soil Moisture',
                soilMoisture,
                '%',
                Icons.water_drop,
                soilMoisture >= 30 && soilMoisture <= 80 ? Colors.green : Colors.red,
                compact: compact,
              ),
            ),
          ],
        );
      },
    );
  },
);
  }

  Widget _buildRecentActivityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instanceFor(
                app: Firebase.app(),
                databaseURL: AppConfig.realtimeDbUrl,
              )
              .ref('devices/${widget.deviceId}/TriggerLog')
              .limitToLast(5)
              .onValue
              .asBroadcastStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Text('No recent activity');
                }
                final map = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                final items = map.values
                    .whereType<Map>()
                    .map((v) => Map<String, dynamic>.from(v))
                    .toList()
                  ..sort((a, b) => ((b['timestampMs'] ?? 0) as int).compareTo((a['timestampMs'] ?? 0) as int));
                return Column(
                  children: items.map((data) {
                    final actuator = (data['Actuator_Status'] ?? 'Unknown').toString();
                    final state = (data['state'] ?? 'Unknown').toString();
                    final source = (data['source'] ?? 'Unknown').toString();
                    final tsMs = (data['timestampMs'] ?? 0) as int;
                    final ts = tsMs > 0 ? DateTime.fromMillisecondsSinceEpoch(tsMs) : null;
                    return ListTile(
                      leading: Icon(
                        state == 'ON' ? Icons.power : Icons.power_off,
                        color: state == 'ON' ? Colors.green : Colors.grey,
                      ),
                      title: Text('$actuator $state'),
                      subtitle: Text('$source • ${ts != null ? DateFormat('MMM dd, HH:mm').format(ts) : 'Unknown'}'),
                      dense: true,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
          },
        ),
      ),
    );
  }

  Widget _buildAutomationRulesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Automation Rules',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddRuleDialog(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instanceFor(
                app: Firebase.app(),
                databaseURL: AppConfig.realtimeDbUrl,
              )
              .ref('devices/${widget.deviceId}/AutomationRules')
              .onValue
              .asBroadcastStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Text('No automation rules configured');
                }
                final rules = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                if (rules.isEmpty) return const Text('No automation rules configured');
                return Column(
                  children: rules.entries.map((entry) {
                    final actuator = entry.key;
                    final rule = Map<String, dynamic>.from(entry.value as Map);
                    final when = rule['when'] ?? 'Unknown';
                    final op = rule['operator'] ?? 'Unknown';
                    final value = rule['value'] ?? 0;
                    return ListTile(
                      leading: const Icon(Icons.rule, color: Colors.blue),
                      title: Text('$actuator: $when $op $value'),
                      subtitle: const Text('Automation rule'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final db = FirebaseDatabase.instanceFor(
                            app: Firebase.app(),
                            databaseURL: AppConfig.realtimeDbUrl,
                          );
                          // Remove from new devices collection
                          await db.ref('devices/${widget.deviceId}/AutomationRules/$actuator').remove();
                          // Also remove from old structure for backward compatibility
                          await db.ref('Users/${widget.uid}/devices/${widget.deviceId}/AutomationRules/$actuator').remove();
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSensorChart(),
        const SizedBox(height: 16),
        _buildSensorDetails(),
      ],
    );
  }

  Widget _buildSensorChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sensor History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SensorChart(uid: widget.uid, deviceId: widget.deviceId),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sensor Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instanceFor(
                app: Firebase.app(),
                databaseURL: AppConfig.realtimeDbUrl,
              )
              .ref('devices/${widget.deviceId}')
              .onValue
              .asBroadcastStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Text('No sensor data available');
                }

                final root = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                final sensorData = _asMap(root['Sensor_Data'].toString().isNotEmpty ? root['Sensor_Data'] : root['sensorData']);
                if (sensorData.isEmpty) {
                  return const Text('No sensor data available');
                }
                final sensors = [
                  {'name': 'Temperature', 'value': ((sensorData['temperature'] ?? 0) as num).toDouble(), 'unit': '°C', 'icon': Icons.thermostat},
                  {'name': 'Humidity', 'value': ((sensorData['humidity'] ?? 0) as num).toDouble(), 'unit': '%', 'icon': Icons.water_drop},
                  {'name': 'Soil Moisture', 'value': ((sensorData['soilMoisture'] ?? 0) as num).toDouble(), 'unit': '%', 'icon': Icons.grass},
                ];

                return Column(
                  children: sensors.map((sensor) {
                    final value = (sensor['value'] as num).toDouble();
                    final isNormal = _isSensorValueNormal(sensor['name'] as String, value);

                    return ListTile(
                      leading: Icon(
                        sensor['icon'] as IconData,
                        color: isNormal ? Colors.green : Colors.red,
                      ),
                      title: Text(sensor['name'] as String),
                      subtitle: Text('${value.toStringAsFixed(1)}${sensor['unit']}'),
                      trailing: Icon(
                        isNormal ? Icons.check_circle : Icons.warning,
                        color: isNormal ? Colors.green : Colors.red,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard(
    String name,
    double value,
    String unit,
    IconData icon,
    Color color, {
    bool compact = false,
  }) {
    final bool isNormal = _isSensorValueNormal(name, value);
    final Color okColor = Theme.of(context).colorScheme.primary;
    final Color warnColor = Theme.of(context).colorScheme.error;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: compact ? 18 : 24),
            const SizedBox(height: 4),
            Text(
              name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 12 : null,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${value.toStringAsFixed(1)}$unit',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: compact ? 12 : null,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 4),
            Icon(
              isNormal ? Icons.check_circle : Icons.warning,
              color: isNormal ? okColor : warnColor,
              size: compact ? 14 : 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildActuatorControls(),
        const SizedBox(height: 16),
        _buildSchedulesEditor(),
        const SizedBox(height: 16),
        _buildTestModeControls(),
      ],
    );
  }

  Widget _buildActuatorControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Actuator Controls',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(_isEditingRelayNames ? Icons.save : Icons.edit),
                  onPressed: _isEditingRelayNames ? null : _toggleRelayNameEditing,
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instanceFor(
                app: Firebase.app(),
                databaseURL: AppConfig.realtimeDbUrl,
              )
              .ref('devices/${widget.deviceId}')
              .onValue
              .asBroadcastStream()
              .timeout(
                const Duration(seconds: 10),
                onTimeout: (eventSink) {
                  eventSink.addError('Connection timeout. Please check your internet connection.');
                },
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading device data...'),
                      ],
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text('Database Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.device_unknown, color: Colors.orange, size: 48),
                        const SizedBox(height: 16),
                        const Text('No device data available'),
                        const SizedBox(height: 8),
                        const Text('This device may not exist or you may not have access to it.'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final root = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                final actuators = Map<String, dynamic>.from(root['Actuator_Status'] ?? {});
                final statuses = Map<String, dynamic>.from(root['Actuator_Status'] ?? {});
                final actuatorNames = Map<String, dynamic>.from(root['Actuator_Names'] ?? {});

                String relayValue(int n) {
                  final status = actuators['relay$n'];
                  if (status is bool) {
                    return status ? 'ON' : 'OFF';
                  } else if (status is String) {
                    return status;
                  } else if (status is Map) {
                    return (status['status'] ?? 'OFF').toString();
                  }
                  return 'OFF';
                }
                String relayStatus(int n) {
                  final status = statuses['relay$n'];
                  if (status is Map) {
                    return (status['status'] ?? 'Unknown').toString();
                  } else if (status is bool) {
                    return status ? 'ON' : 'OFF';
                  } else if (status is String) {
                    return status;
                  }
                  return 'Unknown';
                }

                Widget relayTile({
                  required int n,
                  required bool allowsAuto,
                }) {
                  final current = relayValue(n);
                  final statusText = relayStatus(n);
                  final relayName = _getRelayName(n, actuatorNames);

                  // Load current name into controller when editing
                  if (_isEditingRelayNames) {
                    final controller = _relayNameControllers[n];
                    if (controller != null && controller.text.isEmpty) {
                      controller.text = relayName;
                    }
                  }

                  if (allowsAuto) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.power, color: Colors.green),
                        title: _isEditingRelayNames 
                          ? TextField(
                              controller: _relayNameControllers[n],
                              decoration: InputDecoration(
                                hintText: 'Enter relay name',
                                border: const OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                            )
                          : Text(relayName),
                        subtitle: Text(statusText),
                        trailing: _isEditingRelayNames 
                          ? null
                          : DropdownButton<String>(
                              value: current == 'AUTO' ? 'AUTO' : (current == 'ON' ? 'ON' : 'OFF'),
                              items: const [
                                DropdownMenuItem(value: 'OFF', child: Text('OFF')),
                                DropdownMenuItem(value: 'ON', child: Text('ON')),
                                DropdownMenuItem(value: 'AUTO', child: Text('AUTO')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  _setRelayValue(n, val);
                                }
                              },
                            ),
                        onLongPress: () {
                          if (n == 1 && !_isEditingRelayNames) {
                            _openThresholdsSheet();
                          }
                        },
                      ),
                    );
                  }

                  final isOn = current == 'ON';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(Icons.power, color: isOn ? Colors.green : Colors.grey),
                      title: _isEditingRelayNames 
                        ? TextField(
                            controller: _relayNameControllers[n],
                            decoration: InputDecoration(
                              hintText: 'Enter relay name',
                              border: const OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          )
                        : Text(relayName),
                      subtitle: Text(statusText),
                      trailing: _isEditingRelayNames 
                        ? null
                        : Switch(
                            value: isOn,
                            onChanged: (val) => _setRelayValue(n, val ? 'ON' : 'OFF'),
                            activeColor: Colors.green,
                          ),
                      onLongPress: () {
                        if (n == 1 && !_isEditingRelayNames) {
                          _openThresholdsSheet();
                        }
                      },
                    ),
                  );
                }

                return Column(
                  children: [
                    relayTile(n: 1, allowsAuto: true),
                    relayTile(n: 2, allowsAuto: false),
                    relayTile(n: 3, allowsAuto: false),
                    relayTile(n: 4, allowsAuto: false),
                    relayTile(n: 5, allowsAuto: false),
                    if (_isEditingRelayNames) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isEditingRelayNames = false;
                              });
                            },
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _saveRelayNames(actuatorNames),
                            child: const Text('Save Names'),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdEditor() {
    final moistureCtl = TextEditingController();
    final tempCtl = TextEditingController();
    final humCtl = TextEditingController();

    return StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instanceFor(
                app: Firebase.app(),
                databaseURL: AppConfig.realtimeDbUrl,
              )
              .ref('Users/${widget.uid}/devices/${widget.deviceId}/Sensor_Threshold')
              .onValue,
              builder: (context, snapshot) {
                final map = snapshot.hasData && snapshot.data!.snapshot.value != null
                    ? Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map)
                    : <String, dynamic>{};
                moistureCtl.text = ((map['Moisture_Thres'] ?? 50) as num).toString();
                tempCtl.text = ((map['Temperature_Thres'] ?? 100) as num).toString();
                humCtl.text = ((map['Humidity_Thres'] ?? 0) as num).toString();

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _numField(moistureCtl, 'Moisture % (0-100)')),
                        const SizedBox(width: 12),
                        Expanded(child: _numField(tempCtl, 'Temperature °C')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _numField(humCtl, 'Humidity %')),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final moisture = int.tryParse(moistureCtl.text.trim());
                              final temp = double.tryParse(tempCtl.text.trim());
                              final hum = double.tryParse(humCtl.text.trim());
                              if (moisture == null || temp == null || hum == null) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Enter valid numeric thresholds')),
                                  );
                                }
                                return;
                              }
                              final m = moisture.clamp(0, 100);
                              final db = FirebaseDatabase.instanceFor(
                                app: Firebase.app(),
                                databaseURL: AppConfig.realtimeDbUrl,
                              );
                              // Update in new devices collection
                              await db.ref('devices/${widget.deviceId}/Sensor_Threshold').update({
                                'Moisture_Thres': m,
                                'Temperature_Thres': temp,
                                'Humidity_Thres': hum,
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Thresholds saved')),
                                );
                              }
                            },
                            icon: const Icon(Icons.save),
                            label: const Text('Save Thresholds'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
  }

  Widget _numField(TextEditingController ctl, String label) {
    return TextField(
      controller: ctl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  void _openThresholdsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune),
                    const SizedBox(width: 8),
                    Text(
                      'Auto Mode Thresholds (Relay 1)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildThresholdEditor(),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime24(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildSchedulesEditor() {
    int relaySel = 1;
    String daySel = 'Monday';
    TimeOfDay start = const TimeOfDay(hour: 6, minute: 0);
    TimeOfDay stop = const TimeOfDay(hour: 6, minute: 5);
    final bool invalidRange =
        (stop.hour * 60 + stop.minute) <= (start.hour * 60 + start.minute);


    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedules',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                final left = DropdownButtonFormField<int>(
                  value: relaySel,
                  items: const [1,2,3,4,5]
                      .map((e) => DropdownMenuItem(value: e, child: Text('Relay $e')))
                      .toList(),
                  onChanged: (v) { if (v != null) setState(() { relaySel = v; }); },
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Relay'),
                );
                final right = DropdownButtonFormField<String>(
                  value: daySel,
                  items: const [
                    'Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'
                  ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (v) { if (v != null) setState(() { daySel = v; }); },
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Day'),
                );
                if (isNarrow) {
                  return Column(
                    children: [
                      left,
                      const SizedBox(height: 12),
                      right,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: left),
                    const SizedBox(width: 12),
                    Expanded(child: right),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                final left = OutlinedButton.icon(
                  onPressed: () async {
                    final res = await showTimePicker(
                      context: context,
                      initialTime: start,
                      initialEntryMode: TimePickerEntryMode.input,
                      builder: (context, child) {
                        return MediaQuery(
                          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                          child: child!,
                        );
                      },
                    );
                    if (res != null) setState(() { start = res; });
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: Text('Start ${_formatTime24(start)}'),
                );
                final right = OutlinedButton.icon(
                  onPressed: () async {
                    final res = await showTimePicker(
                      context: context,
                      initialTime: stop,
                      initialEntryMode: TimePickerEntryMode.input,
                      builder: (context, child) {
                        return MediaQuery(
                          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                          child: child!,
                        );
                      },
                    );
                    if (res != null) setState(() { stop = res; });
                  },
                  icon: const Icon(Icons.stop),
                  label: Text('Stop ${_formatTime24(stop)}'),
                );
                if (isNarrow) {
                  return Column(
                    children: [
                      left,
                      const SizedBox(height: 12),
                      right,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: left),
                    const SizedBox(width: 12),
                    Expanded(child: right),
                  ],
                );
              },
            ),
            if (invalidRange)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Stop time must be after start time',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: invalidRange ? null : () async {
                  final db = FirebaseDatabase.instanceFor(
                    app: Firebase.app(),
                    databaseURL: AppConfig.realtimeDbUrl,
                  );
                  final path = 'devices/${widget.deviceId}/Schedules/Schedule_1/Which_Relay/relay$relaySel';
                  final newRef = db.ref(path).push();
                  await newRef.set({
                    'day': daySel,
                    'startHour': start.hour,
                    'startMinute': start.minute,
                    'stopHour': stop.hour,
                    'stopMinute': stop.minute,
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Schedule added')),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Schedule'),
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instanceFor(
                app: Firebase.app(),
                databaseURL: AppConfig.realtimeDbUrl,
              )
              .ref('devices/${widget.deviceId}/Schedules/Schedule_1/Which_Relay')
              .onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Text('No schedules configured');
                }
                final map = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                final entries = <Widget>[];
                for (final relayEntry in map.entries) {
                  final relayKey = relayEntry.key; // e.g., relay1
                  final relayNum = int.tryParse(relayKey.replaceAll('relay', '')) ?? 0;
                  final schedules = Map<String, dynamic>.from(relayEntry.value as Map);
                  schedules.forEach((entryId, v) {
                    final s = Map<String, dynamic>.from(v as Map);
                    entries.add(Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        leading: const Icon(Icons.schedule),
                        title: Text('Relay $relayNum • ${s['day']}'),
                        subtitle: Text(
                          '${s['startHour'].toString().padLeft(2,'0')}:${s['startMinute'].toString().padLeft(2,'0')} — '
                          '${s['stopHour'].toString().padLeft(2,'0')}:${s['stopMinute'].toString().padLeft(2,'0')}'
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final db = FirebaseDatabase.instanceFor(
                              app: Firebase.app(),
                              databaseURL: AppConfig.realtimeDbUrl,
                            );
                            // Remove from new devices collection
                            await db.ref('devices/${widget.deviceId}/Schedules/Schedule_1/Which_Relay/$relayKey/$entryId').remove();
                            // Also remove from old structure for backward compatibility
                            await db.ref('Users/${widget.uid}/devices/${widget.deviceId}/Schedules/Schedule_1/Which_Relay/$relayKey/$entryId').remove();
                          },
                        ),
                      ),
                    ));
                  });
                }
                return Column(children: entries);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestModeControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Mode',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Test mode allows manual control without automation interference',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _enableTestMode(),
              icon: const Icon(Icons.science),
              label: const Text('Enable Test Mode'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  bool _isSensorValueNormal(String sensorName, double value) {
    switch (sensorName.toLowerCase()) {
      case 'temperature':
        return value >= 10 && value <= 40;
      case 'humidity':
        return value >= 30 && value <= 80;
      case 'soil moisture':
        return value >= 20 && value <= 80;
      case 'light intensity':
        return value >= 0 && value <= 100000;
      default:
        return true;
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        // Load current device name from RTDB
        final db = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: AppConfig.realtimeDbUrl,
        );
        // Try new devices collection first, fallback to old structure
        db.ref('devices/${widget.deviceId}/Meta').get().then((snap) {
          if (snap.exists && snap.value is Map) {
            final data = Map<String, dynamic>.from(snap.value as Map);
            _nameController.text = (data['name'] ?? '').toString();
          }
        });
      }
    });
  }

  void _saveDeviceName() async {
    if (_nameController.text.trim().isNotEmpty) {
      await DeviceService(widget.uid).updateDeviceName(
        widget.deviceId,
        _nameController.text.trim(),
      );
      setState(() {
        _isEditing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device name updated')),
        );
      }
    }
  }


  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device'),
        content: const Text('Are you sure you want to delete this device? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDevice();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteDevice() async {
    await DeviceService(widget.uid).deleteDevice(widget.deviceId);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device deleted')),
      );
    }
  }

  void _showAddRuleDialog() {
    // Implementation for adding automation rules
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Automation Rule'),
        content: const Text('Automation rule creation will be implemented in the next version.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }


  void _enableTestMode() {
    // Implementation for enabling test mode
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test mode enabled')),
    );
  }

  void _setRelayValue(int relayNumber, String value) async {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConfig.realtimeDbUrl,
    );
    // Convert string value to boolean for Actuator_Status
    final boolValue = value == 'ON';
    await db
        .ref('devices/${widget.deviceId}/Actuator_Status/relay$relayNumber')
        .set(boolValue);
    await LogService.logDeviceAction(
      widget.uid,
      widget.deviceId,
      'relay$relayNumber set to $value',
      type: LogType.info,
    );
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

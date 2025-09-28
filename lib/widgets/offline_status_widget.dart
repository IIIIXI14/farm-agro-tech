import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../models/sensor_reading.dart';
import '../models/device_state.dart';

class OfflineStatusWidget extends StatefulWidget {
  final String userId;

  const OfflineStatusWidget({super.key, required this.userId});

  @override
  State<OfflineStatusWidget> createState() => _OfflineStatusWidgetState();
}

class _OfflineStatusWidgetState extends State<OfflineStatusWidget> {
  final LocalStorageService _storage = LocalStorageService();
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    setState(() {
      _stats = _storage.getStorageStats();
    });
  }

  Future<void> _addTestData() async {
    // Add test sensor reading
    final testReading = SensorReading(
      deviceId: 'test_device_001',
      temperature: 25.5,
      humidity: 60.2,
      timestamp: DateTime.now(),
      userId: widget.userId,
    );
    await _storage.saveSensorReading(testReading);

    // Add test device state
    final testDevice = DeviceState(
      deviceId: 'test_device_001',
      actuators: {
        'motor': false,
        'light': true,
        'water': false,
        'siren': false,
      },
      lastUpdated: DateTime.now(),
      userId: widget.userId,
      status: 'online',
      deviceName: 'Test Device',
    );
    await _storage.saveDeviceState(testDevice);

    _loadStats();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test data added to local storage'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _clearLocalData() async {
    await _storage.clearUserData(widget.userId);
    _loadStats();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Local data cleared'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage_rounded, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Offline Storage Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadStats,
                  tooltip: 'Refresh stats',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow('Device States', _stats['deviceStates'] ?? 0, Icons.devices_other_rounded),
            _buildStatRow('Sensor Readings', _stats['sensorReadings'] ?? 0, Icons.thermostat_rounded),
            _buildStatRow('Automation Rules', _stats['automationRules'] ?? 0, Icons.auto_mode_rounded),
            _buildStatRow('User Data', _stats['userData'] ?? 0, Icons.person_rounded),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addTestData,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Test Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearLocalData,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int count, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: count > 0 ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
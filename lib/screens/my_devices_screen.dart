import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'device_detail_screen.dart';

class MyDevicesScreen extends StatelessWidget {
  final String uid;

  const MyDevicesScreen({super.key, required this.uid});

  // Helper to safely extract a bool from dynamic
  bool getBool(dynamic value) => value is bool ? value : false;

  void _addDevice(BuildContext context) async {
    final devicesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices');

    final newId = 'device_${DateTime.now().millisecondsSinceEpoch}';

    await devicesRef.doc(newId).set({
      'name': 'New Device',
      'status': 'offline',
      'sensorData': {'temperature': 0, 'humidity': 0},
      'actuators': {
        'motor': false,
        'light': false,
        'water': false,
        'siren': false,
      },
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeviceDetailScreen(uid: uid, deviceId: newId),
        ),
      );
    }
  }

  Widget _buildDeviceCard(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final deviceId = doc.id;
    final name = data['name'] ?? 'Unnamed Device';
    final sensorData = data['sensorData'] as Map<String, dynamic>?;
    final temp = sensorData?['temperature'];
    final hum = sensorData?['humidity'];
    final status = data['status'] ?? 'offline';
    final actuators = data['actuators'] as Map<String, dynamic>?;

    // Determine the primary icon based on active actuators
    IconData primaryIcon;
    Color primaryColor;
    if (getBool(actuators?['motor'])) {
      primaryIcon = Icons.agriculture;
      primaryColor = Colors.brown;
    } else if (getBool(actuators?['light'])) {
      primaryIcon = Icons.lightbulb;
      primaryColor = Colors.amber;
    } else if (getBool(actuators?['water'])) {
      primaryIcon = Icons.opacity;
      primaryColor = Colors.blue;
    } else if (getBool(actuators?['siren'])) {
      primaryIcon = Icons.notifications_active;
      primaryColor = Colors.red;
    } else {
      primaryIcon = Icons.device_hub;
      primaryColor = Colors.grey;
    }

    return Card(
      elevation: 2,
      child: InkWell(
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
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
                              size: 12,
                              color: status == 'online' ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                color: status == 'online' ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    primaryIcon,
                    size: 32,
                    color: primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.thermostat, color: Colors.orange),
                      const SizedBox(height: 4),
                      Text(
                        '${temp?.toStringAsFixed(1) ?? '--'}°C',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Temperature',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Icon(Icons.water_drop, color: Colors.blue),
                      const SizedBox(height: 4),
                      Text(
                        '${hum?.toStringAsFixed(1) ?? '--'}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Humidity',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActuatorIndicator(
                    'Motor',
                    Icons.agriculture,
                    getBool(actuators?['motor']),
                    Colors.brown,
                  ),
                  _buildActuatorIndicator(
                    'Light',
                    Icons.lightbulb,
                    getBool(actuators?['light']),
                    Colors.amber,
                  ),
                  _buildActuatorIndicator(
                    'Water',
                    Icons.opacity,
                    getBool(actuators?['water']),
                    Colors.blue,
                  ),
                  _buildActuatorIndicator(
                    'Siren',
                    Icons.notifications_active,
                    getBool(actuators?['siren']),
                    Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActuatorIndicator(String name, IconData icon, bool isActive, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: isActive ? color : Colors.grey,
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? color : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final devicesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addDevice(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: devicesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _addDevice(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Device'),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              return _buildDeviceCard(context, doc);
            },
          );
        },
      ),
    );
  }
} 
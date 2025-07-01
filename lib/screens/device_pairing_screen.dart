import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DevicePairingScreen extends StatefulWidget {
  final String userId;
  const DevicePairingScreen({super.key, required this.userId});

  @override
  State<DevicePairingScreen> createState() => _DevicePairingScreenState();
}

class _DevicePairingScreenState extends State<DevicePairingScreen> {
  final _deviceIdController = TextEditingController();
  bool _isSaving = false;
  String? _savedDeviceId;

  Future<void> _saveDevice() async {
    final deviceId = _deviceIdController.text.trim();
    if (deviceId.isEmpty) return;
    setState(() => _isSaving = true);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('devices')
        .doc(deviceId)
        .set({
      'name': 'New Device',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'offline',
      'sensorData': {'temperature': 0, 'humidity': 0},
      'actuators': {
        'motor': false,
        'light': false,
        'water': false,
        'siren': false,
      },
    }, SetOptions(merge: true));
    setState(() {
      _isSaving = false;
      _savedDeviceId = deviceId;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device paired!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Pairing')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter Device ID:', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _deviceIdController,
              decoration: const InputDecoration(hintText: 'e.g. device_001'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveDevice,
                child: _isSaving ? const CircularProgressIndicator() : const Text('Pair Device'),
              ),
            ),
            if (_savedDeviceId != null) ...[
              const SizedBox(height: 32),
              const Text('Give these values to your ESP device:', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText('userId: ${widget.userId}'),
              SelectableText('deviceId: $_savedDeviceId'),
            ],
          ],
        ),
      ),
    );
  }
} 
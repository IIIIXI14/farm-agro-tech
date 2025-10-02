import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:firebase_core/firebase_core.dart';
import '../services/app_config.dart';
import 'device_detail_screen.dart';

class AddDeviceWaitScreen extends StatefulWidget {
  final String uid;
  final String? deviceId;
  final int? startTimeMs;
  const AddDeviceWaitScreen({
    super.key, 
    required this.uid, 
    this.deviceId,
    this.startTimeMs,
  });

  @override
  State<AddDeviceWaitScreen> createState() => _AddDeviceWaitScreenState();
}

class _AddDeviceWaitScreenState extends State<AddDeviceWaitScreen> {
  StreamSubscription? _subscription;
  Timer? _timeoutTimer;
  bool _found = false;

  @override
  void initState() {
    super.initState();
    _listenForRegistration();
    _timeoutTimer = Timer(const Duration(minutes: 2), () {
      if (!mounted || _found) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Still waiting for the device. Ensure Wi‑Fi credentials are correct and the device is powered.')),
      );
    });
  }

  void _listenForRegistration() {
    if (widget.deviceId != null) {
      // Listen for specific device
      _listenForSpecificDevice();
    } else {
      // Listen for any new device (fallback)
      _listenForAnyDevice();
    }
  }

  void _listenForSpecificDevice() {
    final deviceRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('devices')
        .doc(widget.deviceId);

    _subscription?.cancel();
    _subscription = deviceRef.snapshots().listen((snapshot) async {
      if (!mounted || _found) return;
      
      if (snapshot.exists) {
        final raw = snapshot.data();
        final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
        final status = (data['status'] ?? '').toString();
        final sensorData = data['sensorData'];
        final hasSensorData = sensorData is Map && sensorData.isNotEmpty;
        
        if (status == 'online' || hasSensorData) {
          // Try to fetch latest data from realtime database
          await _fetchLatestDataFromRealtimeDb();
          _found = true;
          // Navigate directly to the device details screen
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DeviceDetailScreen(
                uid: widget.uid,
                deviceId: widget.deviceId!,
              ),
            ),
          );
        }
      }
    });
  }

  void _listenForAnyDevice() {
    final userDevices = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('devices');

    Query query = userDevices.orderBy('createdAt', descending: true).limit(5);
    if (widget.startTimeMs != null) {
      final ts = Timestamp.fromMillisecondsSinceEpoch(widget.startTimeMs!);
      query = userDevices
          .where('createdAt', isGreaterThanOrEqualTo: ts)
          .orderBy('createdAt', descending: true)
          .limit(5);
    }

    _subscription?.cancel();
    _subscription = query.snapshots().listen((snapshot) {
      if (!mounted || _found) return;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = (data['status'] ?? '').toString();
        final sensorData = data['sensorData'];
        final hasSensorData = sensorData is Map && sensorData.isNotEmpty;
        if (status == 'online' || hasSensorData) {
          _found = true;
          // Fallback navigation when we don't know deviceId for detail screen
          if (!mounted) return;
          Navigator.pushReplacementNamed(
            context,
            '/my-devices',
            arguments: {'uid': widget.uid},
          );
          break;
        }
      }
    });
  }

  Future<void> _fetchLatestDataFromRealtimeDb() async {
    if (widget.deviceId == null) return;
    
    try {
      // Import Firebase Database
      final url = AppConfig.realtimeDbUrl;
      final db = rtdb.FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: url.isNotEmpty ? url : null,
      );
      
      final ref = db.ref('Users/${widget.uid}/devices/${widget.deviceId}');
      final snapshot = await ref.get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          // Update Firestore with latest realtime database data
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.uid)
              .collection('devices')
              .doc(widget.deviceId)
              .update({
            'sensorData': data['sensorData'] ?? {},
            'actuators': data['actuators'] ?? {},
            'status': data['status'] ?? 'online',
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finalizing')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 24),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Waiting for your device to come online...\nThis can take up to 1–2 minutes after entering Wi‑Fi credentials.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}



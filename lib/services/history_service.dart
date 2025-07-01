import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryService {
  final String uid;
  final String deviceId;

  HistoryService(this.uid, this.deviceId);

  Future<void> addHistoricalData(double temperature, double humidity) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .collection('history')
        .add({
          'temperature': temperature,
          'humidity': humidity,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  Stream<QuerySnapshot> getHistoricalData({int limitHours = 24}) {
    final DateTime limitTime = DateTime.now().subtract(Duration(hours: limitHours));
    
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .collection('history')
        .where('timestamp', isGreaterThan: limitTime)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getRecentHistory() {
    final startTime = DateTime.now().subtract(const Duration(hours: 24));
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .collection('history')
        .where('timestamp', isGreaterThanOrEqualTo: startTime)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  Future<List<QueryDocumentSnapshot>> getHistory(DateTime startTime) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .collection('history')
        .where('timestamp', isGreaterThanOrEqualTo: startTime)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs;
  }
} 
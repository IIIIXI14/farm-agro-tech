import 'package:cloud_firestore/cloud_firestore.dart';

class Schedule {
  final String id;
  final String actuator;
  final bool value;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> days;
  final bool isActive;

  Schedule({
    required this.id,
    required this.actuator,
    required this.value,
    required this.startTime,
    required this.endTime,
    required this.days,
    required this.isActive,
  });

  factory Schedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Schedule(
      id: doc.id,
      actuator: data['actuator'],
      value: data['value'],
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      days: List<String>.from(data['days']),
      isActive: data['isActive'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'actuator': actuator,
      'value': value,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'days': days,
      'isActive': isActive,
    };
  }
}

class ScheduleService {
  final String uid;
  final String deviceId;

  ScheduleService(this.uid, this.deviceId);

  Stream<QuerySnapshot> getSchedules() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .collection('schedules')
        .snapshots();
  }

  Future<void> addSchedule(Schedule schedule) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .collection('schedules')
        .add(schedule.toMap());
  }

  Future<void> updateSchedule(String scheduleId, Schedule schedule) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .collection('schedules')
        .doc(scheduleId)
        .update(schedule.toMap());
  }

  Future<void> deleteSchedule(String scheduleId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .collection('schedules')
        .doc(scheduleId)
        .delete();
  }

  Future<void> toggleSchedule(String scheduleId, bool isActive) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .collection('schedules')
        .doc(scheduleId)
        .update({'isActive': isActive});
  }
} 
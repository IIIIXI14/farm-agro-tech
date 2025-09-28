import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_config.dart';

class StreamManager {
  static final Map<String, StreamController<DatabaseEvent>> _controllers = {};
  static final Map<String, StreamSubscription<DatabaseEvent>> _subscriptions = {};
  static final Map<String, int> _listenerCount = {};

  static Stream<DatabaseEvent> getDeviceStream(String uid, String deviceId) {
    final key = 'device_$uid$deviceId';
    return _getOrCreateStream(key, () {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: AppConfig.realtimeDbUrl,
      );
      return db.ref('Users/$uid/Devices/$deviceId').onValue;
    });
  }

  static Stream<DatabaseEvent> getUserDevicesStream(String uid) {
    final key = 'user_devices_$uid';
    return _getOrCreateStream(key, () {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: AppConfig.realtimeDbUrl,
      );
      // Use user-scoped devices path
      return db.ref('Users/$uid/Devices').onValue;
    });
  }

  static Stream<DatabaseEvent> getActuatorStatusStream(String uid, String deviceId) {
    final key = 'actuator_$uid$deviceId';
    return _getOrCreateStream(key, () {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: AppConfig.realtimeDbUrl,
      );
      return db.ref('Users/$uid/Devices/$deviceId/Actuator_Status').onValue;
    });
  }

  static Stream<DatabaseEvent> _getOrCreateStream(String key, Stream<DatabaseEvent> Function() streamFactory) {
    if (_controllers.containsKey(key)) {
      _listenerCount[key] = (_listenerCount[key] ?? 0) + 1;
      return _controllers[key]!.stream;
    }

    final controller = StreamController<DatabaseEvent>.broadcast();
    _controllers[key] = controller;
    _listenerCount[key] = 1;

    // Create the Firebase stream and forward events to the broadcast controller
    final firebaseStream = streamFactory();
    _subscriptions[key] = firebaseStream.listen(
      (event) {
        if (!controller.isClosed) {
          controller.add(event);
        }
      },
      onError: (error) {
        if (!controller.isClosed) {
          controller.addError('Stream error: $error');
        }
      },
      onDone: () {
        if (!controller.isClosed) {
          controller.close();
        }
      },
    );

    return controller.stream.timeout(
      const Duration(seconds: 15),
      onTimeout: (eventSink) {
        eventSink.addError('Connection timeout. Please check your internet connection and try again.');
      },
    );
  }

  static void disposeStream(String key) {
    _listenerCount[key] = (_listenerCount[key] ?? 1) - 1;
    
    if (_listenerCount[key]! <= 0) {
      _subscriptions[key]?.cancel();
      _subscriptions.remove(key);
      _controllers[key]?.close();
      _controllers.remove(key);
      _listenerCount.remove(key);
    }
  }

  static void disposeAllStreams() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    for (final controller in _controllers.values) {
      controller.close();
    }
    _subscriptions.clear();
    _controllers.clear();
    _listenerCount.clear();
  }

  // Dispose streams only when app is actually closing
  static void disposeStreamsOnAppClose() {
    disposeAllStreams();
  }

  // Get current stream status for debugging
  static Map<String, dynamic> getStreamStatus() {
    return {
      'activeStreams': _controllers.keys.toList(),
      'listenerCounts': Map.from(_listenerCount),
      'subscriptionCount': _subscriptions.length,
    };
  }
}

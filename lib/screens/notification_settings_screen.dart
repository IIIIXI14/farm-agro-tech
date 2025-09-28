import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../services/local_notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _notificationsEnabled = true;
  bool _sensorAlertsEnabled = true;
  bool _deviceOfflineAlertsEnabled = true;
  bool _automationAlertsEnabled = true;
  bool _weatherAlertsEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      await _notificationService.initialize();
      
      setState(() {
        _notificationsEnabled = _notificationService.notificationsEnabled;
        _sensorAlertsEnabled = _notificationService.sensorAlertsEnabled;
        _deviceOfflineAlertsEnabled = _notificationService.deviceOfflineAlertsEnabled;
        _automationAlertsEnabled = _notificationService.automationAlertsEnabled;
        _weatherAlertsEnabled = _notificationService.weatherAlertsEnabled;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSettings() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _notificationService.updateNotificationSettings(
        notificationsEnabled: _notificationsEnabled,
        sensorAlertsEnabled: _sensorAlertsEnabled,
        deviceOfflineAlertsEnabled: _deviceOfflineAlertsEnabled,
        automationAlertsEnabled: _automationAlertsEnabled,
        weatherAlertsEnabled: _weatherAlertsEnabled,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testNotification() async {
    try {
      await _notificationService.sendSystemAlert(
        'Test Notification',
        'This is a test notification to verify your settings are working correctly.',
        data: {'test': true},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending test notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _testNotification,
            child: Text(
              'Test',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Main notification toggle
          Card(
            child: SwitchListTile(
              title: const Text(
                'Enable Notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Receive notifications about your farm devices'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                _updateSettings();
              },
              secondary: Icon(
                _notificationsEnabled ? Icons.notifications : Icons.notifications_off,
                color: _notificationsEnabled ? Colors.green : Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Notification types
          if (_notificationsEnabled) ...[
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Notification Types',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  
                  // Sensor alerts
                  SwitchListTile(
                    title: const Text('Sensor Alerts'),
                    subtitle: const Text('Temperature, humidity, and other sensor readings'),
                    value: _sensorAlertsEnabled,
                    onChanged: (value) {
                      setState(() => _sensorAlertsEnabled = value);
                      _updateSettings();
                    },
                    secondary: const Icon(Icons.warning, color: Colors.red),
                  ),
                  
                  const Divider(height: 1),
                  
                  // Device offline alerts
                  SwitchListTile(
                    title: const Text('Device Offline Alerts'),
                    subtitle: const Text('When your devices go offline'),
                    value: _deviceOfflineAlertsEnabled,
                    onChanged: (value) {
                      setState(() => _deviceOfflineAlertsEnabled = value);
                      _updateSettings();
                    },
                    secondary: const Icon(Icons.wifi_off, color: Colors.orange),
                  ),
                  
                  const Divider(height: 1),
                  
                  // Automation alerts
                  SwitchListTile(
                    title: const Text('Automation Alerts'),
                    subtitle: const Text('When automation rules are triggered'),
                    value: _automationAlertsEnabled,
                    onChanged: (value) {
                      setState(() => _automationAlertsEnabled = value);
                      _updateSettings();
                    },
                    secondary: const Icon(Icons.auto_awesome, color: Colors.blue),
                  ),
                  
                  const Divider(height: 1),
                  
                  // Weather alerts
                  SwitchListTile(
                    title: const Text('Weather Alerts'),
                    subtitle: const Text('Weather conditions affecting your farm'),
                    value: _weatherAlertsEnabled,
                    onChanged: (value) {
                      setState(() => _weatherAlertsEnabled = value);
                      _updateSettings();
                    },
                    secondary: const Icon(Icons.cloud, color: Colors.purple),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // System settings
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'System Settings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  
                  ListTile(
                    leading: const Icon(Icons.phone_android),
                    title: const Text('App Notifications'),
                    subtitle: const Text('Manage system notification permissions'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      final enabled = await LocalNotificationService.areNotificationsEnabled();
                      if (!enabled) {
                        await LocalNotificationService.openNotificationSettings();
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notifications are already enabled'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  
                  const Divider(height: 1),
                  
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About Notifications'),
                    subtitle: const Text('Learn more about notification types'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showNotificationInfo(),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Test notification button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _testNotification,
              icon: const Icon(Icons.send),
              label: const Text('Send Test Notification'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Notifications'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sensor Alerts',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Temperature outside normal range (10-40°C)\n• Humidity outside normal range (30-80%)\n• Soil moisture issues\n• pH level problems\n• High CO2 levels'),
              
              SizedBox(height: 16),
              
              Text(
                'Device Offline Alerts',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• When your farm devices lose connection\n• Helps you stay informed about device status'),
              
              SizedBox(height: 16),
              
              Text(
                'Automation Alerts',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• When automation rules are triggered\n• Motor, water, light, or other actuator activations'),
              
              SizedBox(height: 16),
              
              Text(
                'Weather Alerts',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Severe weather warnings\n• Temperature extremes\n• Precipitation alerts'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

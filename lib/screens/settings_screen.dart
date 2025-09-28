import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../services/theme_service.dart';
import '../services/notification_service.dart';
import 'notification_settings_screen.dart';
// import '../services/weather_service.dart';
// import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String uid;
  final bool embedded; // if true, renders content without Scaffold/AppBar

  const SettingsScreen({super.key, required this.uid, this.embedded = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _notificationsEnabled = true;
  bool _sensorAlertsEnabled = true;
  bool _deviceOfflineAlertsEnabled = true;
  bool _automationAlertsEnabled = true;
  bool _weatherAlertsEnabled = true;
  bool _weatherIntegrationEnabled = false;
  String _selectedLanguage = 'English';
  String _selectedUnit = 'Metric';
  
  // Dynamic device information
  int _deviceCount = 0;
  int _alertCount = 0;
  String _systemStatus = 'Online';
  DateTime? _lastUpdateTime;
  StreamSubscription<QuerySnapshot>? _devicesSubscription;
  StreamSubscription<QuerySnapshot>? _sensorReadingsSubscription;
  StreamSubscription<QuerySnapshot>? _alertsSubscription;
  String? _displayName;
  String? _photoUrl;
  bool _savingProfile = false;
  Uint8List? _photoBytes;
  
  // Additional profile information
  String? _email;
  String? _phone;
  String? _address;
  String? _farmName;
  String? _farmLocation;
  String? _farmSize;
  String? _cropType;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadDeviceInformation();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _devicesSubscription?.cancel();
    _sensorReadingsSubscription?.cancel();
    _alertsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    await _notificationService.initialize();
    setState(() {
      _notificationsEnabled = _notificationService.notificationsEnabled;
      _sensorAlertsEnabled = _notificationService.sensorAlertsEnabled;
      _deviceOfflineAlertsEnabled =
          _notificationService.deviceOfflineAlertsEnabled;
      _automationAlertsEnabled = _notificationService.automationAlertsEnabled;
      _weatherAlertsEnabled = _notificationService.weatherAlertsEnabled;
    });
  }

  void _loadDeviceInformation() {
    // Listen to devices collection for real-time updates
    _devicesSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('devices')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _deviceCount = snapshot.docs.length;
          _alertCount = _calculateAlertCount(snapshot.docs);
          _systemStatus = _calculateSystemStatus(snapshot.docs);
          _lastUpdateTime = DateTime.now();
        });
      }
    });

    // Listen to sensor readings for real-time alert updates
    _sensorReadingsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('sensorReadings')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _alertCount = _calculateAlertCountFromReadings(snapshot.docs);
          _lastUpdateTime = DateTime.now();
        });
      }
    });

    // Listen to alerts collection for real-time alert updates
    _alertsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('alerts')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _alertCount = snapshot.docs.length;
          _lastUpdateTime = DateTime.now();
        });
      }
    });
  }

  Future<void> _loadUserProfile() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
    if (mounted) {
      setState(() {
        _displayName = doc.data()?['displayName'] as String?;
        _photoUrl = doc.data()?['photoUrl'] as String?;
        final b64 = doc.data()?['photoBase64'] as String?;
        _photoBytes = (b64 != null && b64.isNotEmpty) ? base64Decode(b64) : null;
        
        // Load additional profile information
        _email = doc.data()?['email'] as String?;
        _phone = doc.data()?['phone'] as String?;
        _address = doc.data()?['address'] as String?;
        _farmName = doc.data()?['farmName'] as String?;
        _farmLocation = doc.data()?['farmLocation'] as String?;
        _farmSize = doc.data()?['farmSize'] as String?;
        _cropType = doc.data()?['cropType'] as String?;
      });
    }
  }


  Future<void> _saveProfileInfo(Map<String, String> profileData) async {
    setState(() { _savingProfile = true; });
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set(
        profileData,
        SetOptions(merge: true),
      );
      await _loadUserProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      setState(() { _savingProfile = false; });
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 70);
      if (picked == null) return;
      setState(() { _savingProfile = true; });
      final file = File(picked.path);
      try {
        final ref = FirebaseStorage.instance.ref().child('user_photos').child('${widget.uid}.jpg');
        await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
        final url = await ref.getDownloadURL();
        await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({'photoUrl': url, 'photoBase64': FieldValue.delete()}, SetOptions(merge: true));
        await _loadUserProfile();
      } catch (_) {
        // Storage not configured: fallback to Firestore base64
        final bytes = await file.readAsBytes();
        // Guard against Firestore 1MB limit: trim if too large
        if (bytes.lengthInBytes > 900 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image too large. Please choose a smaller image.')));
          }
        } else {
          final b64 = base64Encode(bytes);
          await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({'photoBase64': b64, 'photoUrl': FieldValue.delete()}, SetOptions(merge: true));
          await _loadUserProfile();
        }
      }
    } finally {
      if (mounted) setState(() { _savingProfile = false; });
    }
  }

  int _calculateAlertCount(List<QueryDocumentSnapshot> devices) {
    int alertCount = 0;
    
    for (final device in devices) {
      final data = device.data() as Map<String, dynamic>;
      
      // Check for offline devices
      final status = data['status'] as String? ?? 'offline';
      if (status == 'offline') {
        alertCount++;
      }
      
      // Check for sensor alerts (temperature, humidity thresholds)
      final sensorData = data['sensorData'] as Map<String, dynamic>?;
      if (sensorData != null) {
        final temperature = (sensorData['temperature'] as num?)?.toDouble() ?? 0.0;
        final humidity = (sensorData['humidity'] as num?)?.toDouble() ?? 0.0;
        
        // Temperature alerts (above 35°C or below 5°C)
        if (temperature > 35 || temperature < 5) {
          alertCount++;
        }
        
        // Humidity alerts (below 30% or above 90%)
        if (humidity < 30 || humidity > 90) {
          alertCount++;
        }
      }
    }
    
    return alertCount;
  }

  int _calculateAlertCountFromReadings(List<QueryDocumentSnapshot> readings) {
    int alertCount = 0;
    final now = DateTime.now();
    final Set<String> alertedDevices = <String>{};
    
    for (final reading in readings) {
      final data = reading.data() as Map<String, dynamic>;
      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
      
      // Only consider readings from the last 24 hours
      if (timestamp != null && now.difference(timestamp).inHours < 24) {
        // Extract device identifier - try deviceId first, then sensorId, then create composite
        final deviceId = data['deviceId'] as String? ?? 
                        data['sensorId'] as String? ?? 
                        '${data['deviceId'] ?? 'unknown'}_${data['sensorId'] ?? 'unknown'}';
        
        // Skip if we've already counted an alert for this device
        if (alertedDevices.contains(deviceId)) {
          continue;
        }
        
        final temperature = (data['temperature'] as num?)?.toDouble() ?? 0.0;
        final humidity = (data['humidity'] as num?)?.toDouble() ?? 0.0;
        final soilMoisture = (data['soilMoisture'] as num?)?.toDouble() ?? 0.0;
        
        // Check if any threshold is breached for this device
        bool hasAlert = false;
        
        // Temperature alerts (above 35°C or below 5°C)
        if (temperature > 35 || temperature < 5) {
          hasAlert = true;
        }
        
        // Humidity alerts (below 30% or above 90%)
        if (humidity < 30 || humidity > 90) {
          hasAlert = true;
        }
        
        // Soil moisture alerts (below 20% or above 80%)
        if (soilMoisture < 20 || soilMoisture > 80) {
          hasAlert = true;
        }
        
        // If any threshold is breached, count this device as having an alert
        if (hasAlert) {
          alertCount++;
          alertedDevices.add(deviceId);
        }
      }
    }
    
    return alertCount;
  }

  String _calculateSystemStatus(List<QueryDocumentSnapshot> devices) {
    if (devices.isEmpty) {
      return 'No Devices';
    }
    
    int onlineDevices = 0;
    int totalDevices = devices.length;
    
    for (final device in devices) {
      final data = device.data() as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'offline';
      if (status == 'online') {
        onlineDevices++;
      }
    }
    
    if (onlineDevices == 0) {
      return 'Offline';
    } else if (onlineDevices == totalDevices) {
      return 'Online';
    } else {
      return 'Partial';
    }
  }

  void _refreshDeviceInfo() {
    // Cancel current subscriptions and reload
    _devicesSubscription?.cancel();
    _sensorReadingsSubscription?.cancel();
    _alertsSubscription?.cancel();
    _loadDeviceInformation();
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing real-time data...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  String _formatLastUpdateTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    
    final lowerStatus = status.toLowerCase();
    if (lowerStatus == 'online' || lowerStatus == 'live' || lowerStatus == 'running') {
      return Colors.green;
    } else if (lowerStatus == 'degraded' || lowerStatus == 'warning' || lowerStatus == 'partial') {
      return Colors.orange;
    } else if (lowerStatus == 'down' || lowerStatus == 'offline') {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    if (status == null) return 'Unknown';
    
    final lowerStatus = status.toLowerCase();
    if (lowerStatus == 'online' || lowerStatus == 'live' || lowerStatus == 'running') {
      return 'Live';
    } else if (lowerStatus == 'degraded' || lowerStatus == 'warning') {
      return 'Warning';
    } else if (lowerStatus == 'partial') {
      return 'Partial';
    } else if (lowerStatus == 'down' || lowerStatus == 'offline') {
      return 'Offline';
    } else if (lowerStatus == 'no devices') {
      return 'No Devices';
    } else {
      return status;
    }
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserInfoCard(),
          const SizedBox(height: 16),
          _buildFarmInfoCard(),
          const SizedBox(height: 16),
          _buildThemeSettings(),
          const SizedBox(height: 16),
          _buildNotificationSettings(),
          const SizedBox(height: 16),
          _buildWeatherSettings(),
          const SizedBox(height: 16),
          _buildGeneralSettings(),
          const SizedBox(height: 16),
          _buildDataManagement(),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About & Legal'),
            subtitle: const Text('Version, Privacy Policy, Terms'),
            onTap: () => Navigator.pushNamed(context, '/about'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildContent(context);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: _buildContent(context),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with profile picture and basic info
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Theme.of(context).primaryColor,
                      backgroundImage: _photoUrl != null
                          ? NetworkImage(_photoUrl!)
                          : (_photoBytes != null ? MemoryImage(_photoBytes!) as ImageProvider : null),
                      child: (_photoUrl == null && _photoBytes == null)
                          ? const Icon(Icons.person, size: 32, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _savingProfile ? null : _pickAndUploadPhoto,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)],
                            border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName ?? 'Add your name',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        FirebaseAuth.instance.currentUser?.email ?? 'Unknown User',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'User ID: ${widget.uid.substring(0, 12)}...',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: _copyUserId,
                      tooltip: 'Copy User ID',
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _refreshDeviceInfo,
                      tooltip: 'Refresh Device Info',
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _compactButton(
                    icon: Icons.edit,
                    label: _savingProfile ? 'Saving...' : 'Edit Profile',
                    onPressed: _savingProfile ? null : _showEditProfileDialog,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _compactButton(
                    icon: Icons.photo_camera,
                    label: _savingProfile ? 'Uploading...' : 'Change Photo',
                    onPressed: _savingProfile ? null : _pickAndUploadPhoto,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // User information details
            if (_email != null || _phone != null || _address != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Contact Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 12),
              if (_email != null && _email!.isNotEmpty)
                _buildInfoRow(Icons.email, 'Email', _email!),
              if (_phone != null && _phone!.isNotEmpty)
                _buildInfoRow(Icons.phone, 'Phone', _phone!),
              if (_address != null && _address!.isNotEmpty)
                _buildInfoRow(Icons.location_on, 'Address', _address!),
              const SizedBox(height: 16),
            ],
            
            // System status chips
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'System Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getStatusColor(_systemStatus),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _getStatusText(_systemStatus),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(_systemStatus),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _statChip(icon: Icons.device_hub, label: 'Devices', value: '$_deviceCount'),
                _statChip(icon: Icons.notifications, label: 'Alerts', value: '$_alertCount'),
                _statChip(icon: Icons.wifi, label: 'Status', value: _systemStatus),
              ],
            ),
            if (_lastUpdateTime != null) ...[
              const SizedBox(height: 12),
              Text(
                'Last updated: ${_formatLastUpdateTime(_lastUpdateTime!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _compactButton({required IconData icon, required String label, VoidCallback? onPressed}) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: FilledButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 12)),
    );
  }

  Widget _statChip({required IconData icon, required String label, required String value}) {
    final Color color;
    if (label == 'Status') {
      if (value == 'Online') {
        color = Colors.green;
      } else if (value == 'Offline') {
        color = Colors.red;
      } else if (value == 'Partial') {
        color = Colors.orange;
      } else {
        color = Colors.grey;
      }
    } else if (label == 'Alerts' && int.tryParse(value) != null && int.parse(value) > 0) {
      color = Colors.red;
    } else {
      color = Theme.of(context).primaryColor;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text('$label: $value', style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }


  Widget _buildThemeSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Appearance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<ThemeService>(
              builder: (context, themeService, _) {
                return Column(
                  children: [
                    ListTile(
                      title: const Text('Dark Mode'),
                      subtitle:
                          const Text('Switch between light and dark themes'),
                      trailing: Switch(
                        value: themeService.isDarkMode,
                        onChanged: (value) {
                          themeService.setThemeMode(
                            value ? ThemeMode.dark : ThemeMode.light,
                          );
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('Auto Theme'),
                      subtitle: const Text('Follow system theme'),
                      trailing: Switch(
                        value: themeService.themeMode == ThemeMode.system,
                        onChanged: (value) {
                          themeService.setThemeMode(
                            value ? ThemeMode.system : ThemeMode.light,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications,
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NotificationSettingsScreen(),
                      ),
                    );
                  },
                  child: const Text('Advanced Settings'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: const Text('Receive push notifications'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                _notificationService.updateNotificationSettings(
                  notificationsEnabled: value,
                );
              },
            ),
            if (_notificationsEnabled) ...[
              SwitchListTile(
                title: const Text('Sensor Alerts'),
                subtitle:
                    const Text('Alerts when sensors detect abnormal values'),
                value: _sensorAlertsEnabled,
                onChanged: (value) {
                  setState(() {
                    _sensorAlertsEnabled = value;
                  });
                  _notificationService.updateNotificationSettings(
                    sensorAlertsEnabled: value,
                  );
                },
              ),
              SwitchListTile(
                title: const Text('Device Offline Alerts'),
                subtitle: const Text('Alerts when devices go offline'),
                value: _deviceOfflineAlertsEnabled,
                onChanged: (value) {
                  setState(() {
                    _deviceOfflineAlertsEnabled = value;
                  });
                  _notificationService.updateNotificationSettings(
                    deviceOfflineAlertsEnabled: value,
                  );
                },
              ),
              SwitchListTile(
                title: const Text('Automation Alerts'),
                subtitle:
                    const Text('Alerts when automation rules are triggered'),
                value: _automationAlertsEnabled,
                onChanged: (value) {
                  setState(() {
                    _automationAlertsEnabled = value;
                  });
                  _notificationService.updateNotificationSettings(
                    automationAlertsEnabled: value,
                  );
                },
              ),
              SwitchListTile(
                title: const Text('Weather Alerts'),
                subtitle: const Text('Alerts for weather conditions'),
                value: _weatherAlertsEnabled,
                onChanged: (value) {
                  setState(() {
                    _weatherAlertsEnabled = value;
                  });
                  _notificationService.updateNotificationSettings(
                    weatherAlertsEnabled: value,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Weather Integration',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Weather Integration'),
              subtitle:
                  const Text('Integrate weather data for better automation'),
              value: _weatherIntegrationEnabled,
              onChanged: (value) {
                setState(() {
                  _weatherIntegrationEnabled = value;
                });
              },
            ),
            if (_weatherIntegrationEnabled) ...[
              ListTile(
                title: const Text('Location'),
                subtitle: const Text('Set farm location for weather data'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Navigate to location settings
                },
              ),
              ListTile(
                title: const Text('Weather API Key'),
                subtitle: const Text('Configure OpenWeatherMap API'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Navigate to API settings
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'General',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Language'),
              subtitle: Text(_selectedLanguage),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showLanguageDialog,
            ),
            ListTile(
              title: const Text('Units'),
              subtitle: Text(_selectedUnit),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showUnitDialog,
            ),
            ListTile(
              title: const Text('Data Sync'),
              subtitle: const Text('Manage data synchronization'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showDataSyncDialog,
            ),
            ListTile(
              title: const Text('Device Settings'),
              subtitle: const Text('Configure device-specific settings'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showDeviceSettingsDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagement() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Data Management',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Export Data'),
              subtitle: const Text('Export your farm data'),
              leading: const Icon(Icons.download),
              onTap: () {
                // Implement data export
              },
            ),
            ListTile(
              title: const Text('Clear Cache'),
              subtitle: const Text('Clear local cache data'),
              leading: const Icon(Icons.clear_all),
              onTap: _showClearCacheDialog,
            ),
            ListTile(
              title: const Text('Backup Settings'),
              subtitle: const Text('Backup your app settings'),
              leading: const Icon(Icons.backup),
              onTap: () {
                // Implement settings backup
              },
            ),
          ],
        ),
      ),
    );
  }

  // _buildAboutSection removed; replaced by About screen entry above

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Spanish'),
              value: 'Spanish',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('French'),
              value: 'French',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUnitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Units'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Metric (°C, mm)'),
              value: 'Metric',
              groupValue: _selectedUnit,
              onChanged: (value) {
                setState(() {
                  _selectedUnit = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Imperial (°F, in)'),
              value: 'Imperial',
              groupValue: _selectedUnit,
              onChanged: (value) {
                setState(() {
                  _selectedUnit = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _copyUserId() {
    Clipboard.setData(ClipboardData(text: widget.uid));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User ID copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
            'This will clear all locally stored data. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implement cache clearing
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _displayName ?? '');
    final emailController = TextEditingController(text: _email ?? '');
    final phoneController = TextEditingController(text: _phone ?? '');
    final addressController = TextEditingController(text: _address ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final profileData = {
                'displayName': nameController.text.trim(),
                'email': emailController.text.trim(),
                'phone': phoneController.text.trim(),
                'address': addressController.text.trim(),
              };
              Navigator.pop(context);
              await _saveProfileInfo(profileData);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.agriculture,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Farm Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showEditFarmInfoDialog,
                  tooltip: 'Edit Farm Information',
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(Icons.agriculture, 'Farm Name', _farmName ?? 'Not set'),
            _buildInfoRow(Icons.location_on, 'Location', _farmLocation ?? 'Not set'),
            _buildInfoRow(Icons.straighten, 'Size', _farmSize ?? 'Not set'),
            _buildInfoRow(Icons.eco, 'Crop Type', _cropType ?? 'Not set'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditFarmInfoDialog() {
    final farmNameController = TextEditingController(text: _farmName ?? '');
    final farmLocationController = TextEditingController(text: _farmLocation ?? '');
    final farmSizeController = TextEditingController(text: _farmSize ?? '');
    final cropTypeController = TextEditingController(text: _cropType ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Farm Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: farmNameController,
                decoration: const InputDecoration(
                  labelText: 'Farm Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: farmLocationController,
                decoration: const InputDecoration(
                  labelText: 'Farm Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: farmSizeController,
                decoration: const InputDecoration(
                  labelText: 'Farm Size (acres/hectares)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cropTypeController,
                decoration: const InputDecoration(
                  labelText: 'Crop Type',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final farmData = {
                'farmName': farmNameController.text.trim(),
                'farmLocation': farmLocationController.text.trim(),
                'farmSize': farmSizeController.text.trim(),
                'cropType': cropTypeController.text.trim(),
              };
              Navigator.pop(context);
              await _saveProfileInfo(farmData);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDataSyncDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Synchronization'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Configure how your data is synchronized:'),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto Sync'),
              subtitle: const Text('Automatically sync data when online'),
              value: true, // This would be loaded from settings
              onChanged: (value) {
                // Implement auto sync toggle
              },
            ),
            SwitchListTile(
              title: const Text('Sync on WiFi Only'),
              subtitle: const Text('Only sync when connected to WiFi'),
              value: false, // This would be loaded from settings
              onChanged: (value) {
                // Implement WiFi-only sync toggle
              },
            ),
            ListTile(
              title: const Text('Sync Frequency'),
              subtitle: const Text('Every 5 minutes'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Show sync frequency options
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sync settings updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeviceSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Configure device-specific settings:'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Default Sensor Reading Interval'),
              subtitle: const Text('5 minutes'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Show interval options
              },
            ),
            ListTile(
              title: const Text('Device Timeout'),
              subtitle: const Text('10 minutes'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Show timeout options
              },
            ),
            SwitchListTile(
              title: const Text('Auto Device Discovery'),
              subtitle: const Text('Automatically discover new devices'),
              value: true,
              onChanged: (value) {
                // Implement auto discovery toggle
              },
            ),
            SwitchListTile(
              title: const Text('Device Health Monitoring'),
              subtitle: const Text('Monitor device health and performance'),
              value: true,
              onChanged: (value) {
                // Implement health monitoring toggle
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Device settings updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

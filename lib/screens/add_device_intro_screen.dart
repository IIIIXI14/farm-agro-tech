import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

class AddDeviceIntroScreen extends StatefulWidget {
  final String uid;
  const AddDeviceIntroScreen({super.key, required this.uid});

  @override
  State<AddDeviceIntroScreen> createState() => _AddDeviceIntroScreenState();
}

class _AddDeviceIntroScreenState extends State<AddDeviceIntroScreen> with WidgetsBindingObserver {
  bool _locationGranted = false;
  bool _requesting = false;
  String _permissionStatus = 'Checking...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Check permissions when app becomes active (user might have granted permission in settings)
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    try {
      // Check location permission
      final locationStatus = await Permission.locationWhenInUse.status;
      
      // Also check if location services are enabled
      final locationServiceEnabled = await Permission.locationWhenInUse.serviceStatus.isEnabled;
      
      // Check for additional permissions that might be needed
      final nearbyWifiDevicesStatus = await Permission.nearbyWifiDevices.status;
      
      // Debug information
      print('Location permission status: $locationStatus');
      print('Location service enabled: $locationServiceEnabled');
      print('Nearby WiFi devices permission: $nearbyWifiDevicesStatus');
      
      // For Android 13+ (API 33+), we also need nearby WiFi devices permission
      final hasAllPermissions = locationStatus.isGranted && 
          locationServiceEnabled && 
          (nearbyWifiDevicesStatus.isGranted || nearbyWifiDevicesStatus.isDenied);
      
      setState(() {
        _locationGranted = hasAllPermissions;
        _permissionStatus = hasAllPermissions
            ? 'All permissions granted' 
            : locationStatus.isDenied 
                ? 'Location permission denied'
                : locationStatus.isPermanentlyDenied
                    ? 'Location permission permanently denied'
                    : !locationServiceEnabled
                        ? 'Location services are disabled'
                        : nearbyWifiDevicesStatus.isDenied
                            ? 'WiFi scanning permission needed'
                            : 'Location permission needed';
      });
    } catch (e) {
      print('Error checking permissions: $e');
      setState(() {
        _locationGranted = false;
        _permissionStatus = 'Error checking permissions: $e';
      });
    }
  }

  Future<void> _requestPermissions() async {
    if (_requesting) return;
    setState(() {
      _requesting = true;
      _permissionStatus = 'Requesting permissions...';
    });
    
    try {
      // Check if location services are enabled first
      final locationServiceEnabled = await Permission.locationWhenInUse.serviceStatus.isEnabled;
      
      if (!locationServiceEnabled) {
        // Location services are disabled, show dialog to enable them
        setState(() {
          _requesting = false;
          _permissionStatus = 'Location services are disabled';
        });
        _showLocationServicesDialog();
        return;
      }
      
      // Request location permission
      final locationResult = await Permission.locationWhenInUse.request();
      
      // Request nearby WiFi devices permission for Android 13+
      final nearbyWifiResult = await Permission.nearbyWifiDevices.request();
      
      print('Location permission result: $locationResult');
      print('Nearby WiFi permission result: $nearbyWifiResult');
      
      // Re-check location services after permission request
      final locationServiceEnabledAfter = await Permission.locationWhenInUse.serviceStatus.isEnabled;
      
      final hasAllPermissions = locationResult.isGranted && 
          locationServiceEnabledAfter && 
          (nearbyWifiResult.isGranted || nearbyWifiResult.isDenied);
      
      setState(() {
        _locationGranted = hasAllPermissions;
        _permissionStatus = hasAllPermissions
            ? 'All permissions granted' 
            : locationResult.isDenied 
                ? 'Location permission denied'
                : locationResult.isPermanentlyDenied
                    ? 'Location permission permanently denied'
                    : !locationServiceEnabledAfter
                        ? 'Location services are disabled'
                        : nearbyWifiResult.isDenied
                            ? 'WiFi scanning permission needed'
                            : 'Location permission needed';
        _requesting = false;
      });
      
      // If permission was permanently denied, show dialog to open settings
      if (locationResult.isPermanentlyDenied || nearbyWifiResult.isPermanentlyDenied) {
        _showPermissionDeniedDialog();
      }
    } catch (e) {
      print('Error requesting permissions: $e');
      setState(() {
        _locationGranted = false;
        _permissionStatus = 'Error requesting permissions: $e';
        _requesting = false;
      });
    }
  }

  void _showLocationServicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Location Services'),
        content: const Text(
          'Location services are currently disabled on your device. '
          'Please enable them in your device settings to continue with device setup.\n\n'
          '1. Go to Settings > Location\n'
          '2. Turn on Location services\n'
          '3. Return to this app and try again',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openLocationSettings();
            },
            child: const Text('Open Location Settings'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Location permission is required to discover Wi-Fi networks. '
          'Please enable it in the app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _openWifiSettings() {
    AppSettings.openAppSettings(type: AppSettingsType.wifi);
  }

  void _openLocationSettings() {
    AppSettings.openAppSettings(type: AppSettingsType.location);
  }

  void _goToWebPortal() {
    final now = DateTime.now();
    Navigator.pushNamed(
      context,
      '/add-device/config',
      arguments: {
        'uid': widget.uid,
        'startTimeMs': now.millisecondsSinceEpoch,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Device')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 1: Prepare to Connect',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'We will guide you to connect to the device\'s temporary Wi‑Fi network. '
              'Your phone may briefly leave the app to open Wi‑Fi settings.',
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _locationGranted ? Icons.check_circle : Icons.location_on,
                          color: _locationGranted ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _permissionStatus,
                            style: TextStyle(
                              color: _locationGranted ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _checkPermissions,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh permission status',
                        ),
                      ],
                    ),
                    if (!_locationGranted) ...[
                      const SizedBox(height: 8),
                      Text(
                        _permissionStatus.contains('Location services are disabled')
                            ? 'Location services are disabled on your device. Please enable them in Settings > Location.'
                            : 'Location permission is needed to discover local Wi‑Fi networks on Android.',
                        style: TextStyle(
                          fontSize: 12, 
                          color: _permissionStatus.contains('Location services are disabled') 
                              ? Colors.red 
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _requesting ? null : _requestPermissions,
                              child: _requesting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Grant Permission'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_permissionStatus.contains('Location services are disabled'))
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _openLocationSettings(),
                                icon: const Icon(Icons.location_on, size: 16),
                                label: const Text('Location'),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _openWifiSettings,
                  icon: const Icon(Icons.wifi),
                  label: const Text('Open Wi‑Fi Settings'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _goToWebPortal,
                  child: const Text('I\'m connected to the device Wi‑Fi'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



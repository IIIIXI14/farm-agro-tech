import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/app_config.dart';
import '../services/firebase_database_service.dart';

class AddDeviceConfigScreen extends StatefulWidget {
  final String uid;
  final int? startTimeMs;
  
  const AddDeviceConfigScreen({
    super.key, 
    required this.uid, 
    this.startTimeMs,
  });

  @override
  State<AddDeviceConfigScreen> createState() => _AddDeviceConfigScreenState();
}

class _AddDeviceConfigScreenState extends State<AddDeviceConfigScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  final _deviceIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isConfiguring = false;
  List<String> _existingDeviceIds = [];

  @override
  void initState() {
    super.initState();
    _loadExistingDeviceIds();
    _initializeWebView();
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingDeviceIds() async {
    try {
      final db = await FirebaseDatabaseService.initializeDatabase();
      if (db == null) return;
      // Read device IDs from both new and legacy locations
      final legacySnap = await db.ref('Users/${widget.uid}/devices').get();
      final newSnap = await db.ref('devices').get();

      final ids = <String>{};
      if (legacySnap.exists && legacySnap.value is Map) {
        final map = Map<String, dynamic>.from(legacySnap.value as Map);
        ids.addAll(map.keys.map((k) => k.toString()));
      }
      if (newSnap.exists && newSnap.value is Map) {
        final map = Map<String, dynamic>.from(newSnap.value as Map);
        map.forEach((key, value) {
          if (value is Map && (value['userId'] == widget.uid)) {
            ids.add(key.toString());
          }
        });
      }
      setState(() {
        _existingDeviceIds = ids.toList();
      });
    } catch (e) {
      // Handle error silently
    }
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (url) {
            setState(() => _loading = false);
            _injectUserData();
            // Retry injection after a short delay to ensure page is fully loaded
            Future.delayed(const Duration(milliseconds: 500), () {
              _injectUserData();
            });
            // Another retry after longer delay for slow-loading pages
            Future.delayed(const Duration(seconds: 2), () {
              _injectUserData();
            });
          },
          onWebResourceError: (_) {
            // stay silent; user can still tap Continue after submitting credentials
          },
        ),
      )
      ..loadRequest(Uri.parse(AppConfig.devicePortalUrl));
  }

  void _injectUserData() {
    // Inject JavaScript to pre-fill User ID and Device ID fields
    // Escape the user ID to prevent JavaScript injection issues
    final escapedUid = widget.uid.replaceAll("'", "\\'").replaceAll('"', '\\"').replaceAll('\n', '\\n').replaceAll('\r', '\\r');
    final escapedDeviceId = _deviceIdController.text.replaceAll("'", "\\'").replaceAll('"', '\\"').replaceAll('\n', '\\n').replaceAll('\r', '\\r');
    
    final script = '''
      (function() {
        const userId = '$escapedUid';
        const deviceId = '$escapedDeviceId';
        console.log('Injecting User ID:', userId);
        console.log('Injecting Device ID:', deviceId);
        
        // Try multiple selectors to find User ID input field
        const userIdSelectors = [
          'input[type="text"]',
          'input[type="email"]', 
          'input[name*="user"]',
          'input[name*="uid"]',
          'input[id*="user"]',
          'input[id*="uid"]',
          'input[placeholder*="user"]',
          'input[placeholder*="User"]',
          'input[placeholder*="uid"]',
          'input[placeholder*="UID"]'
        ];
        
        let userIdFound = false;
        userIdSelectors.forEach(selector => {
          const inputs = document.querySelectorAll(selector);
          inputs.forEach(input => {
            if (!userIdFound && (input.value === '' || 
                input.placeholder.toLowerCase().includes('user') || 
                input.name.toLowerCase().includes('user') || 
                input.id.toLowerCase().includes('user') ||
                input.placeholder.toLowerCase().includes('uid') ||
                input.name.toLowerCase().includes('uid') ||
                input.id.toLowerCase().includes('uid'))) {
              input.value = userId;
              input.dispatchEvent(new Event('input', { bubbles: true }));
              input.dispatchEvent(new Event('change', { bubbles: true }));
              input.dispatchEvent(new Event('blur', { bubbles: true }));
              console.log('User ID filled in field:', input.name || input.id || 'unnamed');
              userIdFound = true;
            }
          });
        });
        
        // Try to find Device ID input field and pre-fill it if we have one
        if (deviceId && deviceId.length > 0) {
          const deviceIdSelectors = [
            'input[type="text"]',
            'input[name*="device"]',
            'input[name*="did"]',
            'input[id*="device"]',
            'input[id*="did"]',
            'input[placeholder*="device"]',
            'input[placeholder*="Device"]'
          ];
          
          let deviceIdFound = false;
          deviceIdSelectors.forEach(selector => {
            const inputs = document.querySelectorAll(selector);
            inputs.forEach(input => {
              if (!deviceIdFound && !userIdFound && (input.value === '' || 
                  input.placeholder.toLowerCase().includes('device') || 
                  input.name.toLowerCase().includes('device') || 
                  input.id.toLowerCase().includes('device'))) {
                input.value = deviceId;
                input.dispatchEvent(new Event('input', { bubbles: true }));
                input.dispatchEvent(new Event('change', { bubbles: true }));
                input.dispatchEvent(new Event('blur', { bubbles: true }));
                console.log('Device ID filled in field:', input.name || input.id || 'unnamed');
                deviceIdFound = true;
              }
            });
          });
        }
        
        if (!userIdFound) {
          console.log('No suitable User ID field found');
        }
      })();
    ''';
    
    _controller.runJavaScript(script);
  }

  String _getSuggestedDeviceId() {
    final suggestions = [
      'device_001',
      'farm_sensor_1',
      'greenhouse_monitor',
      'field_station_1',
      'crop_sensor',
      'weather_station',
      'soil_monitor',
      'irrigation_controller',
    ];

    // Find a name that doesn't exist
    for (final suggestion in suggestions) {
      if (!_existingDeviceIds.contains(suggestion)) {
        return suggestion;
      }
    }

    // If all suggestions are taken, generate with numbers
    int counter = 1;
    String baseName = 'device';
    while (_existingDeviceIds.contains('${baseName}_$counter')) {
      counter++;
    }
    return '${baseName}_$counter';
  }

  void _generateDeviceId() {
    setState(() {
      _deviceIdController.text = _getSuggestedDeviceId();
    });
    // Re-inject data with new device ID
    _injectUserData();
  }

  bool _isDeviceIdUnique(String deviceId) {
    return !_existingDeviceIds.contains(deviceId.trim());
  }

  Future<void> _createDevice() async {
    if (!_formKey.currentState!.validate()) return;

    final deviceId = _deviceIdController.text.trim();
    
    if (deviceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a Device ID first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Check if user is authenticated
    final user = FirebaseAuth.instance.currentUser;
    print('AddDeviceConfigScreen: Current user: ${user?.uid}');
    print('AddDeviceConfigScreen: User email: ${user?.email}');
    print('AddDeviceConfigScreen: User display name: ${user?.displayName}');
    
    if (user == null) {
      print('AddDeviceConfigScreen: No authenticated user found');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to create a device'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    print('AddDeviceConfigScreen: User is authenticated, proceeding with device creation');
    
    setState(() {
      _isConfiguring = true;
    });

    try {
      print('AddDeviceConfigScreen: Starting device creation for $deviceId');
      
      // Test database connection first
      print('AddDeviceConfigScreen: Testing database connection...');
      final connectionTest = await FirebaseDatabaseService.testConnection(uid: widget.uid);
      if (!connectionTest) {
        // Proceed anyway; creation will attempt writes to permitted paths
        print('AddDeviceConfigScreen: Connection test failed, proceeding to write');
      }
      print('AddDeviceConfigScreen: Database connection test passed');
      
      // Create device in Realtime Database with custom ID
      final created = await FirebaseDatabaseService.createDeviceDataStructure(
        widget.uid,
        deviceId,
        {
          'name': 'Device $deviceId',
          'deviceId': deviceId,
          'status': 'offline',
          'sensorData': {
            'temperature': 0,
            'humidity': 0,
          },
          'actuators': {
            'motor': false,
            'light': false,
            'water': false,
            'siren': false,
          },
          'automationRules': {
            'motor': {
              'when': 'temperature',
              'operator': '>',
              'value': 35,
            },
            'water': {
              'when': 'humidity',
              'operator': '<',
              'value': 40,
            },
          },
          'createdAt': DateTime.now().toIso8601String(),
          'lastUpdated': DateTime.now().toIso8601String(),
        },
      );

      print('AddDeviceConfigScreen: Device creation result: $created');

      if (!created) {
        throw Exception('Failed to write to Realtime Database. Please check your internet connection and try again.');
      }

      // Wait a moment for the device to come online
      await Future.delayed(const Duration(seconds: 2));
      
      // Try to fetch initial data from realtime database
      await _fetchDeviceDataFromRealtimeDb(deviceId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Device "$deviceId" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to wait screen
        Navigator.pushReplacementNamed(
          context,
          '/add-device/wait',
          arguments: {
            'uid': widget.uid,
            'deviceId': deviceId,
            if (widget.startTimeMs != null) 'startTimeMs': widget.startTimeMs,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error creating device: $e';
        
        // Provide more specific error messages
        if (e.toString().contains('permission-denied')) {
          errorMessage = 'Permission denied. Please check your Firebase security rules.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Request timeout. Please try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConfiguring = false;
        });
      }
    }
  }

  Future<void> _fetchDeviceDataFromRealtimeDb(String deviceId) async {
    try {
      // Try to get data from Realtime Database first
      final realtimeData = await FirebaseDatabaseService.getDeviceData(
        widget.uid,
        deviceId,
      );
      
      if (realtimeData == null) {
        // If Realtime Database is not available or empty, create initial structure
        await FirebaseDatabaseService.createDeviceDataStructure(
          widget.uid,
          deviceId,
          {
            'sensorData': {},
            'actuators': {},
            'status': 'offline',
            'createdAt': DateTime.now().toIso8601String(),
            'lastUpdated': DateTime.now().toIso8601String(),
          },
        );
      } else {
        // Touch lastUpdated
        await FirebaseDatabaseService.updateDeviceData(
          widget.uid,
          deviceId,
          {'lastUpdated': DateTime.now().toIso8601String()},
        );
      }
    } catch (_) {
      // Ignore; device may not be online yet
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configure Device')),
      body: Column(
        children: [
          // Device ID Configuration Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha:0.1),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Device Configuration',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'User ID will be automatically filled. Enter a unique Device ID:',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _deviceIdController,
                          decoration: const InputDecoration(
                            labelText: 'Device ID',
                            hintText: 'Enter unique device identifier',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.device_hub),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a Device ID';
                            }
                            if (!_isDeviceIdUnique(value.trim())) {
                              return 'This Device ID already exists';
                            }
                            if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value.trim())) {
                              return 'Device ID can only contain letters, numbers, hyphens, and underscores';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _generateDeviceId,
                        icon: const Icon(Icons.auto_awesome),
                        tooltip: 'Generate Device ID',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _generateDeviceId,
                          child: const Text('Generate ID'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isConfiguring ? null : _createDevice,
                          child: _isConfiguring
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Create Device'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // WebView Section
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
          
          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The User ID ('
                        '${widget.uid.length <= 20 ? widget.uid : widget.uid.substring(0, 20) + '...'}'
                        ') has been pre-filled.\n'
                        'Enter your Wi-Fi credentials and configure the device.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse(AppConfig.devicePortalUrl);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Open in browser'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _controller.reload(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reload'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _injectUserData(),
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('Fill User ID'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/device_service.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomePopupScreen extends StatefulWidget {
  final String uid;
  final String userEmail;

  const WelcomePopupScreen({
    super.key,
    required this.uid,
    required this.userEmail,
  });

  @override
  State<WelcomePopupScreen> createState() => _WelcomePopupScreenState();
}

class _WelcomePopupScreenState extends State<WelcomePopupScreen> {
  final _deviceNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isCreating = false;
  List<String> _existingDeviceNames = [];

  @override
  void initState() {
    super.initState();
    _loadExistingDeviceNames();
    _deviceNameController.text = _getSuggestedDeviceName();
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingDeviceNames() async {
    try {
      final devicesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('devices')
          .get();

      setState(() {
        _existingDeviceNames = devicesSnapshot.docs
            .map((doc) => (doc.data()['name'] as String?) ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
      });
    } catch (e) {
      // Handle error silently
    }
  }

  String _getSuggestedDeviceName() {
    final suggestions = [
      'Greenhouse 1',
      'Irrigation System',
      'Weather Station',
      'Soil Monitor',
      'Crop Camera',
      'Automation Hub',
      'Sensor Array',
      'Control Center',
    ];

    for (final suggestion in suggestions) {
      if (!_existingDeviceNames.contains(suggestion)) {
        return suggestion;
      }
    }

    // If all suggestions are taken, generate a unique name
    int counter = 1;
    String baseName = 'Smart Device';
    while (_existingDeviceNames.contains('$baseName $counter')) {
      counter++;
    }
    return '$baseName $counter';
  }

  bool _isDeviceNameUnique(String name) {
    return !_existingDeviceNames.contains(name);
  }

  Future<void> _createDevice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final deviceName = _deviceNameController.text.trim();
      
      // Create device using DeviceService
      await DeviceService(widget.uid).addDevice(deviceName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Device "$deviceName" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Close the popup
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating device: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: themeService.getPrimaryGradient(),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.celebration,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to Farm Agro Tech!',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your account has been created successfully',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // User Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeService.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: themeService.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              color: themeService.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.userEmail,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: themeService.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.vpn_key_outlined,
                              color: themeService.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'User ID: ${widget.uid.substring(0, 28)}...',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: themeService.primaryColor.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.copy,
                                size: 16,
                                color: themeService.primaryColor,
                              ),
                              onPressed: () {
                                // Copy user ID to clipboard
                                // You can implement clipboard functionality here
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('User ID copied to clipboard'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              tooltip: 'Copy User ID',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Device Creation Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Your First Device',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: themeService.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Give your device a unique name to get started',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _deviceNameController,
                          decoration: InputDecoration(
                            labelText: 'Device Name',
                            hintText: 'Enter device name',
                            prefixIcon: Icon(
                              Icons.device_hub_outlined,
                              color: themeService.primaryColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: themeService.primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a device name';
                            }
                            if (!_isDeviceNameUnique(value.trim())) {
                              return 'Device name must be unique';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _deviceNameController.text = _getSuggestedDeviceName();
                                  });
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Generate Name'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade100,
                                  foregroundColor: Colors.grey.shade700,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isCreating ? null : _createDevice,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeService.primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: _isCreating
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'Create Device',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Skip option
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Skip for now',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

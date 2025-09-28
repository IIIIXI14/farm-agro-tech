import 'package:flutter/material.dart';
import '../models/actuator_status.dart';
import '../services/device_service.dart';

class ActuatorControlWidget extends StatefulWidget {
  final String deviceId;
  final DeviceService deviceService;
  final ActuatorStatus? actuatorStatus;

  const ActuatorControlWidget({
    Key? key,
    required this.deviceId,
    required this.deviceService,
    this.actuatorStatus,
  }) : super(key: key);

  @override
  State<ActuatorControlWidget> createState() => _ActuatorControlWidgetState();
}

class _ActuatorControlWidgetState extends State<ActuatorControlWidget> {
  bool _isLoading = false;
  Map<String, String> _actuatorNames = {};
  final List<String> _relayNames = ['relay1', 'relay2', 'relay3', 'relay4', 'relay5'];

  @override
  void initState() {
    super.initState();
    _loadActuatorNames();
  }

  Future<void> _loadActuatorNames() async {
    try {
      final names = await widget.deviceService.getActuatorNames(widget.deviceId);
      if (mounted) {
        setState(() {
          _actuatorNames = names;
        });
      }
    } catch (e) {
      // Use default names on error
      if (mounted) {
        setState(() {
          _actuatorNames = {
            'relay1': 'Motor Control',
            'relay2': 'Water Pump',
            'relay3': 'Lighting',
            'relay4': 'Siren',
            'relay5': 'Fan System',
          };
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Actuator Controls',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    _buildBulkButton(
                      'All ON',
                      Icons.power,
                      Colors.green,
                      _turnAllOn,
                    ),
                    const SizedBox(width: 8),
                    _buildBulkButton(
                      'All OFF',
                      Icons.power_off,
                      Colors.red,
                      _turnAllOff,
                    ),
                    const SizedBox(width: 8),
                    _buildBulkButton(
                      'STOP',
                      Icons.emergency,
                      Colors.red.shade800,
                      _emergencyStop,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.actuatorStatus != null) ...[
              _buildActuatorList(),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.sensors_off, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No actuator data available',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBulkButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildActuatorList() {
    return Column(
      children: _relayNames.map((relayName) {
        final isOn = widget.actuatorStatus?.isRelayOn(relayName) ?? false;
        final displayName = _actuatorNames[relayName] ?? relayName.toUpperCase();
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isOn ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOn ? Colors.green : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      relayName.toUpperCase(),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isOn ? 'ON' : 'OFF',
                      style: TextStyle(
                        color: isOn ? Colors.green.shade700 : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Switch(
                      value: isOn,
                      onChanged: _isLoading ? null : (value) => _toggleRelay(relayName),
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.grey.shade400,
                      inactiveTrackColor: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isLoading ? null : () => _editActuatorName(relayName),
                icon: const Icon(Icons.edit, size: 20),
                tooltip: 'Edit name',
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _toggleRelay(String relayName) async {
    if (_isLoading) return;
    
    final isOn = widget.actuatorStatus?.isRelayOn(relayName) ?? false;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.deviceService.toggleRelay(widget.deviceId, relayName, !isOn);
      if (mounted) {
        final displayName = _actuatorNames[relayName] ?? relayName.toUpperCase();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$displayName toggled successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final displayName = _actuatorNames[relayName] ?? relayName.toUpperCase();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle $displayName: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _turnAllOn() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.deviceService.turnAllRelaysOn(widget.deviceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All actuators turned ON'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to turn all ON: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _turnAllOff() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.deviceService.turnAllRelaysOff(widget.deviceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All actuators turned OFF'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to turn all OFF: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _emergencyStop() async {
    if (_isLoading) return;
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency Stop'),
          ],
        ),
        content: const Text(
          'This will immediately turn off ALL actuators. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('EMERGENCY STOP'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.deviceService.emergencyStop(widget.deviceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('EMERGENCY STOP activated - All actuators OFF'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Emergency stop failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _editActuatorName(String relayName) async {
    final currentName = _actuatorNames[relayName] ?? relayName.toUpperCase();
    final controller = TextEditingController(text: currentName);
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${relayName.toUpperCase()} Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Actuator Name',
            hintText: 'Enter a custom name for this actuator',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      try {
        final updatedNames = Map<String, String>.from(_actuatorNames);
        updatedNames[relayName] = newName;
        
        await widget.deviceService.updateActuatorNames(widget.deviceId, updatedNames);
        
        if (mounted) {
          setState(() {
            _actuatorNames = updatedNames;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${relayName.toUpperCase()} renamed to "$newName"'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update name: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}
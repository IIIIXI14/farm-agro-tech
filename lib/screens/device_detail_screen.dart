import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/device_service.dart';
import '../services/history_service.dart';
import '../services/schedule_service.dart';
import '../services/theme_service.dart';
import '../widgets/sensor_history_chart.dart';
import '../screens/sensor_history_screen.dart';
import '../widgets/sensor_chart.dart';
import '../services/data_repository.dart';
import '../models/sensor_reading.dart';
import 'package:intl/intl.dart';

class DeviceDetailScreen extends StatefulWidget {
  final String uid;
  final String deviceId;
  const DeviceDetailScreen({Key? key, required this.uid, required this.deviceId}) : super(key: key);

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> with SingleTickerProviderStateMixin {
  final Map<String, bool> _loading = {};
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  late TabController _tabController;
  late HistoryService _historyService;
  late ScheduleService _scheduleService;

  // For sensor readings
  late Future<List<SensorReading>> _sensorReadingsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _historyService = HistoryService(widget.uid, widget.deviceId);
    _scheduleService = ScheduleService(widget.uid, widget.deviceId);
    _sensorReadingsFuture = DataRepository.getSensorReadings(widget.deviceId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _toggleActuator(String actuator, bool value, DeviceService deviceService) async {
    setState(() {
      _loading[actuator] = true;
    });
    try {
      await deviceService.toggleActuator(widget.deviceId, actuator, value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(value ? Icons.check_circle : Icons.info, color: Colors.white),
                const SizedBox(width: 8),
                Text('${actuator[0].toUpperCase()}${actuator.substring(1)} turned ${value ? 'ON' : 'OFF'}'),
              ],
            ),
            backgroundColor: value ? Colors.green : Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Failed to update $actuator: $e'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _loading[actuator] = false;
      });
    }
  }

  Future<void> _confirmAndToggle(String actuator, bool value, DeviceService deviceService) async {
    final critical = actuator == 'motor' || actuator == 'siren';
    if (!critical) {
      await _toggleActuator(actuator, value, deviceService);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm ${value ? 'Activation' : 'Deactivation'}'),
        content: Text('Are you sure you want to turn ${value ? 'ON' : 'OFF'} the $actuator?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: value ? Colors.green : Colors.red,
            ),
            child: Text(value ? 'TURN ON' : 'TURN OFF'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _toggleActuator(actuator, value, deviceService);
    }
  }

  Future<void> _addSchedule(String actuator) async {
    TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (startTime == null) return;

    TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    if (endTime == null) return;

    final now = DateTime.now();
    final schedule = Schedule(
      id: '',
      actuator: actuator,
      value: true,
      startTime: DateTime(
        now.year,
        now.month,
        now.day,
        startTime.hour,
        startTime.minute,
      ),
      endTime: DateTime(
        now.year,
        now.month,
        now.day,
        endTime.hour,
        endTime.minute,
      ),
      days: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
      isActive: true,
    );

    try {
      await _scheduleService.addSchedule(schedule);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add schedule: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildActuatorCard(
    String title,
    String actuator,
    IconData icon,
    Map<String, dynamic> data,
    DeviceService deviceService,
  ) {
    final actuators = Map<String, dynamic>.from(data['actuators'] ?? {});
    final isOn = actuators[actuator] ?? false;
    final isLoading = _loading[actuator] ?? false;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: isLoading
            ? null
            : () async {
                setState(() => _loading[actuator] = true);
                try {
                  await deviceService.toggleActuator(
                    widget.deviceId,
                    actuator,
                    !isOn,
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to toggle $actuator: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _loading[actuator] = false);
                  }
                }
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isOn ? Theme.of(context).primaryColor : Colors.grey,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: isOn ? Theme.of(context).primaryColor : null,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              if (isLoading)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              else
                Text(
                  isOn ? 'ON' : 'OFF',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOn ? Theme.of(context).primaryColor : Colors.grey,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsTab(Map<String, dynamic> data, DeviceService deviceService) {
    final sensorData = Map<String, dynamic>.from(data['sensorData'] ?? {});
    final temperature = sensorData['temperature'] ?? 0.0;
    final humidity = sensorData['humidity'] ?? 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SensorChart(uid: widget.uid, deviceId: widget.deviceId),
        const SizedBox(height: 24),
        const Text(
          'Actuator Controls',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActuatorCard(
                'Motor',
                'motor',
                Icons.agriculture,
                data,
                deviceService,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActuatorCard(
                'Light',
                'light',
                Icons.lightbulb,
                data,
                deviceService,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActuatorCard(
                'Water',
                'water',
                Icons.opacity,
                data,
                deviceService,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActuatorCard(
                'Siren',
                'siren',
                Icons.notifications_active,
                data,
                deviceService,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _historyService.getRecentHistory(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No historical data available'));
        }

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SensorHistoryChart(
                    historyData: docs,
                    title: 'Temperature History',
                    lineColor: Colors.orange,
                    valueType: 'temperature',
                    unit: '°C',
                  ),
                  const SizedBox(height: 16),
                  SensorHistoryChart(
                    historyData: docs,
                    title: 'Humidity History',
                    lineColor: Colors.blue,
                    valueType: 'humidity',
                    unit: '%',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SensorHistoryScreen(
                        uid: widget.uid,
                        deviceId: widget.deviceId,
                        deviceName: snapshot.data!.docs.first.reference.parent.parent!.id,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('View Detailed History'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSchedulesTab(Map<String, dynamic> data, DeviceService deviceService) {
    return StreamBuilder<QuerySnapshot>(
      stream: _scheduleService.getSchedules(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No schedules yet'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _addSchedule('motor'),
                  child: const Text('Add Schedule'),
                ),
              ],
            ),
          );
        }

        final schedules = snapshot.data!.docs
            .map((doc) => Schedule.fromFirestore(doc))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final schedule = schedules[index];
            return Card(
              child: ListTile(
                leading: Icon(
                  _getActuatorIcon(schedule.actuator),
                  color: schedule.isActive ? _getActuatorColor(schedule.actuator) : Colors.grey,
                ),
                title: Text(
                  '${schedule.actuator[0].toUpperCase()}${schedule.actuator.substring(1)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${_formatTime(schedule.startTime)} - ${_formatTime(schedule.endTime)}\n'
                  '${schedule.days.join(", ")}',
                ),
                trailing: Switch(
                  value: schedule.isActive,
                  onChanged: (value) => _scheduleService.toggleSchedule(schedule.id, value),
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAutomationRulesTab(Map<String, dynamic> data, DeviceService deviceService) {
    final automationRules = Map<String, dynamic>.from(data['automationRules'] ?? {});
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: ['motor', 'light', 'water', 'siren'].map((actuator) {
        final rule = automationRules[actuator];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getActuatorIcon(actuator),
                      color: _getActuatorColor(actuator),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$actuator Rule',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (rule != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Rule'),
                              content: Text(
                                'Are you sure you want to delete the automation rule for $actuator?'
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('CANCEL'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('DELETE'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            try {
                              await deviceService.deleteAutomationRule(
                                widget.deviceId,
                                actuator,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Rule deleted successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to delete rule: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                  ],
                ),
                if (rule == null)
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Rule'),
                      onPressed: () => _showAddRuleDialog(actuator, deviceService),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'When',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: rule['when'],
                                      isExpanded: true,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'temperature',
                                          child: Text('Temperature'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'humidity',
                                          child: Text('Humidity'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          deviceService.updateAutomationRule(
                                            widget.deviceId,
                                            actuator,
                                            AutomationRule(
                                              when: value,
                                              operator: rule['operator'],
                                              value: rule['value'],
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Operator',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: rule['operator'],
                                      isExpanded: true,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      items: const [
                                        DropdownMenuItem(
                                          value: '>',
                                          child: Text('Greater than (>)'),
                                        ),
                                        DropdownMenuItem(
                                          value: '<',
                                          child: Text('Less than (<)'),
                                        ),
                                        DropdownMenuItem(
                                          value: '>=',
                                          child: Text('Greater or equal (≥)'),
                                        ),
                                        DropdownMenuItem(
                                          value: '<=',
                                          child: Text('Less or equal (≤)'),
                                        ),
                                        DropdownMenuItem(
                                          value: '==',
                                          child: Text('Equal to (=)'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          deviceService.updateAutomationRule(
                                            widget.deviceId,
                                            actuator,
                                            AutomationRule(
                                              when: rule['when'],
                                              operator: value,
                                              value: rule['value'],
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: Theme.of(context).primaryColor,
                          inactiveTrackColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          thumbColor: Theme.of(context).primaryColor,
                          overlayColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: (rule['value'] as num).toDouble(),
                          min: rule['when'] == 'temperature' ? 0 : 0,
                          max: rule['when'] == 'temperature' ? 50 : 100,
                          divisions: rule['when'] == 'temperature' ? 50 : 100,
                          onChanged: (value) {
                            deviceService.updateAutomationRule(
                              widget.deviceId,
                              actuator,
                              AutomationRule(
                                when: rule['when'],
                                operator: rule['operator'],
                                value: value,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Turn ON when ${rule['when']} is ${rule['operator']} ${rule['value']}${rule['when'] == 'temperature' ? '°C' : '%'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showAddRuleDialog(String actuator, DeviceService deviceService) async {
    String when = 'temperature';
    String operator = '>';
    double value = 35;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add Rule for ${actuator[0].toUpperCase()}${actuator.substring(1)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: when,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    items: const [
                      DropdownMenuItem(
                        value: 'temperature',
                        child: Text('Temperature'),
                      ),
                      DropdownMenuItem(
                        value: 'humidity',
                        child: Text('Humidity'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => when = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: operator,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    items: const [
                      DropdownMenuItem(
                        value: '>',
                        child: Text('Greater than (>)'),
                      ),
                      DropdownMenuItem(
                        value: '<',
                        child: Text('Less than (<)'),
                      ),
                      DropdownMenuItem(
                        value: '>=',
                        child: Text('Greater or equal (≥)'),
                      ),
                      DropdownMenuItem(
                        value: '<=',
                        child: Text('Less or equal (≤)'),
                      ),
                      DropdownMenuItem(
                        value: '==',
                        child: Text('Equal to (=)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => operator = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: Theme.of(context).primaryColor,
                  inactiveTrackColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  thumbColor: Theme.of(context).primaryColor,
                  overlayColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: value,
                  min: when == 'temperature' ? 0 : 0,
                  max: when == 'temperature' ? 50 : 100,
                  divisions: when == 'temperature' ? 50 : 100,
                  onChanged: (v) => setState(() => value = v),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Turn ON when $when is $operator $value${when == 'temperature' ? '°C' : '%'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('ADD'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        await deviceService.updateAutomationRule(
          widget.deviceId,
          actuator,
          AutomationRule(
            when: when,
            operator: operator,
            value: value,
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rule added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add rule: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  IconData _getActuatorIcon(String actuator) {
    switch (actuator) {
      case 'motor':
        return Icons.agriculture;
      case 'light':
        return Icons.lightbulb;
      case 'water':
        return Icons.opacity;
      case 'siren':
        return Icons.notifications_active;
      default:
        return Icons.device_hub;
    }
  }

  Color _getActuatorColor(String actuator) {
    switch (actuator) {
      case 'motor':
        return Colors.brown;
      case 'light':
        return Colors.amber;
      case 'water':
        return Colors.blue;
      case 'siren':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final deviceRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('devices')
        .doc(widget.deviceId);
    final deviceService = DeviceService(widget.uid);
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      key: _scaffoldMessengerKey,
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: deviceRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Text('Device Control');
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            final name = data?['name'] ?? 'Unnamed Device';
            return Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () async {
                    final controller = TextEditingController(text: name);
                    final newName = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Edit Device Name'),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            labelText: 'Device Name',
                            border: OutlineInputBorder(),
                          ),
                          autofocus: true,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('CANCEL'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, controller.text),
                            child: const Text('SAVE'),
                          ),
                        ],
                      ),
                    );

                    if (newName != null && newName.isNotEmpty && mounted) {
                      try {
                        await deviceService.updateDeviceName(widget.deviceId, newName);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Device name updated successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update device name: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeService.toggleTheme(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'delete':
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Device'),
                      content: const Text(
                        'Are you sure you want to delete this device? This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('CANCEL'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('DELETE'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && mounted) {
                    try {
                      await deviceService.deleteDevice(widget.deviceId);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Device deleted successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to delete device: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Device'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Controls'),
            Tab(text: 'History'),
            Tab(text: 'Schedules'),
            Tab(text: 'Rules'),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: deviceRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return const Center(child: Text('Device not found.'));
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildControlsTab(data, deviceService),
              // History Tab: show readings as a simple list
              FutureBuilder<List<SensorReading>>(
                future: _sensorReadingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading sensor data'));
                  }
                  final readings = snapshot.data ?? [];
                  if (readings.isEmpty) {
                    return const Center(child: Text('No sensor data available'));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: readings.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final r = readings[index];
                      return ListTile(
                        leading: const Icon(Icons.thermostat),
                        title: Text('Temp: ${r.temperature.toStringAsFixed(1)}°C, Humidity: ${r.humidity.toStringAsFixed(1)}%'),
                        subtitle: Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(r.timestamp)),
                      );
                    },
                  );
                },
              ),
              _buildSchedulesTab(data, deviceService),
              _buildAutomationRulesTab(data, deviceService),
            ],
          );
        },
      ),
    );
  }
} 

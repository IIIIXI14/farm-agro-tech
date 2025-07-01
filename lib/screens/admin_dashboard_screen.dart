import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/admin_service.dart';
import '../services/device_service.dart';
import '../services/log_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  final _deviceSearchController = TextEditingController();
  String _deviceSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    _deviceSearchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _safeGet(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return {
      'email': data['email'] ?? 'No Email',
      'isAdmin': data['isAdmin'] ?? false,
      'isActive': data['isActive'] ?? true,
      'lastLogin': data['lastLogin'],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛠 Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.devices), text: 'Devices'),
            Tab(icon: Icon(Icons.analytics), text: 'System'),
            Tab(icon: Icon(Icons.history), text: 'Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(),
          _buildDevicesTab(),
          _buildSystemTab(),
          _buildLogsTab(),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: 'Search Users',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        setState(() => searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) => setState(() => searchQuery = value),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!.docs.where((doc) {
                final data = _safeGet(doc);
                final email = data['email'] as String;
                return searchQuery.isEmpty ||
                    email.toLowerCase().contains(searchQuery.toLowerCase());
              }).toList();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard(
                              '👥 Total Users',
                              users.length.toString(),
                              Colors.blue,
                            ),
                            _buildStatCard(
                              '🛡 Admins',
                              users.where((doc) => _safeGet(doc)['isAdmin'] == true).length.toString(),
                              Colors.amber,
                            ),
                            _buildStatCard(
                              '✅ Active',
                              users.where((doc) => _safeGet(doc)['isActive'] == true).length.toString(),
                              Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final uid = user.id;
                        final data = _safeGet(user);
                        final email = data['email'] as String;
                        final isAdmin = data['isAdmin'] as bool;
                        final isActive = data['isActive'] as bool;
                        final lastLogin = data['lastLogin'] as Timestamp?;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        email,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'UID: $uid',
                                        style: Theme.of(context).textTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (lastLogin != null)
                                        Text(
                                          'Last Login: ${lastLogin.toDate().toString().split('.').first}',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Row(
                                        children: [
                                          const Text('Admin',
                                              style: TextStyle(fontSize: 14)),
                                          Switch(
                                            value: isAdmin,
                                            onChanged: (val) async {
                                              await AdminService.toggleAdminStatus(uid, val);
                                            },
                                            activeColor: Colors.amber,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 16),
                                      Row(
                                        children: [
                                          const Text('Active',
                                              style: TextStyle(fontSize: 14)),
                                          Switch(
                                            value: isActive,
                                            onChanged: (val) async {
                                              await AdminService.updateUserStatus(uid, val);
                                            },
                                            activeColor: Colors.green,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDevicesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collectionGroup('devices').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final devices = snapshot.data!.docs;
        final onlineDevices = devices.where((d) => d['status'] == 'online').length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        '📱 Total Devices',
                        devices.length.toString(),
                        Colors.purple,
                      ),
                      _buildStatCard(
                        '🟢 Online',
                        onlineDevices.toString(),
                        Colors.green,
                      ),
                      _buildStatCard(
                        '🔴 Offline',
                        (devices.length - onlineDevices).toString(),
                        Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  final deviceId = device.id;
                  final status = device['status'] ?? 'unknown';
                  final lastUpdate = device['lastUpdate'] as Timestamp?;
                  final owner = device.reference.parent.parent?.id ?? 'Unknown';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.circle,
                        color: status == 'online' ? Colors.green : Colors.red,
                      ),
                      title: Text('Device: $deviceId'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Owner: $owner'),
                          if (lastUpdate != null)
                            Text(
                              'Last Update: ${lastUpdate.toDate().toString().split('.').first}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Device'),
                              content: const Text(
                                'Are you sure you want to delete this device? This action cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await device.reference.delete();
                            await LogService.logDeviceAction(
                              owner,
                              deviceId,
                              'Device deleted by admin',
                              type: LogType.warning,
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSystemTab() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: AdminService.systemStatsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📊 System Statistics',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      _buildStatRow('Total Users', stats['totalUsers'].toString()),
                      _buildStatRow('Active Users', stats['activeUsers'].toString()),
                      _buildStatRow('Total Devices', stats['totalDevices'].toString()),
                      _buildStatRow('Active Devices', stats['activeDevices'].toString()),
                      const Divider(),
                      Text(
                        'Last Updated: ${stats['lastUpdated'].toString().split('.').first}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Clean Inactive Devices'),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clean Inactive Devices'),
                      content: const Text(
                        'This will remove all devices that have been offline for more than 30 days. Continue?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clean'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await AdminService.deleteInactiveDevices();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Inactive devices cleaned successfully'),
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.backup),
                label: const Text('Backup System Data'),
                onPressed: () async {
                  try {
                    await AdminService.backupSystemData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('System backup completed successfully'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Backup failed: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('system_logs')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final logs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index].data() as Map<String, dynamic>;
            final timestamp = (log['timestamp'] as Timestamp).toDate();
            final message = log['message'] as String;
            final type = log['type'] as String;

            Color getLogColor() {
              switch (type) {
                case 'error':
                  return Colors.red;
                case 'warning':
                  return Colors.orange;
                case 'success':
                  return Colors.green;
                default:
                  return Colors.blue;
              }
            }

            IconData getLogIcon() {
              switch (type) {
                case 'error':
                  return Icons.error;
                case 'warning':
                  return Icons.warning;
                case 'success':
                  return Icons.check_circle;
                default:
                  return Icons.info;
              }
            }

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              child: ListTile(
                leading: Icon(
                  getLogIcon(),
                  color: getLogColor(),
                ),
                title: Text(message),
                subtitle: Text(
                  timestamp.toString().split('.').first,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 
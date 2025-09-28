import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/admin_service.dart';
import '../services/migration_service.dart';
import '../widgets/dashboard_overview.dart';
import '../widgets/notification_badge.dart';
import 'my_devices_screen.dart';
import 'settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/app_config.dart';

class HomeScreen extends StatefulWidget {
  final String uid;
  const HomeScreen({super.key, required this.uid});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _migrationCompleted = false;

  @override
  void initState() {
    super.initState();
    _performMigration();
  }

  Future<void> _performMigration() async {
    try {
      // Check if user's devices have been migrated
      final isMigrated = await MigrationService.isUserMigrated(widget.uid);
      
      if (!isMigrated) {
        // Perform migration
        final success = await MigrationService.migrateUserDevices(widget.uid);
        if (success) {
          print('Device migration completed for user ${widget.uid}');
        } else {
          print('Device migration failed for user ${widget.uid}');
        }
      }
      
      if (mounted) {
        setState(() {
          _migrationCompleted = true;
        });
      }
    } catch (e) {
      print('Error during migration: $e');
      if (mounted) {
        setState(() {
          _migrationCompleted = true;
        });
      }
    }
  }

  @override
  void dispose() {
    // Don't dispose all streams here as other screens might still need them
    // Streams will be disposed when the app is actually closed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    // Show loading while migration is in progress
    if (!_migrationCompleted) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Setting up your devices...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: StreamBuilder<DatabaseEvent>(
          stream: FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL: AppConfig.realtimeDbUrl,
          ).ref('Users/${widget.uid}/Profile').onValue,
          builder: (context, snapshot) {
            final data = snapshot.data?.snapshot.value is Map
                ? Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map)
                : <String, dynamic>{};
            final displayName = data['displayName'] as String?;
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.eco,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    (displayName == null || displayName.isEmpty) ? 'Farm Agro Tech' : displayName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          const NotificationBadge(),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                  themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => themeService.toggleTheme(),
              tooltip: 'Toggle Theme',
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Menu',
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'settings', child: ListTile(leading: Icon(Icons.settings), title: Text('Settings'))),
              const PopupMenuItem(value: 'admin', child: ListTile(leading: Icon(Icons.admin_panel_settings), title: Text('Admin Panel'))),
              const PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout), title: Text('Logout'))),
            ],
            onSelected: (value) async {
              if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SettingsScreen(uid: widget.uid)),
                );
              } else if (value == 'admin') {
                final isAdmin = await AdminService.isUserAdmin(widget.uid);
                if (isAdmin && context.mounted) {
                  Navigator.pushNamed(context, '/admin');
                }
              } else if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Enhanced Tab Bar with proper theme styling
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TabBar(
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.dashboard, size: 18),
                        SizedBox(width: 8),
                        Text('Dashboard'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.device_hub, size: 18),
                        SizedBox(width: 8),
                        Text('Devices'),
                      ],
                    ),
                  ),
                ],
                labelColor: themeService.primaryColor,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: themeService.primaryColor,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                // Enhanced tab bar styling
                dividerColor: Colors.transparent,
                indicatorWeight: 3,
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  DashboardOverview(uid: widget.uid),
                  MyDevicesScreen(uid: widget.uid),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: themeService.getPrimaryGradient(),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: themeService.primaryColor.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/add-device/intro',
              arguments: {'uid': widget.uid},
            );
          },
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add Device',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }
}

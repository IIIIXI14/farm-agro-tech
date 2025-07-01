import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/admin_service.dart';
import '../widgets/offline_status_widget.dart';
import 'login_screen.dart';
import 'my_devices_screen.dart';

class HomeScreen extends StatelessWidget {
  final String uid;
  const HomeScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Agro Tech'),
        actions: [
          FutureBuilder<bool>(
            future: AdminService.isUserAdmin(uid),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data == true) {
                return IconButton(
                  icon: const Icon(Icons.admin_panel_settings),
                  tooltip: 'Admin Panel',
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin');
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: Icon(themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeService.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          OfflineStatusWidget(userId: uid),
          Expanded(child: MyDevicesScreen(uid: uid)),
        ],
      ),
    );
  }
} 
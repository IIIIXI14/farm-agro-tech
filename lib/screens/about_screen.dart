import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About & Legal')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.app_settings_alt),
            title: Text('App Version'),
            subtitle: Text('1.0.0'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text('Privacy Policy'),
            subtitle: Text('Read our privacy policy'),
          ),
          ListTile(
            leading: Icon(Icons.description),
            title: Text('Terms of Service'),
            subtitle: Text('Read our terms of service'),
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('Support'),
            subtitle: Text('Get help and support'),
          ),
        ],
      ),
    );
  }
}



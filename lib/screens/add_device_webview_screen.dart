import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_config.dart';

class AddDeviceWebViewScreen extends StatefulWidget {
  final String uid;
  final int? startTimeMs;
  const AddDeviceWebViewScreen(
      {super.key, required this.uid, this.startTimeMs});

  @override
  State<AddDeviceWebViewScreen> createState() => _AddDeviceWebViewScreenState();
}

class _AddDeviceWebViewScreenState extends State<AddDeviceWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
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
    // Inject JavaScript to pre-fill User ID field
    // Escape the user ID to prevent JavaScript injection issues
    final escapedUid = widget.uid.replaceAll("'", "\\'").replaceAll('"', '\\"').replaceAll('\n', '\\n').replaceAll('\r', '\\r');
    
    final script = '''
      (function() {
        const userId = '$escapedUid';
        console.log('Injecting User ID:', userId);
        
        // Try multiple selectors to find User ID input field
        const selectors = [
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
        
        let found = false;
        selectors.forEach(selector => {
          const inputs = document.querySelectorAll(selector);
          inputs.forEach(input => {
            if (!found && (input.value === '' || 
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
              found = true;
            }
          });
        });
        
        if (!found) {
          console.log('No suitable User ID field found');
        }
      })();
    ''';
    
    _controller.runJavaScript(script);
  }

  void _proceedToWait() {
    Navigator.pushNamed(
      context,
      '/add-device/wait',
      arguments: {
        'uid': widget.uid,
        if (widget.startTimeMs != null) 'startTimeMs': widget.startTimeMs,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configure Device')),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: WebViewWidget(controller: _controller)),
          Padding(
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
                        'Enter your home Wi‑Fi name and password in the portal served by the device.\n'
                        'When you\'re done, tap Continue. The device will restart and join your Wi‑Fi.',
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _proceedToWait,
                      child: const Text('Continue'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final url = Uri.parse(AppConfig.devicePortalUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
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
          ),
        ],
      ),
    );
  }
}

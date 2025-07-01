import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AutomationRulesScreen extends StatefulWidget {
  final String userId;
  final String deviceId;
  const AutomationRulesScreen({super.key, required this.userId, required this.deviceId});

  @override
  State<AutomationRulesScreen> createState() => _AutomationRulesScreenState();
}

class _AutomationRulesScreenState extends State<AutomationRulesScreen> {
  String _conditionType = 'temp';
  String _operator = '>';
  String _action = 'motor = true';
  double _threshold = 35;
  bool _isSaving = false;

  Future<void> _saveRule() async {
    setState(() => _isSaving = true);
    final rule = {
      'condition': '$_conditionType $_operator $_threshold',
      'action': _action,
    };
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('devices')
        .doc(widget.deviceId)
        .set({'rules': rule}, SetOptions(merge: true));
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rule saved!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Automation Rule Editor')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Condition:', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                DropdownButton<String>(
                  value: _conditionType,
                  items: const [
                    DropdownMenuItem(value: 'temp', child: Text('Temperature')),
                    DropdownMenuItem(value: 'humidity', child: Text('Humidity')),
                  ],
                  onChanged: (v) => setState(() => _conditionType = v!),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _operator,
                  items: const [
                    DropdownMenuItem(value: '>', child: Text('>')),
                    DropdownMenuItem(value: '<', child: Text('<')),
                    DropdownMenuItem(value: '>=', child: Text('≥')),
                    DropdownMenuItem(value: '<=', child: Text('≤')),
                    DropdownMenuItem(value: '==', child: Text('=')),
                  ],
                  onChanged: (v) => setState(() => _operator = v!),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Value'),
                    onChanged: (v) => setState(() => _threshold = double.tryParse(v) ?? 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Action:', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _action,
              items: const [
                DropdownMenuItem(value: 'motor = true', child: Text('Turn Motor ON')),
                DropdownMenuItem(value: 'motor = false', child: Text('Turn Motor OFF')),
              ],
              onChanged: (v) => setState(() => _action = v!),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveRule,
                child: _isSaving ? const CircularProgressIndicator() : const Text('Save Rule'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
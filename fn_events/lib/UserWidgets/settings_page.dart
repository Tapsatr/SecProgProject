import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/constants.dart' as constants;
import '../secure_storage.dart';
import '../AuthWidgets/mfa_enroll_page.dart'; // Ensure you import the MFAEnrollPage

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isMfaEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    String? token = await getSecureStorageAuthToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error: Token not found')),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${constants.accountBaseUrl}/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          final data = jsonDecode(response.body);
          _isMfaEnabled = data['isMfaEnabled'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load settings: $e')),
      );
    }
  }

  Future<void> _toggleMfa(bool enable) async {
    if (!enable && _isMfaEnabled) {
      // Confirm deactivation
      final confirmDeactivate = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Disable MFA'),
          content: Text('Are you sure you want to disable MFA?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Disable'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );

      if (confirmDeactivate) {
        // Deactivate MFA
        await deactivateMfa();
      }
    } else if (enable && !_isMfaEnabled) {
      // Navigate to MFA setup page
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MFAEnrollPage()),
      );

      if (result == true) {
        // MFA was successfully enabled, refresh settings
        _loadSettings();
      }
    }
  }

  Future<void> deactivateMfa() async {
    String? token = await getSecureStorageAuthToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error: Token not found')),
      );
      return;
    }

    final uri = Uri.parse('${constants.accountBaseUrl}/settings/mfa');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'enable': false}),
    );

    if (response.statusCode == 200) {
      setState(() => _isMfaEnabled = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to disable MFA: ${response.statusCode}')),
      );
    }
  }

  Future<String?> getSecureStorageAuthToken() async {
    SecureStorage secureStorage = SecureStorage();
    return await secureStorage.getSecret('auth_token');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Enable MFA'),
            value: _isMfaEnabled,
            onChanged: _toggleMfa,
          ),
        ],
      ),
    );
  }
}

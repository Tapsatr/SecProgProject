import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../constants/constants.dart' as constants;
import 'package:http/http.dart' as http;

import '../home_page.dart';
import '../secure_storage.dart';

class MfaVerificationPage extends StatefulWidget {
  final String email;
  const MfaVerificationPage({Key? key, required this.email}) : super(key: key);

  @override
  _MfaVerificationPageState createState() => _MfaVerificationPageState();
}

class _MfaVerificationPageState extends State<MfaVerificationPage> {
  final TextEditingController _mfaController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _verifyMfa() async {
    setState(() {
      _isSubmitting = true;
    });
    var isSuccess = await verifyMfaToken(widget.email, _mfaController.text);

    setState(() {
      _isSubmitting = false;
    });

    if (isSuccess) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Login Successful')),
      );
    } else {
      // Something went wrong
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid MFA token')),
      );
    }
  }

  Future<bool> verifyMfaToken(String email, String mfaCode) async {
    final url = Uri.parse('${constants.accountBaseUrl}/verify-mfa');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'token': mfaCode,
      }),
    );

    if (response.statusCode == 200) {
      // Here you could store the JWT token if your API returns one after MFA verification
      final token = jsonDecode(response.body)['token'];
      await SecureStorage().storeSecret('auth_token', token);
      return true;
    } else {
      // Log error or handle it appropriately
      print('Failed to verify MFA token: ${response.body}');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verify MFA')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _mfaController,
              decoration: InputDecoration(labelText: 'MFA Code'),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _verifyMfa,
              child: _isSubmitting ? CircularProgressIndicator() : Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}

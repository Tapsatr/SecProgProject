import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fn_events/secure_storage.dart';
import 'package:http/http.dart' as http;
import '../constants/constants.dart' as constants;

class MFAEnrollPage extends StatefulWidget {
  const MFAEnrollPage({super.key});

  @override
  State<MFAEnrollPage> createState() => _MFAEnrollPageState();
}

class _MFAEnrollPageState extends State<MFAEnrollPage> {
  late Future<Map<String, dynamic>> _enrollFuture;

  @override
  void initState() {
    super.initState();
    _enrollFuture = fetchMfaDetails();
  }

  Future<Map<String, dynamic>> fetchMfaDetails() async {
    SecureStorage secureStorage = SecureStorage();
    String? token = await secureStorage.getSecret('auth_token');

    if (token == null) {
      throw Exception('Authentication error: Token not found');
    }

    final url = Uri.parse('${constants.accountBaseUrl}/enroll-mfa');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load MFA details: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup MFA'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _enrollFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final data = snapshot.data!;
          final qrCodeBase64 = data['qrCodeBase64'] as String?;
          final secret = data['secret'] as String?;

          if (qrCodeBase64 == null || secret == null) {
            return const Center(child: Text("Invalid data received from server"));
          }

          // Decode the Base64 image string for displaying
          Uint8List bytes = base64Decode(qrCodeBase64);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              const Text(
                'Open your authentication app and add this app via QR code or by pasting the code below.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Image.memory(bytes, width: 150, height: 150),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      secret,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: secret));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to your clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Enter the code shown in your authentication app.'),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(hintText: '000000'),
                style: const TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                onChanged: (value) async {
                  if (value.length == 6) {
                    try {
                      SecureStorage secureStorage = SecureStorage();
                      var email = await secureStorage.getSecret('user_email');
                      final response = await http.post(
                        Uri.parse('${constants.accountBaseUrl}/verify-mfa'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({'email': email, 'token': value}), // Adjust the payload as needed
                      );

                      if (response.statusCode == 200) {
                        Navigator.of(context).pop(true); // Return to settings page and indicate success
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Invalid MFA token')),
                        );
                      }
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('An unexpected error occurred')),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

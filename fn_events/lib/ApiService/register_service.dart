import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/constants.dart' as constants;

class RegisterService {
  final String _baseUrl = constants.accountBaseUrl;

  Future<RegistrationResult> registerUser(
      String email,
      String password,
      String confirmPassword,
      String firstName,
      String lastName,
      String phoneNumber) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
      }),
    );

    String errorMessage = '';
    Map<String, dynamic>? errorDetails;
    if (response.statusCode != 200) {
       errorMessage =
          'An error occurred during registration. Status code: ${response.statusCode}';
      try {
        final result = jsonDecode(response.body);
        errorMessage = result['title'] ?? errorMessage;
        if (result.containsKey('errors')) {
          errorDetails = Map<String, dynamic>.from(result['errors']);
        } else if (result['title'] == null && !result.containsKey('errors') && result[''] != null) {
          // Only first general error
          errorMessage = result[''][0];
        }
      } catch (e) {
        if (kDebugMode) {
          print('Exception during registration: $e');
        }
        errorMessage = 'An unexpected error occurred. Please try again later.';
      }
       return RegistrationResult(
           isSuccess: false,
           errorMessage: errorMessage,
           errorDetails: errorDetails);
    }
    return RegistrationResult(

        isSuccess: true,
        errorMessage: errorMessage,
        errorDetails: errorDetails);
  }
  
}

class RegistrationResult {
  final bool isSuccess;
  final String errorMessage;
  final Map<String, dynamic>? errorDetails;

  RegistrationResult({required this.isSuccess, this.errorMessage = '', this.errorDetails});
}

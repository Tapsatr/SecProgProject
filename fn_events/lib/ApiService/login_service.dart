import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/constants.dart' as constants;

class LoginResult {
  final bool isSuccess;
  final String? token;
  final String? errorMessage;
  final bool requiresMfa;

  LoginResult({required this.isSuccess, this.token, this.errorMessage, this.requiresMfa = false});
}

class LoginService {
  Future<LoginResult> loginUser(String email, String password) async {
    final url = Uri.parse('${constants.accountBaseUrl}/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Email': email, 'Password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Check if MFA is required
      if (data['requiresMfa'] != null && data['requiresMfa'] == true) {
        return LoginResult(isSuccess: true, requiresMfa: true);
      }
      return LoginResult(isSuccess: true, token: data['token']);
    } else if (response.statusCode == 401) {
      return LoginResult(isSuccess: false, errorMessage: 'Invalid email or password.');
    } else {
      return LoginResult(isSuccess: false, errorMessage: 'An unexpected error occurred.');
    }
  }
}

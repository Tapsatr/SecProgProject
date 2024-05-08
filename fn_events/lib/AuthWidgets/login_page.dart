import 'package:flutter/material.dart';
import '../secure_storage.dart';
import 'mfa_verify_page.dart';
import 'registration_page.dart';
import '../home_page.dart';
import '../ApiService/login_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Map<String, String> _fieldErrors = {};
  bool _isSubmitting = false;

  void _setFieldError(String field, String message) {
    setState(() {
      _fieldErrors[field] = message;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      LoginService loginService = LoginService();
      LoginResult result = await loginService.loginUser(
        _emailController.text,
        _passwordController.text,
      );

      setState(() {
        _isSubmitting = false;
      });
      final String email = _emailController.text;

      if (result.requiresMfa) {
        // Navigate to MFA verification page or show a dialog for MFA code entry
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => MfaVerificationPage(email: _emailController.text)),
        );
      }
      else if (result.isSuccess) {
        // store the token using SecureStorage
        SecureStorage secureStorage = SecureStorage();
        await secureStorage.storeSecret('auth_token', result.token!);
        await secureStorage.storeSecret('user_email', _emailController.text);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Login Successful')),
        );
      } else {
        // Error?
        final errorMessage = result.errorMessage ?? 'An unknown error occurred.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email', errorText: _fieldErrors['Email']),
                validator: (value) => value!.isEmpty ? 'Email cannot be empty' : null,
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password', errorText: _fieldErrors['Password']),
                validator: (value) => value!.isEmpty ? 'Password cannot be empty' : null,
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _loginUser,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const RegistrationPage()),
                  );
                },
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

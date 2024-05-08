import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fn_events/ApiService/register_service.dart';
import '../home_page.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  Map<String, String> _fieldErrors = {};

  /// Set error for specific field
  void _setFieldError(String field, String message) {
    setState(() {
      _fieldErrors[field] = message;
    });
  }

  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      RegisterService registerService = RegisterService();
      final RegistrationResult result = await registerService.registerUser(
        _emailController.text,
        _passwordController.text,
        _confirmPasswordController.text,
        _firstNameController.text,
        _lastNameController.text,
        _phoneNumberController.text,
      );

      setState(() {
        _isSubmitting = false;
      });

      if (result.isSuccess) {
        // Navigate to the home page on success
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Registration Successful')),
        );
      } else {
        setState(() {
          _isSubmitting = false;
          if (result.errorDetails != null) {
            result.errorDetails!.forEach((key, value) {
              // TODO Maybe take more errors?
              _fieldErrors[key] = value[0];
            });
            // Trigger revalidation
            _formKey.currentState!.validate();
          }
        });

        // Show a generic error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: <Widget>[
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email', errorText: _fieldErrors['Email'],),
              validator: (value) =>
                  value!.isEmpty ? 'Email cannot be empty' : null,
              keyboardType: TextInputType.emailAddress,
            ),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password', errorText: _fieldErrors['Password']),
              validator: (value) =>
                  value!.isEmpty ? 'Password cannot be empty' : null,
              obscureText: true,
            ),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(labelText: 'Confirm Password', errorText: _fieldErrors['ConfirmPassword']),
              validator: (value) =>
              value!.isEmpty ? 'Password cannot be empty' : null,
              obscureText: true,
            ),
            TextFormField(
              controller: _firstNameController,
              decoration: InputDecoration(labelText: 'First Name', errorText: _fieldErrors['FirstName']),
              validator: (value) =>
                  value!.isEmpty ? 'First name cannot be empty' : null,
            ),
            TextFormField(
              controller: _lastNameController,
              decoration: InputDecoration(labelText: 'Last Name', errorText: _fieldErrors['LastName']),
              validator: (value) =>
                  value!.isEmpty ? 'Last name cannot be empty' : null,
            ),
            TextFormField(
              controller: _phoneNumberController,
              decoration: InputDecoration(labelText: 'Phone Number', errorText: _fieldErrors['PhoneNumber']),
              validator: (value) =>
                  value!.isEmpty ? 'Phone number cannot be empty' : null,
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _registerUser,
              child: _isSubmitting
                  ? CircularProgressIndicator()
                  : Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}

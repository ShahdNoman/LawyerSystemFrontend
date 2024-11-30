import 'package:flutter/material.dart';
import 'dart:convert'; 
import 'package:http/http.dart' as http; 

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  String _email = '';
  bool _isSignUp = true; 

Future<void> _signup(String username, String password, String email) async {
  try {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/insert_record/insert_record'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'email': email,
      }),
    );

    print('Response Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    // Check if the response status is 201 (Created)
    if (response.statusCode == 201) {
      final result = jsonDecode(response.body); // Define result here
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-Up Successful!')),
        );
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        // Show the error message returned by backend
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-Up Failed: ${result['message']}')),
        );
      }
    }else if (response.statusCode == 400) {
      final result = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result['message']}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server error, please try again later.')),
      );
    }
  } catch (e) {
    print('Error during request: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error: Could not connect to server.')),
    );
  }
}


  Future<void> _login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/login/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login Successful!')),
          );
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid Username or Password')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Server error, please try again later.')),
        );
      }
    } catch (e) {
      print('Error during request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Could not connect to server.')),
      );
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_isSignUp) {
        _signup(_username, _password, _email);
      } else {
        _login(_username, _password);
      }
    }
  }

  void _toggleForm() {
    setState(() {
      _isSignUp = !_isSignUp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Hero(
                  tag: 'logo',
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.indigoAccent,
                    child: Icon(Icons.gavel, size: 60, color: Colors.white),
                  ),
                ),
                SizedBox(height: 40), // Removed `const` here
                TextFormField(
                  decoration: InputDecoration(
                    // Removed `const` here
                    labelText: 'Username',
                    filled: true,
                    fillColor: Colors.indigo[50],
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _username = value!;
                  },
                ),
                SizedBox(height: 20), // Removed `const` here
                TextFormField(
                  decoration: InputDecoration(
                    // Removed `const` here
                    labelText: 'Password',
                    filled: true,
                    fillColor: Colors.indigo[50],
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _password = value!;
                  },
                ),
                if (_isSignUp)
                  Column(
                    children: [
                      SizedBox(height: 20), // Removed `const` here
                      TextFormField(
                        decoration: InputDecoration(
                          // Removed `const` here
                          labelText: 'Email',
                          filled: true,
                          fillColor: Colors.indigo[50],
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value!.isEmpty || !value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _email = value!;
                        },
                      ),
                    ],
                  ),
                SizedBox(height: 30), // Removed `const` here
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        vertical: 16), // Removed `const` here
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    backgroundColor: Colors.indigo,
                  ),
                  onPressed: _submit,
                  child: Text(_isSignUp ? 'Sign Up' : 'Login'),
                ),
                SizedBox(height: 20), // Removed `const` here
                GestureDetector(
                  onTap: _toggleForm,
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Login'
                        : 'Don\'t have an account? Sign Up',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: Colors.indigo), // Removed `const` here
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
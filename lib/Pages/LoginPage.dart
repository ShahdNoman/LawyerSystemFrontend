import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http; 

void main() {
  runApp(LawApp());
}

class LawApp extends StatelessWidget {
  const LawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lawyer App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AnimatedLoginPage(),
        '/dashboard': (context) => const DashboardPage(),
      },
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Center(
        child: const Text(
          'Welcome to the Dashboard!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

class AnimatedLoginPage extends StatefulWidget {
  const AnimatedLoginPage({super.key});

  @override
  _AnimatedLoginPageState createState() => _AnimatedLoginPageState();
}

class _AnimatedLoginPageState extends State<AnimatedLoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  String _email = ''; // Email for sign-up
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isSignUp = false; // Track if user is signing up

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleForm() {
    setState(() {
      _isSignUp = !_isSignUp;
    });
  }

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
        SnackBar(content: Text('Error: ${result['message']}')), // Show the backend message
      );
    } else {
      // If status code is not 201, show a general error message
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
      print('Starting login request...'); // Debugging log

      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/login/login'),
        headers: {
          'Content-Type': 'application/json'
        }, // Changed to application/json
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      print('Response received: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
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
        } catch (e) {
          print('Error decoding JSON: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Invalid response format')),
          );
        }
      } else {
        print('Failed to login. Status Code: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Server error, please try again later.')),
        );
      }
    } catch (e) {
      print('Error during request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occurred. Please try again later.')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Hero(
                    tag: 'logo',
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.indigoAccent,
                      child: Icon(Icons.gavel, size: 60, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    key: const ValueKey('username'),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      filled: true,
                      fillColor: Colors.indigo[50],
                      prefixIcon: const Icon(Icons.person),
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
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const ValueKey('password'),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      filled: true,
                      fillColor: Colors.indigo[50],
                      prefixIcon: const Icon(Icons.lock),
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
                        const SizedBox(height: 20),
                        TextFormField(
                          key: const ValueKey('email'),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            filled: true,
                            fillColor: Colors.indigo[50],
                            prefixIcon: const Icon(Icons.email),
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
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      backgroundColor: Colors.indigo,
                    ),
                    onPressed: _submit,
                    child: Text(_isSignUp ? 'Sign Up' : 'Login'),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _toggleForm,
                    child: Text(
                      _isSignUp
                          ? 'Already have an account? Login'
                          : 'Don\'t have an account? Sign Up',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.indigo),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

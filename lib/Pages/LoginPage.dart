import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firstproj/Pages/DashboardPage.dart' as dashboardPage;
import 'package:firstproj/Pages/TokenUtils.dart';
import 'package:firstproj/main.dart';
import 'package:firstproj/Pages/AdminDashboardPage.dart' as adminDashboardPage;

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
        '/AdminDashboardPage': (context) =>
            const adminDashboardPage.AdminDashboardPage(),
      },
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // key: scaffoldMessengerKey, // Connect Scaffold to the scaffoldMessengerKey
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
  final String _role = ''; // New field
  String _fullName = ''; // New field
  String _phoneNumber = ''; // New field
  String _membershipNumber = ''; // New field
  String _judgeNumber = ''; // New field (appears only for Judge role)
  String _idNumber = ''; // New field
  String _bio = ''; // New field
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isSignUp = false; // Track if user is signing up

  @override
  void initState() {
    super.initState();
    TokenUtils.checkTokenExpiration(context);
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

  Future<void> _signup() async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:4000/insert_record/insert_record'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _username,
          'password': _password,
          'email': _email,
          'role': _role,
          'fullName': _fullName,
          'phoneNumber': _phoneNumber,
          'membershipNumber': _membershipNumber,
          'judgeNumber': _judgeNumber,
          'idNumber': _idNumber,
          'bio': _bio,
        }),
      );

      if (response.statusCode == 201) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          var box = await Hive.openBox('userBox');
          await box.put('token', result['token']);
          final expirationTime = DateTime.now().add(Duration(hours: 1));
          await box.put('token_expiration', expirationTime.toIso8601String());

          if (ScaffoldMessenger.of(context).mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ScaffoldMessenger.maybeOf(context) != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sign-Up Successful!')),
                );
              }
            });
          }
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const dashboardPage.DashboardPage()),
            );
          });
        } else {
          if (ScaffoldMessenger.of(context).mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ScaffoldMessenger.maybeOf(context) != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Sign-Up Failed: ${result['message']}')),
                );
              }
            });
          }
        }
      } else {
        if (ScaffoldMessenger.of(context).mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ScaffoldMessenger.maybeOf(context) != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Server error, please try again later.')),
              );
            }
          });
        }
      }
    } catch (e) {
      if (ScaffoldMessenger.of(context).mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (ScaffoldMessenger.maybeOf(context) != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Error: Could not connect to server.')),
            );
          }
        });
      }
    }
  }

  Future<void> _login() async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:4000/login/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _username,
          'password': _password,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success'] == true) {
          var box = await Hive.openBox('userBox');
          await box.put('token', result['token']);
          final expirationTime = DateTime.now().add(Duration(hours: 1));
          await box.put('token_expiration', expirationTime.toIso8601String());

          // Extract role from the result
          final role = result['role'];

          if (ScaffoldMessenger.of(context).mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ScaffoldMessenger.maybeOf(context) != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Login Successful!')),
                );
              }
            });
          }

          // Navigate based on the role
          Future.delayed(const Duration(seconds: 2), () {
            if (role == 'Admin') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const adminDashboardPage
                        .AdminDashboardPage()), // Replace with your Admin Dashboard page
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const DashboardPage()), // Replace with your User Dashboard page
              );
            }
          });
        } else {
          if (ScaffoldMessenger.of(context).mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ScaffoldMessenger.maybeOf(context) != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid Username or Password')),
                );
              }
            });
          }
        }
      } else {
        if (ScaffoldMessenger.of(context).mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ScaffoldMessenger.maybeOf(context) != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Server error, please try again later.')),
              );
            }
          });
        }
      }
    } catch (e) {
      if (ScaffoldMessenger.of(context).mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (ScaffoldMessenger.maybeOf(context) != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error during login.')),
            );
          }
        });
      }
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_isSignUp) {
        _signup();
      } else {
        _login();
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
              child: SingleChildScrollView(
                // Ensure the form scrolls on smaller screens
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
                    const SizedBox(height: 20), // Reduced gap
                    TextFormField(
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
                    const SizedBox(height: 10), // Reduced gap
                    TextFormField(
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
                          const SizedBox(height: 10), // Reduced gap
                          TextFormField(
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
                          const SizedBox(height: 10), // Reduced gap
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              filled: true,
                              fillColor: Colors.indigo[50],
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSaved: (value) {
                              _fullName = value!;
                            },
                          ),
                          const SizedBox(height: 10), // Reduced gap
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              filled: true,
                              fillColor: Colors.indigo[50],
                              prefixIcon: const Icon(Icons.phone),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSaved: (value) {
                              _phoneNumber = value!;
                            },
                          ),
                          const SizedBox(height: 10), // Reduced gap
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Membership Number',
                              filled: true,
                              fillColor: Colors.indigo[50],
                              prefixIcon: const Icon(Icons.numbers),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSaved: (value) {
                              _membershipNumber = value!;
                            },
                          ),
                          const SizedBox(height: 10), // Reduced gap
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Judge Number (Optional)',
                              filled: true,
                              fillColor: Colors.indigo[50],
                              prefixIcon: const Icon(Icons.gavel),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSaved: (value) {
                              _judgeNumber = value!;
                            },
                          ),
                          const SizedBox(height: 10), // Reduced gap
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'ID Number',
                              filled: true,
                              fillColor: Colors.indigo[50],
                              prefixIcon: const Icon(Icons.credit_card),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSaved: (value) {
                              _idNumber = value!;
                            },
                          ),
                          const SizedBox(height: 10), // Reduced gap
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Bio (Optional)',
                              filled: true,
                              fillColor: Colors.indigo[50],
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSaved: (value) {
                              _bio = value!;
                            },
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        backgroundColor: Colors.indigo,
                      ),
                      child: Text(_isSignUp ? 'Sign Up' : 'Login'),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: _toggleForm,
                      child: Text(
                        _isSignUp
                            ? 'Already have an account? Login'
                            : 'Don\'t have an account? Sign Up',
                        style: TextStyle(color: Colors.indigo),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

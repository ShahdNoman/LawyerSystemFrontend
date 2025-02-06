
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'AboutPage.dart';
import 'DashboardPage.dart' as dashboardPage;
import 'TokenUtils.dart';
import 'AdminDashboardPage.dart' as adminDashboardPage;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'DashboardPage.dart';
import 'LoginPage.dart';
const Color textPrimaryColor = Color.fromARGB(255, 1, 25, 65);
const Color primaryColor = Color(0xFF003366);

class ForgotPasswordScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot Password', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor, // Use your primary color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter your email to reset your password',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email, color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryColor),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                labelStyle: TextStyle(color: primaryColor),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Validate email input
                if (_emailController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter your email')),
                  );
                  return;
                }

                try {
                  final forgetpass = kIsWeb
                      ? 'http://192.168.0.186:4000/login/forgot-password' // For Web (Chrome)
                      : 'http://10.0.2.2:4000/login/forgot-password'; // For Android Emulator

                  print("forgetpass is $forgetpass");

                  final response = await http.post(
                    Uri.parse(forgetpass), // Replace with your API endpoint
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({'email': _emailController.text}),
                  );

                  if (response.statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Password reset email sent')),
                    );
                  } else {
                    final error = json.decode(response.body)['message'];
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $error')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to send reset email')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white),
              child: Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }
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
  String _role = 'Citizen'; // New field
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
    String determinedRole = 'Citizen';
      if (_membershipNumber.isNotEmpty) {
        determinedRole = 'Lawyer';
      } else if (_judgeNumber.isNotEmpty) {
        determinedRole = 'Judge';
      }
    try {
      final signupUrl = kIsWeb
          ? 'http://192.168.0.186:4000/insert_record/insert_record' // For Web (Chrome)
          : 'http://10.0.2.2:4000/insert_record/insert_record'; // For Android Emulator

      print("signupUrl is $signupUrl");

      final response = await http.post(
        Uri.parse(signupUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _username,
          'password': _password,
          'email': _email,
          'role': determinedRole,
          'phone_number': _phoneNumber,
          'full_name': _fullName,
          'membership_number': _membershipNumber,
          'judge_number': _judgeNumber,
          'id_number': _idNumber,
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
                  builder: (context) => const AnimatedLoginPage()),
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
      final loginUrl = kIsWeb
          ? 'http://192.168.0.186:4000/login/login' // For Web (Chrome)
          : 'http://10.0.2.2:4000/login/login'; // For Android Emulator

      print("loginUrl is $loginUrl");

      final response = await http.post(
        Uri.parse(loginUrl),
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
      body: Stack(
        children: [
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isMobile = constraints.maxWidth < 600;
                return FadeTransition(
                  opacity: _animation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16.0 : 32.0,
                    ),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildLogo(isMobile),
                            const SizedBox(height: 20),
                            _buildUsernameTextField(),
                            const SizedBox(height: 10),
                            _buildPasswordTextField(),
                            const SizedBox(height: 10),
                            if (!_isSignUp) _buildForgotPasswordLink(isMobile),
                            if (_isSignUp) _buildSignUpFields(isMobile),
                            const SizedBox(height: 20),
                            _buildSubmitButton(isMobile),
                            const SizedBox(height: 20),
                            _buildToggleFormButton(isMobile),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (!_isSignUp)
            Positioned(
              bottom: 20, // position at the bottom of the stack
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                   Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AboutPage()),
              );

                },
                child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_upward_rounded,
                          color: primaryColor),
                      SizedBox(width: 10),
                      Text(
                        "About This App",
                        style: TextStyle(
                            color: primaryColor,
                            decoration: TextDecoration.underline),
                      ),
                    ]),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildLogo(bool isMobile) {
    return Hero(
      tag: 'logo',
      child: CircleAvatar(
        radius: isMobile ? 50 : 60,
        backgroundColor: primaryColor,
        child: Icon(Icons.gavel, size: isMobile ? 50 : 60, color: Colors.white),
      ),
    );
  }

  Widget _buildUsernameTextField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Username',
        filled: true,
        fillColor: Colors.indigo[50],
        prefixIcon: const Icon(Icons.person, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
          borderRadius: BorderRadius.circular(10.0),
        ),
        labelStyle: TextStyle(color: primaryColor),
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
    );
  }

  Widget _buildPasswordTextField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Password',
        filled: true,
        fillColor: Colors.indigo[50],
        prefixIcon: const Icon(Icons.lock, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
           focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
          borderRadius: BorderRadius.circular(10.0),
        ),
           labelStyle: TextStyle(color: primaryColor),
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
    );
  }

  Widget _buildForgotPasswordLink(bool isMobile) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
          );
        },
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            color: primaryColor,
            decoration: TextDecoration.underline,
            fontSize: isMobile ? 12 : 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpFields(bool isMobile) {
    return Column(
      children: [
        const SizedBox(height: 10),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Email',
            filled: true,
            fillColor: Colors.indigo[50],
            prefixIcon: const Icon(Icons.email, color: primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
             focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
          borderRadius: BorderRadius.circular(10.0),
        ),
        labelStyle: TextStyle(color: primaryColor),
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
        const SizedBox(height: 10),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Full Name',
            filled: true,
            fillColor: Colors.indigo[50],
            prefixIcon: const Icon(Icons.person, color: primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
             focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
          borderRadius: BorderRadius.circular(10.0),
        ),
        labelStyle: TextStyle(color: primaryColor),
          ),
          onSaved: (value) {
            _fullName = value!;
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Phone Number',
            filled: true,
            fillColor: Colors.indigo[50],
            prefixIcon: const Icon(Icons.phone, color: primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
             focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
          borderRadius: BorderRadius.circular(10.0),
        ),
        labelStyle: TextStyle(color: primaryColor),
          ),
          onSaved: (value) {
            _phoneNumber = value!;
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Membership Number',
            filled: true,
            fillColor: Colors.indigo[50],
            prefixIcon: const Icon(Icons.numbers, color: primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
             focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
          borderRadius: BorderRadius.circular(10.0),
        ),
        labelStyle: TextStyle(color: primaryColor),
          ),
          onSaved: (value) {
            _membershipNumber = value!;
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Judge Number (Optional)',
            filled: true,
            fillColor: Colors.indigo[50],
            prefixIcon: const Icon(Icons.gavel, color: primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
               focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
          borderRadius: BorderRadius.circular(10.0),
        ),
        labelStyle: TextStyle(color: primaryColor),
          ),
          onSaved: (value) {
            _judgeNumber = value!;
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'ID Number',
            filled: true,
            fillColor: Colors.indigo[50],
            prefixIcon: const Icon(Icons.credit_card, color: primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
               focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
          borderRadius: BorderRadius.circular(10.0),
        ),
        labelStyle: TextStyle(color: primaryColor),
          ),
          onSaved: (value) {
            _idNumber = value!;
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Bio (Optional)',
            filled: true,
            fillColor: Colors.indigo[50],
            prefixIcon: const Icon(Icons.person, color: primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
               focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
          borderRadius: BorderRadius.circular(10.0),
        ),
        labelStyle: TextStyle(color: primaryColor),
          ),
          onSaved: (value) {
            _bio = value!;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isMobile) {
    return ElevatedButton(
      onPressed: _submit,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16.0),
        backgroundColor: primaryColor, // Use your primary color
        foregroundColor: Colors.white,
      ),
      child: Text(
        _isSignUp ? 'Sign Up' : 'Login',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildToggleFormButton(bool isMobile) {
    return TextButton(
      onPressed: _toggleForm,
      child: Text(
        _isSignUp
            ? 'Already have an account? Login'
            : 'Don\'t have an account? Sign Up',
        style: TextStyle(color: primaryColor, fontSize: isMobile ? 12 : 14),
      ),
    );
  }
}
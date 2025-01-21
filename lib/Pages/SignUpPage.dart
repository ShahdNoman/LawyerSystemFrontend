import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firstproj/Pages/DashboardPage.dart' as dashboardPage;
import 'package:firstproj/Pages/TokenUtils.dart';
import 'package:firstproj/main.dart'; // Import the main.dart file
import 'package:flutter/foundation.dart'; // Import to check if running on web
import 'package:flutter/foundation.dart'; // Import to check if running on web

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
  String _role = 'Admin'; // Default role
  String _phoneNumber = '';
  String _fullName = '';
  String _membershipNumber = '';
  String _judgeNumber = '';
  String _idNumber = '';
  String _bio = '';
  bool _isSignUp = true;

  // Add a variable to store the profile picture
  String? _profilePicture;

  Future<void> _signup(
      String username,
      String password,
      String email,
      String role,
      String phoneNumber,
      String fullName,
      String membershipNumber,
      String judgeNumber,
      String idNumber,
      String bio) async {
    try {
      final signupUrl = kIsWeb
          ? 'http://192.168.88.11:4000/insert_record/insert_record' // For Web (Chrome)
          : 'http://10.0.2.2:4000/insert_record/insert_record'; // For Android Emulator

      print("signupUrl is $signupUrl");

      final response = await http.post(
        Uri.parse(signupUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'email': email,
          'role': role,
          'phoneNumber': phoneNumber,
          'fullName': fullName,
          'membershipNumber': membershipNumber,
          'judgeNumber': judgeNumber,
          'idNumber': idNumber,
          'bio': bio,
          'profilePicture': _profilePicture, // Profile Picture URL or file data
        }),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          var box = await Hive.openBox('userBox');
          await box.put('token', result['token']);
          print('Token saved: ${result['token']}');
          final expirationTime = DateTime.now().add(Duration(hours: 1));
          await box.put('token_expiration', expirationTime.toIso8601String());
          print('Token expiration time: $expirationTime');
          if (ScaffoldMessenger.of(context).mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sign-Up Successful!')),
            );
          }
          print('Navigating to dashboard...');
          TokenUtils.checkTokenExpiration(context);
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
      } else if (response.statusCode == 400) {
        final result = jsonDecode(response.body);
        if (ScaffoldMessenger.of(context).mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ScaffoldMessenger.maybeOf(context) != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${result['message']}')),
              );
            }
          });
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
      print('Error during request: $e');
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_isSignUp) {
        _signup(
          _username,
          _password,
          _email,
          _role,
          _phoneNumber,
          _fullName,
          _membershipNumber,
          _judgeNumber,
          _idNumber,
          _bio,
        );
      } else {
        // Add login functionality if needed
      }
    }
  }

  void _toggleForm() {
    setState(() {
      _isSignUp = !_isSignUp;
    });
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     // key: scaffoldMessengerKey, // Connect Scaffold to the scaffoldMessengerKey
  //     backgroundColor: Colors.white,
  //     body: Center(
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 32.0),
  //         child: Form(
  //           key: _formKey,
  //           child: Column(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             crossAxisAlignment: CrossAxisAlignment.stretch,
  //             children: [
  //               Hero(
  //                 tag: 'logo',
  //                 child: CircleAvatar(
  //                   radius: 60,
  //                   backgroundColor: Colors.indigoAccent,
  //                   child: Icon(Icons.gavel, size: 60, color: Colors.white),
  //                 ),
  //               ),
  //               SizedBox(height: 40),
  //               TextFormField(
  //                 decoration: InputDecoration(
  //                   labelText: 'Username',
  //                   filled: true,
  //                   fillColor: Colors.indigo[50],
  //                   prefixIcon: Icon(Icons.person),
  //                   border: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(10.0),
  //                     borderSide: BorderSide.none,
  //                   ),
  //                 ),
  //                 validator: (value) {
  //                   if (value!.isEmpty) {
  //                     return 'Please enter your username';
  //                   }
  //                   return null;
  //                 },
  //                 onSaved: (value) {
  //                   _username = value!;
  //                 },
  //               ),
  //               SizedBox(height: 20),
  //               TextFormField(
  //                 decoration: InputDecoration(
  //                   labelText: 'Password',
  //                   filled: true,
  //                   fillColor: Colors.indigo[50],
  //                   prefixIcon: Icon(Icons.lock),
  //                   border: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(10.0),
  //                     borderSide: BorderSide.none,
  //                   ),
  //                 ),
  //                 obscureText: true,
  //                 validator: (value) {
  //                   if (value!.isEmpty) {
  //                     return 'Please enter your password';
  //                   }
  //                   return null;
  //                 },
  //                 onSaved: (value) {
  //                   _password = value!;
  //                 },
  //               ),
  //               if (_isSignUp) ...[
  //                 SizedBox(height: 20),
  //                 TextFormField(
  //                   decoration: InputDecoration(
  //                     labelText: 'Email',
  //                     filled: true,
  //                     fillColor: Colors.indigo[50],
  //                     prefixIcon: Icon(Icons.email),
  //                     border: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(10.0),
  //                       borderSide: BorderSide.none,
  //                     ),
  //                   ),
  //                   validator: (value) {
  //                     if (value!.isEmpty || !value.contains('@')) {
  //                       return 'Please enter a valid email';
  //                     }
  //                     return null;
  //                   },
  //                   onSaved: (value) {
  //                     _email = value!;
  //                   },
  //                 ),
  //                 SizedBox(height: 20),
  //                 DropdownButtonFormField<String>(
  //                   value: _role,
  //                   onChanged: (newValue) {
  //                     setState(() {
  //                       _role = newValue!;
  //                     });
  //                   },
  //                   items: ['Admin', 'Lawyer', 'Citizen', 'Judge']
  //                       .map((role) => DropdownMenuItem<String>(
  //                             value: role,
  //                             child: Text(role),
  //                           ))
  //                       .toList(),
  //                   decoration: InputDecoration(
  //                     labelText: 'Role',
  //                     filled: true,
  //                     fillColor: Colors.indigo[50],
  //                     prefixIcon: Icon(Icons.person_outline),
  //                     border: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(10.0),
  //                       borderSide: BorderSide.none,
  //                     ),
  //                   ),
  //                 ),
  //                 SizedBox(height: 20),
  //                 TextFormField(
  //                   decoration: InputDecoration(
  //                     labelText: 'Phone Number',
  //                     filled: true,
  //                     fillColor: Colors.indigo[50],
  //                     prefixIcon: Icon(Icons.phone),
  //                     border: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(10.0),
  //                       borderSide: BorderSide.none,
  //                     ),
  //                   ),
  //                   keyboardType: TextInputType.phone,
  //                   onSaved: (value) {
  //                     _phoneNumber = value!;
  //                   },
  //                 ),
  //                 SizedBox(height: 20),
  //                 TextFormField(
  //                   decoration: InputDecoration(
  //                     labelText: 'Full Name',
  //                     filled: true,
  //                     fillColor: Colors.indigo[50],
  //                     prefixIcon: Icon(Icons.account_circle),
  //                     border: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(10.0),
  //                       borderSide: BorderSide.none,
  //                     ),
  //                   ),
  //                   onSaved: (value) {
  //                     _fullName = value!;
  //                   },
  //                 ),
  //                 SizedBox(height: 20),
  //                 TextFormField(
  //                   decoration: InputDecoration(
  //                     labelText: 'Membership Number',
  //                     filled: true,
  //                     fillColor: Colors.indigo[50],
  //                     prefixIcon: Icon(Icons.card_membership),
  //                     border: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(10.0),
  //                       borderSide: BorderSide.none,
  //                     ),
  //                   ),
  //                   onSaved: (value) {
  //                     _membershipNumber = value!;
  //                   },
  //                 ),
  //                 if (_role == 'Judge') ...[
  //                   SizedBox(height: 20),
  //                   TextFormField(
  //                     decoration: InputDecoration(
  //                       labelText: 'Judge Number',
  //                       filled: true,
  //                       fillColor: Colors.indigo[50],
  //                       prefixIcon: Icon(Icons.gavel),
  //                       border: OutlineInputBorder(
  //                         borderRadius: BorderRadius.circular(10.0),
  //                         borderSide: BorderSide.none,
  //                       ),
  //                     ),
  //                     onSaved: (value) {
  //                       _judgeNumber = value!;
  //                     },
  //                   ),
  //                 ],
  //                 SizedBox(height: 20),
  //                 TextFormField(
  //                   decoration: InputDecoration(
  //                     labelText: 'ID Number',
  //                     filled: true,
  //                     fillColor: Colors.indigo[50],
  //                     prefixIcon: Icon(Icons.credit_card),
  //                     border: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(10.0),
  //                       borderSide: BorderSide.none,
  //                     ),
  //                   ),
  //                   onSaved: (value) {
  //                     _idNumber = value!;
  //                   },
  //                 ),
  //                 SizedBox(height: 20),
  //                 TextFormField(
  //                   decoration: InputDecoration(
  //                     labelText: 'Bio',
  //                     filled: true,
  //                     fillColor: Colors.indigo[50],
  //                     prefixIcon: Icon(Icons.info),
  //                     border: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(10.0),
  //                       borderSide: BorderSide.none,
  //                     ),
  //                   ),
  //                   maxLines: 3,
  //                   onSaved: (value) {
  //                     _bio = value!;
  //                   },
  //                 ),
  //                 SizedBox(height: 20),
  //                 ElevatedButton(
  //                   onPressed: _submit,
  //                   child: Text('Sign Up'),
  //                 ),
  //               ],
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   Text(_isSignUp
  //                       ? 'Already have an account?'
  //                       : 'Don’t have an account?'),
  //                   TextButton(
  //                     onPressed: _toggleForm,
  //                     child: Text(_isSignUp ? 'Login' : 'Sign Up'),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: LayoutBuilder(builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 32.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLogo(isMobile),
                    SizedBox(height: isMobile ? 20 : 40),
                    _buildUsernameTextField(),
                    SizedBox(height: isMobile ? 10 : 20),
                    _buildPasswordTextField(),
                    if (_isSignUp) _buildSignUpFields(isMobile),
                    _buildFormToggleButtons(isMobile),
                  ],
                ),
              ),
            ),
          );
        })));
  }

  Widget _buildLogo(bool isMobile) {
    return Hero(
      tag: 'logo',
      child: CircleAvatar(
        radius: isMobile ? 50 : 60,
        backgroundColor: Colors.indigoAccent,
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
    );
  }

  Widget _buildPasswordTextField() {
    return TextFormField(
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
    );
  }

  Widget _buildSignUpFields(bool isMobile) {
    return Column(
      children: [
        SizedBox(height: isMobile ? 10 : 20),
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
        SizedBox(height: isMobile ? 10 : 20),
        DropdownButtonFormField<String>(
          value: _role,
          onChanged: (newValue) {
            setState(() {
              _role = newValue!;
            });
          },
          items: ['Admin', 'Lawyer', 'Citizen', 'Judge']
              .map((role) => DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  ))
              .toList(),
          decoration: InputDecoration(
            labelText: 'Role',
            filled: true,
            fillColor: Colors.indigo[50],
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 10 : 20),
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
          keyboardType: TextInputType.phone,
          onSaved: (value) {
            _phoneNumber = value!;
          },
        ),
        SizedBox(height: isMobile ? 10 : 20),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Full Name',
            filled: true,
            fillColor: Colors.indigo[50],
            prefixIcon: const Icon(Icons.account_circle),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
          ),
          onSaved: (value) {
            _fullName = value!;
          },
        ),
        SizedBox(height: isMobile ? 10 : 20),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Membership Number',
            filled: true,
            fillColor: Colors.indigo[50],
            prefixIcon: const Icon(Icons.card_membership),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
          ),
          onSaved: (value) {
            _membershipNumber = value!;
          },
        ),
        if (_role == 'Judge') ...[
          SizedBox(height: isMobile ? 10 : 20),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Judge Number',
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
        ],
        SizedBox(height: isMobile ? 10 : 20),
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
        SizedBox(height: isMobile ? 10 : 20),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Bio',
            filled: true,
            fillColor: Colors.indigo[50],
            prefixIcon: const Icon(Icons.info),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
          ),
          maxLines: 3,
          onSaved: (value) {
            _bio = value!;
          },
        ),
        SizedBox(height: isMobile ? 20 : 20),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
          ),
          child: const Text(
            'Sign Up',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildFormToggleButtons(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_isSignUp ? 'Already have an account?' : 'Don’t have an account?'),
        TextButton(
          onPressed: _toggleForm,
          child: Text(
            _isSignUp ? 'Login' : 'Sign Up',
          ),
        ),
      ],
    );
  }
}

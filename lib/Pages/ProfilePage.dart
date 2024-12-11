import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:firstproj/Pages/TokenUtils.dart';
import 'package:firstproj/Pages/ManageClients.dart' as manageClients;
import 'package:firstproj/Pages/ManageCases.dart' as manageCases;
import 'package:firstproj/Pages/LegalDocuments.dart' as legalDocuments;
import 'package:firstproj/Pages/Reports.dart' as reports;
import 'package:firstproj/Pages/Billing.dart' as billing;
import 'package:firstproj/Pages/Notifications.dart' as notifications;
import 'package:firstproj/Pages/ManageComplaints.dart' as manageComplaints;
import 'package:firstproj/Pages/AdminDashboardPage.dart' as adminDashboardPage;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Timer _timer;
  bool isLoading = true;
  String fetchedData = '';

  String username = '';
  String email = '';
  String fullName = '';
  String phoneNumber = '';
  String bio = '';
  final ImagePicker _picker = ImagePicker();

  String adminPicUrl = ''; // To store the profile picture URL
  bool _isEditing = false;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      TokenUtils.checkTokenExpiration(context); // Add your token check logic
    });

    _loadUserData();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Update the profile picture
      setState(() {
        adminPicUrl =
            image.path; // You can upload the image to a server if needed
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      var box = await Hive.openBox('userBox');
      final token = box.get('token');

      if (token == null || token.isEmpty) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      final data =
          await fetchDataFromBackend(token); // Fetch admin data from API
      setState(() {
        isLoading = false;
        username = data['user']['username'] ?? 'User';
        email = data['user']['email'] ?? 'user@example.com';
        adminPicUrl = data['user']['profilePic'] ?? '';
        phoneNumber = data['user']['phoneNumber'] ?? '';
        fullName = data['user']['fullName'] ?? '';
        bio = data['user']['bio'] ?? '';

        // If no pic, use empty string
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        fetchedData = 'Error fetching admin data: $e';
      });
    }
  }

  Future<Map<String, dynamic>> fetchDataFromBackend(String token) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:4000/adminRoutes/get-my-info'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> _fetchData(String token) async {
    try {
      final data = await fetchDataFromBackend(token);
      setState(() {
        isLoading = false;
        username = data['user']['username'] ?? 'User';
        email = data['user']['email'] ?? 'user@example.com';
        adminPicUrl = data['user']['profilePic'] ?? '';
        phoneNumber = data['user']['phoneNumber'] ?? '';
        fullName = data['user']['fullName'] ?? '';
        bio = data['user']['bio'] ?? '';

        // Update the text controllers with the fetched data
        _usernameController.text = username;
        _emailController.text = email;
        _fullNameController.text = fullName;
        _phoneNumberController.text = phoneNumber;
        _bioController.text = bio;

        print(
            "User data updated: $username, $email, $fullName, $phoneNumber, $bio"); // Debug line
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        fetchedData = 'Error during request: $e';
      });
    }
  }

  Future<void> _saveChanges() async {
    var box = await Hive.openBox('userBox');

    // Save data to Hive box (local database)
    await box.put('username', _usernameController.text);
    await box.put('email', _emailController.text);
    await box.put('fullName', _fullNameController.text);
    await box.put('phoneNumber', _phoneNumberController.text);
    await box.put('bio', _bioController.text);

    // Set the local state with the new data
    setState(() {
      username = _usernameController.text;
      email = _emailController.text;
      fullName = _fullNameController.text;
      phoneNumber = _phoneNumberController.text;
      bio = _bioController.text;
    });

    setState(() {
      _isEditing = false;
    });

    // Fetch the token from local storage (e.g., from Hive)
    final token = box.get('token');

    // Send data to the server with the token in headers
    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:4000/adminRoutes/update-profile'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Add token here
        },
        body: jsonEncode({
          'username': _usernameController.text,
          'email': _emailController.text,
          'fullName': _fullNameController.text,
          'phoneNumber': _phoneNumberController.text,
          'bio': _bioController.text,
        }),
      );

      if (response.statusCode == 200) {
        // Successfully updated
        print('Profile updated successfully');
      } else {
        // Handle the error if the update failed
        print('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      print('Error occurred while updating profile: $e');
    }
  }

  void _showChangePasswordDialog() {
    final TextEditingController _oldPasswordController =
        TextEditingController();
    final TextEditingController _newPasswordController =
        TextEditingController();
    final TextEditingController _confirmPasswordController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Change Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Old Password"),
              ),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "New Password"),
              ),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Confirm New Password"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                // Check if new password and confirm password match
                if (_newPasswordController.text ==
                    _confirmPasswordController.text) {
                  await _changePassword(
                    _oldPasswordController.text,
                    _newPasswordController.text,
                  );
                  Navigator.of(context).pop();
                } else {
                  // Show error message if passwords don't match
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Passwords do not match")),
                  );
                }
              },
              child: Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changePassword(String oldPassword, String newPassword) async {
    var box = await Hive.openBox('userBox');
    final token = box.get('token');

    if (token == null || token.isEmpty) {
      // Handle token expiration or missing token
      Navigator.pushReplacementNamed(context, '/');
      return;
    }

    // Send the old and new passwords to the server for updating
    final response = await http.post(
      Uri.parse('http://10.0.2.2:4000/adminRoutes/update-password'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'currentPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      // Success, show a message or handle success response
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password updated successfully")),
      );
    } else {
      // Error, show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update password")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Page',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Color(0xFF0F3460),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => notifications.NotificationsPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.chat, color: Colors.white),
            onPressed: () {
              // Navigate to the chat page
            },
          ),
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {
              // Navigate to the profile page (current page)
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                backgroundImage: adminPicUrl.isNotEmpty
                    ? NetworkImage(
                        adminPicUrl) // If the profile pic URL exists, display the image
                    : null,
                child: adminPicUrl.isEmpty
                    ? Icon(
                        Icons.person,
                        size: 50,
                        color: Color(0xFF0F3460),
                      )
                    : null,
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blue),
                onPressed: _pickImage, // Trigger the method to pick a new image
              ),

              // CircleAvatar(
              //   radius: 35,
              //   backgroundColor: Colors.white,
              //   backgroundImage: adminPicUrl.isNotEmpty
              //       ? NetworkImage(adminPicUrl) // Use fetched image URL
              //       : null, // If no image URL, fallback to default icon
              //   child:
              //       adminPicUrl.isEmpty // Fallback to default icon if no image
              //           ? Icon(
              //               Icons.person,
              //               size: 50,
              //               color: Color(0xFF0F3460),
              //             )
              //           : null,
              // ),

              const SizedBox(height: 20),

              // Profile Information Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoField('Username', username, _usernameController),
                    _buildInfoField('Email', email, _emailController),
                    _buildInfoField('Full Name', fullName, _fullNameController),
                    _buildInfoField(
                        'Phone Number', phoneNumber, _phoneNumberController),
                    _buildInfoField('Bio', bio, _bioController),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _showChangePasswordDialog();
                },
                child: Text("Change Password"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
              // Edit/Submit Button
              if (!_isEditing) ...[
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  child: Text("Edit Profile"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: _saveChanges,
                  child: Text("Submit Changes"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Color(0xFF0F3460),
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFFADD8E6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    backgroundImage: adminPicUrl.isNotEmpty
                        ? NetworkImage(adminPicUrl) // Use fetched image URL
                        : null, // If no image URL, fallback to default icon
                    child: adminPicUrl
                            .isEmpty // Fallback to default icon if no image
                        ? Icon(
                            Icons.person,
                            size: 50,
                            color: Color(0xFF0F3460),
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    username,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.dashboard, 'Dashboard', () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const adminDashboardPage.AdminDashboardPage()),
              );
            }),
            _buildDrawerItem(Icons.people, 'Manage Clients', () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => manageClients.ManageClients()),
              );
            }),
            _buildDrawerItem(Icons.library_books, 'Manage Cases', () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => manageCases.ManageCases()),
              );
            }),
            _buildDrawerItem(Icons.report_problem, 'Manage Complaints', () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => manageComplaints.ManageComplaints()),
              );
            }),
            _buildDrawerItem(Icons.document_scanner, 'Legal Documents', () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const legalDocuments.LegalDocuments()),
              );
            }),
            _buildDrawerItem(Icons.notifications, 'Notifications', () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const notifications.NotificationsPage()),
              );
            }),
            _buildDrawerItem(Icons.chat, 'Chat', () {
              // Add chat navigation here
            }),
            _buildDrawerItem(Icons.bar_chart, 'Reports', () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => reports.ReportsPage()),
              );
            }),
            _buildDrawerItem(Icons.attach_money, 'Billing', () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => billing.BillingPage()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String text, Function onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(text, style: TextStyle(color: Colors.white)),
      onTap: () => onTap(),
    );
  }

  // Widget _buildInfoField(String label, String controller) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(controller,
  //           style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
  //       TextField(
  //         controller: label.,
  //         enabled: _isEditing,
  //         decoration: InputDecoration(
  //           hintText: label,
  //           border: OutlineInputBorder(),
  //         ),
  //       ),
  //       const SizedBox(height: 10),
  //     ],
  //   );
  // }
  Widget _buildInfoField(
      String label, String value, TextEditingController controller) {
    // Set the controller's text to the value passed in
    controller.text = value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        TextField(
          controller: controller, // Use the controller to manage the input
          enabled: _isEditing,
          decoration: InputDecoration(
            hintText: label,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

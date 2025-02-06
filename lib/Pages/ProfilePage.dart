import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'TokenUtils.dart';
import 'ManageClients.dart' as manageClients;
import 'ManageCases.dart' as manageCases;
import 'Reports.dart' as reports;
import 'Billing.dart' as billing;
import 'Notifications1.dart' as notifications;
import 'ChatPage.dart' as chat;
import 'AdminDashboardPage.dart' as adminDashboardPage;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p; // Import the path package

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
  String adminPicUrl = '';
  bool isEditing = true;
  bool isCancelOrSave = true;
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final bioController = TextEditingController();
  Map<String, dynamic>? userInfo;
  bool _isChangePassword = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      TokenUtils.checkTokenExpiration(context);
    });
    _loadUserData();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
         adminPicUrl = pickedFile.path;
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
        userInfo = data['user'];
        isLoading = false;
        username = data['user']['username'] ?? 'User';
        email = data['user']['email'] ?? 'user@example.com';
        adminPicUrl = data['user']['profilePic'] ?? '';
        phoneNumber = data['user']['phoneNumber'] ?? '';
        fullName = data['user']['fullName'] ?? '';
        bio = data['user']['bio'] ?? '';
        usernameController.text = username;
        emailController.text = email;
        fullNameController.text = fullName;
        phoneController.text = phoneNumber;
        bioController.text = bio;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        fetchedData = 'Error fetching admin data: $e';
      });
    }
  }

String _constructImageUrl(String relativePath) {
    final String baseUrl;
    if (kIsWeb) {
      baseUrl = 'http://192.168.0.186:4000'; // For web (replace with your IP)
    } else {
      baseUrl = 'http://10.0.2.2:4000'; // For Android emulator
    }

    // Using p.join to correctly combine base URL and relative path, ensuring there's only one slash.
    final String finalUrl = p.join(baseUrl, relativePath);

    print('the pic issssssss :$finalUrl'); // Debug print to see the constructed URL

    return finalUrl;
  }


  Future<Map<String, dynamic>> fetchDataFromBackend(String token) async {
    final fetdata = kIsWeb
        ? 'http://192.168.0.186:4000/adminRoutes/get-my-info' // For Web
        : 'http://10.0.2.2:4000/adminRoutes/get-my-info'; // For Android Emulator
    print("fetdata is $fetdata");

    final response = await http.post(
      Uri.parse(fetdata),
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
        userInfo = data['user'];
        isLoading = false;
        username = data['user']['username'] ?? 'User';
        email = data['user']['email'] ?? 'user@example.com';
          adminPicUrl = data['user']['profilePic'] ?? '';
        phoneNumber = data['user']['phoneNumber'] ?? '';
        fullName = data['user']['fullName'] ?? '';
        bio = data['user']['bio'] ?? '';
        usernameController.text = username;
        emailController.text = email;
        fullNameController.text = fullName;
        phoneController.text = phoneNumber;
        bioController.text = bio;
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
    await box.put('username', usernameController.text);
    await box.put('email', emailController.text);
    await box.put('fullName', fullNameController.text);
    await box.put('phoneNumber', phoneController.text);
    await box.put('bio', bioController.text);
    String? profilePicturePath;

     if (adminPicUrl.isNotEmpty) {
      // If the user has selected a new image
       profilePicturePath = adminPicUrl;
    } else if (userInfo != null &&
        userInfo!['profilePic'] != null &&
        userInfo!['profilePic'].trim().isNotEmpty) {
        profilePicturePath = userInfo!['profilePic'].trim();
    }

    await box.put('profile_picture', profilePicturePath);
    // Set the local state with the new data
    setState(() {
      username = usernameController.text;
      email = emailController.text;
      fullName = fullNameController.text;
      phoneNumber = phoneController.text;
      bio = bioController.text;
      isEditing = false;
      isCancelOrSave = false;
    });

    // Fetch the token from local storage (e.g., from Hive)
    final token = box.get('token');

    // Send data to the server with the token in headers
    try {
      final updatepr = kIsWeb
          ? 'http://192.168.0.186:4000/adminRoutes/update-profile'
          : 'http://10.0.2.2:4000/adminRoutes/update-profile';

      print("updatepr is $updatepr");

      final response = await http.put(
        Uri.parse(updatepr),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'username': usernameController.text,
          'email': emailController.text,
          'fullName': fullNameController.text,
          'phoneNumber': phoneController.text,
          'bio': bioController.text,
          'profile_picture': profilePicturePath
        }),
      );

      if (response.statusCode == 200) {
        // Successfully updated
        print('Profile updated successfully');
        if (ScaffoldMessenger.of(context).mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      } else {
        print('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      print('Error occurred while updating profile: $e');
    }
  }

  void _cancelChanges() {
    setState(() {
      isEditing = false;
      isCancelOrSave = false;
      // Restore the old values, we can use `userInfo` as source of truth here.
      usernameController.text = userInfo?['username'] ?? '';
      emailController.text = userInfo?['email'] ?? '';
      fullNameController.text = userInfo?['fullName'] ?? '';
      phoneController.text = userInfo?['phoneNumber'] ?? '';
      bioController.text = userInfo?['bio'] ?? '';
    });
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
    final updatepass = kIsWeb
        ? 'http://192.168.0.186:4000/adminRoutes/update-password'
        : 'http://10.0.2.2:4000/adminRoutes/update-password';

    print("updatepass is $updatepass");

    final response = await http.post(
      Uri.parse(updatepass),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        enabled: isEditing,
        style: TextStyle(
          color: isEditing ? Color(0xFF003366) : Colors.white,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: isEditing ? Colors.grey[600] : Colors.white,
          ),
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 18,
            color: isEditing ? Color(0xFF003366) : Colors.white,
          ),
          filled: true,
          fillColor: isEditing ? Colors.white : Color(0xFF003366),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: Color(0xFF003366),
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: Color(0xFF003366),
              width: 2,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: Color(0xFF003366),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }


    Widget _buildProfilePicture() {
    ImageProvider? imageProvider;

    if (adminPicUrl.isNotEmpty) {
      // If adminPicUrl is not empty, it means the image is either a local file path or a network url
      if (adminPicUrl.startsWith('http')) {
        imageProvider = NetworkImage(adminPicUrl);
      } else {
         imageProvider = FileImage(File(adminPicUrl));
      }

    } else if (userInfo != null &&
        userInfo!['profilePic'] != null &&
        userInfo!['profilePic'].trim().isNotEmpty) {
      // if there is no image from the image picker use the network image
      imageProvider = NetworkImage(_constructImageUrl(userInfo!['profilePic'].trim()));
    } else {
      // Default placeholder if no image
      return CircleAvatar(
        radius: 65,
        backgroundColor: Colors.white,
        child: Icon(
          Icons.person,
          size: 80,
          color: Color(0xFF003366),
        ),
      );
    }

    return CircleAvatar(
      radius: 65,
      backgroundImage: imageProvider,
      backgroundColor: Colors.white,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => adminDashboardPage.AdminDashboardPage()),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>  notifications.NotificationPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.chat, color: Colors.black),
            onPressed: () {
              // Navigator.pushReplacement(
              //   //context
              //   //MaterialPageRoute(builder: (context) => chat.ChatPage()),
              // );
            },
          ),
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.black),
            onPressed: () {
              // Navigate to the profile page (current page)
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: Color(0xFF003366),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.elliptical(400, 150),
                            bottomRight: Radius.elliptical(400, 150),
                          ),
                        ),
                      ),
                      Positioned(
                          top: 10,
                          left: 10,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isCancelOrSave = true;
                                isEditing = true;
                              });
                            },
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.white, size: 24),
                                SizedBox(width: 5),
                                Text(
                                  "Edit Profile",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )),
                      Positioned(
                        top: 140,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: Color(0xFF003366),
                                shape: BoxShape.circle,
                              ),
                              child: _buildProfilePicture(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Padding(
                    padding: EdgeInsets.only(left: 95),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isEditing = true;
                          isCancelOrSave = true;
                        });
                        _pickImage();
                      },
                      child: Container(
                        padding: EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Color(0xFF003366),
                            width: 1,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        _buildTextField(
                          label: 'User Name',
                          controller: usernameController,
                          icon: Icons.person,
                        ),
                        _buildTextField(
                          label: 'Full Name',
                          controller: fullNameController,
                          icon: Icons.person,
                        ),
                        _buildTextField(
                          label: 'Bio',
                          controller: bioController,
                          icon: Icons.article_outlined,
                        ),
                        _buildTextField(
                          label: 'Email',
                          controller: emailController,
                          icon: Icons.email,
                        ),
                        _buildTextField(
                          label: 'Phone Number',
                          controller: phoneController,
                          icon: Icons.phone,
                        ),
                        GestureDetector(
                          onTap: () {
                            _showChangePasswordDialog();
                            setState(() {
                              _isChangePassword = true;
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Change password',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF003366),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Color(0xFF003366),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  if (isEditing) // Conditional rendering of the button Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: 120,
                          child: ElevatedButton(
                            onPressed: _cancelChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF003366),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 32,
                              ),
                            ),
                            child: Text('CANCEL'),
                          ),
                        ),
                        SizedBox(width: 10),
                        SizedBox(
                          width: 120,
                          child: ElevatedButton(
                            onPressed: _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF003366),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 32,
                              ),
                            ),
                            child: Text('SAVE'),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 20),
                ],
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
                        ? FileImage(File(adminPicUrl))
                        : userInfo != null &&
                                userInfo!['profilePic'] != null &&
                                userInfo!['profilePic'].trim().isNotEmpty
                            ? NetworkImage(
                                _constructImageUrl(
                                    userInfo!['profilePic'].trim()),
                              )
                            : null,
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
            _buildDrawerItem(Icons.notifications, 'Notifications', () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>   notifications.NotificationPage()),
              );
            }),
             _buildDrawerItem(Icons.chat, 'Chat', () {
              // Navigator.pushReplacement(
              //   context,
              //  // MaterialPageRoute(builder: (context) => chat.ChatPage()),
              // );
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
}
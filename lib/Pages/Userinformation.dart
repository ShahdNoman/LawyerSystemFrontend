import 'package:flutter/material.dart';
import 'TokenUtils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
class Userinformation extends StatefulWidget {
  const Userinformation({super.key});
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<Userinformation> {
  bool isLoading = true;
  Map<String, dynamic>? userInfo;
  bool isEditing = false;
  bool iscancelorsave = true;
  String fetchedData = "";
  bool _ischangePassword = false;
  late Timer _timer;
  final ImagePicker _picker = ImagePicker();
  String adminPicUrl = ''; // لتخزين رابط صورة البروفايل
  String username = '';
  String email = '';
  String fullName = '';
  String phoneNumber = '';
  String bio = '';
  TextEditingController usernameController = TextEditingController();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _userhData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TokenUtils.checkTokenExpiration(context);
    });
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      TokenUtils.checkTokenExpiration(context);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
  

String? getOriginalImageName(String imagePath) {
  try {
      return path.basename(imagePath);
  } catch(e) {
    print('Error getting the original name from the path $e');
  }
  return null;
}

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        adminPicUrl = pickedFile.path;
      });
    }
  }

  Future<void> _userhData() async {
    try {
      var box = await Hive.openBox('userBox');
      final token = box.get('token');

      if (token == null || token.isEmpty) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }
      final response = await http.get(
        Uri.parse('http://10.0.2.2:4000/home/get-my-info'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          userInfo = result['user'];
          isLoading = false;
          usernameController.text = userInfo?['username'] ?? '';
          fullNameController.text = userInfo?['fullName'] ?? '';
          bioController.text = userInfo?['bio'] ?? '';
          emailController.text = userInfo?['email'] ?? '';
          phoneController.text = userInfo?['phoneNumber'] ?? '';
        });
      } else {
        setState(() {
          isLoading = false;
          fetchedData =
              'Failed to fetch data. Status Code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        fetchedData = 'Error during request: $e';
      });
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
/*
  Future<void> _saveChanges() async {
    var box = await Hive.openBox('userBox');
    // Save data to Hive box (local database)
    await box.put('username', usernameController.text);
    await box.put('email', emailController.text);
    await box.put('fullName', fullNameController.text);
    await box.put('profile_picture,');
    await box.put('phoneNumber', phoneController.text);
    await box.put('bio', bioController.text);
    // Set the local state with the new data
    setState(() {
      username = usernameController.text;
      email = emailController.text;
      fullName = fullNameController.text;
      phoneNumber = phoneController.text;
      bio = bioController.text;
    });

    setState(() {
      iscancelorsave = true;
      isEditing = false;
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
          'username': usernameController.text,
          'email': emailController.text,
          'full_name': fullNameController.text,
          'phone_number': phoneController.text,
          'bio': bioController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile Updated Successfully!',
              style: TextStyle(color: Colors.white), // لون النص
            ),
            backgroundColor:
                Color(0xFF003366), // لون الخلفية (أزرق فاتح مشابه للصورة)
            duration: Duration(seconds: 2), // مدة عرض الرسالة
            behavior: SnackBarBehavior.floating, // سلوك الـ SnackBar (عائم)
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // زوايا دائرية
            ),
          ),
        );
      } else {
        // Handle the error if the update failed
        print('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      print('Error occurred while updating profile: $e');
    }
  }*/

  Future<void> _saveChanges() async {
  var box = await Hive.openBox('userBox');

  // حفظ البيانات في قاعدة البيانات المحلية (Hive)
  await box.put('username', usernameController.text);
  await box.put('email', emailController.text);
  await box.put('fullName', fullNameController.text);
  await box.put('phoneNumber', phoneController.text);
  await box.put('bio', bioController.text);
 String? profilePicturePath;

  if (adminPicUrl.isNotEmpty) {
    // إذا اختار المستخدم صورة جديدة
    profilePicturePath = adminPicUrl;
  } else if (userInfo != null &&
      userInfo!['profilePic'] != null &&
      userInfo!['profilePic'].trim().isNotEmpty) {
    // إذا كانت هناك صورة في userInfo
    profilePicturePath = userInfo!['profilePic'].trim();
  } 

  // حفظ الصورة المحدثة في قاعدة البيانات المحلية
  await box.put('profile_picture', profilePicturePath);


  setState(() {
    username = usernameController.text;
    email = emailController.text;
    fullName = fullNameController.text;
    phoneNumber = phoneController.text;
    bio = bioController.text;
    iscancelorsave = true;
    isEditing = false;
  });

  // جلب التوكن من قاعدة البيانات
  final token = box.get('token');

  // إرسال البيانات إلى السيرفر
  try {
    final response = await http.put(
      Uri.parse('http://10.0.2.2:4000/adminRoutes/update-profile'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'username': usernameController.text,
        'email': emailController.text,
        'full_name': fullNameController.text,
        'phone_number': phoneController.text,
        'bio': bioController.text,
        'profile_picture': profilePicturePath
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile Updated Successfully!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF003366),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
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
      iscancelorsave = true;
      usernameController.text = userInfo?['username'] ?? '';
      fullNameController.text = userInfo?['fullName'] ?? '';
      bioController.text = userInfo?['bio'] ?? '';
      emailController.text = userInfo?['email'] ?? '';
      phoneController.text = userInfo?['phoneNumber'] ?? '';
    });
  }

  void _showChangePasswordDialog() {
    final TextEditingController oldPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController =
        TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
                color: Color(0xFF003366), width: 5), // الحواف الزرقاء
          ),
          elevation: 7, // تأثير الظل
          title: Text("Change Password"),
          titleTextStyle: TextStyle(
            color: Color(0xFF003366), // لون الـ label عند الحالة العادية
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Old Password",
                  labelStyle: TextStyle(
                    color:
                        Color(0xFF003366), // لون الـ label عند الحالة العادية
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: Color(0xFF003366), width: 3), // خط أزرق
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: Color(0xFF003366),
                        width: 5), // خط أزرق عند التركيز
                  ),
                ),
              ),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "New Password",
                  labelStyle: TextStyle(
                    color:
                        Color(0xFF003366), // لون الـ label عند الحالة العادية
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: Color(0xFF003366), width: 3), // خط أزرق
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: Color(0xFF003366),
                        width: 5), // خط أزرق عند التركيز
                  ),
                ),
              ),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Confirm New Password",
                  labelStyle: TextStyle(
                    color:
                        Color(0xFF003366), // لون الـ label عند الحالة العادية
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: Color(0xFF003366), width: 3), // خط أزرق
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: Color(0xFF003366),
                        width: 5), // خط أزرق عند التركيز
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _ischangePassword = false;
                });
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (newPasswordController.text ==
                    confirmPasswordController.text) {
                  await _changePassword(
                    oldPasswordController.text,
                    newPasswordController.text,
                  );
                  setState(() {
                    _ischangePassword = false;
                  });
                  Navigator.of(context).pop();
                } else {
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                        child: iscancelorsave
                            ? GestureDetector(
                                onTap: () {
                                  setState(() {
                                    iscancelorsave = false;
                                    isEditing = true;
                                  });
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.edit,
                                        color: Colors.white, size: 24),
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
                              )
                            : SizedBox.shrink(),
                      ),
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
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    radius: 65,
                                    backgroundImage: adminPicUrl.isNotEmpty
                                        ? FileImage(File(adminPicUrl))
                                        : userInfo != null &&
                                                userInfo!['profilePic'] !=
                                                    null &&
                                                userInfo!['profilePic']
                                                    .trim()
                                                    .isNotEmpty
                                            ? NetworkImage(
                                                userInfo!['profilePic'].trim(),
                                              )
                                            : null,
                                    backgroundColor: Colors.white,
                                  ),
                                ],
                              ),
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
                          iscancelorsave = false;
                          isEditing = true;
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
                          label: isEditing ? 'User Name' : '',
                          controller: usernameController,
                          icon: Icons.person,
                        ),
                        _buildTextField(
                          label: isEditing ? 'Full Name' : '',
                          controller: fullNameController,
                          icon: Icons.person,
                        ),
                        _buildTextField(
                          label: isEditing ? 'Bio' : '',
                          controller: bioController,
                          icon: Icons.article_outlined,
                        ),
                        _buildTextField(
                          label: isEditing ? 'Email' : '',
                          controller: emailController,
                          icon: Icons.email,
                        ),
                        _buildTextField(
                          label: isEditing ? 'Phone Number' : '',
                          controller: phoneController,
                          icon: Icons.phone,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Change password',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF003366), // لون النص الأزرق
                              ),
                            ),
                            Switch(
                              value: _ischangePassword,
                              onChanged: (value) {
                                _showChangePasswordDialog();
                                setState(() {
                                  _ischangePassword = value;
                                });
                              },
                              activeColor:
                                  Colors.white, // اللون الداخلي عند التفعيل
                              activeTrackColor:
                                  Color(0xFF003366), // لون الخلفية عند التفعيل
                              inactiveThumbColor: Color(
                                  0xFF003366), // اللون الداخلي عند عدم التفعيل
                              inactiveTrackColor:
                                  Colors.white, // لون الخلفية عند عدم التفعيل
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  if (isEditing)
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
}
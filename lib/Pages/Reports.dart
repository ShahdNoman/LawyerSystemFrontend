import 'ProfilePage.dart';
import 'Notifications1.dart' as notifications;
import 'TokenUtils.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'ManageClients.dart' as manageClients;
import 'ManageCases.dart' as manageCases;
import 'Reports.dart' as reports;
import 'Billing.dart' as billing;
import 'AdminDashboardPage.dart' as adminDashboardPage;
import 'package:flutter/foundation.dart'; // Import to check if running on web

const Color backgroundColor = Colors.white;
const Color lightBlueColor = Color(0xFFADD8E6);
const Color blueColor = Color(0xFF0F3460);
const Color cardColor = Color(0xFFB0E0E6);

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late Timer _timer;
  bool isLoading = true;
  String fetchedData = '';
  String adminName = 'Admin'; // Default name
  String adminEmail = 'admin@example.com'; // Default email
  String adminPicUrl = ''; // To store the profile picture URL

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      TokenUtils.checkTokenExpiration(context);
    });

    _fetchAdminData(); // Fetch admin data when the page is initialized
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>> fetchAdminData(String token) async {
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
      return json.decode(response.body); // Parse and return the response
    } else {
      throw Exception(
          'Failed to load admin data. Status Code: ${response.statusCode}');
    }
  }

  Future<void> _fetchAdminData() async {
    try {
      var box = await Hive.openBox('userBox');
      final token = box.get('token');

      if (token == null || token.isEmpty) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      final data = await fetchAdminData(token); // Fetch admin data from API
      setState(() {
        isLoading = false;
        adminName = data['user']['username'] ?? 'Admin';
        adminEmail = data['user']['email'] ?? 'admin@example.com';
        adminPicUrl = data['user']['profilePic'] ?? '';
        // If no pic, use empty string
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        fetchedData = 'Error fetching admin data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reports',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Color(0xFF0F3460),
      ),
      drawer: _buildDrawer(),
      body: _buildDashboardContent(),
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
                    adminName, // Display fetched admin name
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    adminEmail, // Display fetched admin email
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Menu items
            _buildDrawerItem(Icons.dashboard, 'Dashboard', () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        adminDashboardPage.AdminDashboardPage()),
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
            _buildDrawerItem(Icons.library_books, 'Reports', () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => reports.ReportsPage()),
              );
            }),
            _buildDrawerItem(Icons.notifications, 'Notifications', () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        notifications.NotificationPage()),
              );
            }),
            _buildDrawerItem(Icons.chat, 'Chat', () {
              // Add chat navigation logic
            }),
            _buildDrawerItem(Icons.account_circle, 'Admin Profile', () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            }),
            _buildDrawerItem(Icons.logout, 'Logout', () {
              Navigator.pushReplacementNamed(context, '/');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, Function() onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 20),
      title: Text(title, style: TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  Widget _buildDashboardContent() {
    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          _buildSearchRow(),
        ],
      ),
    );
  }

  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: lightBlueColor),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.notifications, color: blueColor),
            onPressed: () {
              // Add notification icon logic
            },
          ),
          IconButton(
            icon: Icon(Icons.chat, color: blueColor),
            onPressed: () {
              // Add chat icon logic
            },
          ),
          IconButton(
            icon: Icon(Icons.account_circle, color: blueColor),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
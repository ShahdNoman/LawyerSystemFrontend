import 'package:firstproj/Pages/TokenUtils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'package:firstproj/Pages/ManageClients.dart' as manageClients;
import 'package:firstproj/Pages/ManageCases.dart' as manageCases;
import 'package:firstproj/Pages/LegalDocuments.dart' as legalDocuments;
import 'package:firstproj/Pages/Reports.dart' as reports;
import 'package:firstproj/Pages/Billing.dart' as billing;
import 'package:firstproj/Pages/Notifications.dart' as notifications;
import 'package:firstproj/Pages/ManageComplaints.dart' as manageComplaints;

const Color backgroundColor = Colors.white;
const Color lightBlueColor = Color(0xFFADD8E6);
const Color blueColor = Color(0xFF0F3460);
const Color cardColor = Color(0xFFB0E0E6);

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late Timer _timer;
  bool isLoading = true;
  String fetchedData = '';

  @override
  void initState() {
    super.initState();
    // Token expiration check
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      TokenUtils.checkTokenExpiration(context); // Add your token check logic
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>> fetchDataFromBackend(String token) async {
    final response = await http.get(
      Uri.parse(
          'https://your-backend-api.com/endpoint'), // Replace with your backend API URL
      headers: {
        'Authorization': 'Bearer $token', // Use the token for authentication
      },
    );

    if (response.statusCode == 200) {
      // Parse the JSON response
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> _fetchData() async {
    try {
      var box = await Hive.openBox('userBox');
      final token = box.get('token');
      print('Token retrieved: $token');

      if (token == null || token.isEmpty) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      final data = await fetchDataFromBackend(token);
      setState(() {
        isLoading = false;
        fetchedData = data['message'];
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        fetchedData = 'Error during request: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lawyer System Dashboard',
          style: TextStyle(color: Colors.white),
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
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Color(0xFF0F3460),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Welcome, Admin!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'admin@example.com',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard, color: Colors.white),
              title: const Text('Dashboard',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdminDashboardPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.people, color: Colors.white),
              title: const Text('Manage Clients',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => manageClients.ManageClients()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.library_books, color: Colors.white),
              title: const Text('Manage Cases',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => manageCases.ManageCases()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.report_problem, color: Colors.white),
              title: const Text('Manage Complaints',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          manageComplaints.ManageComplaints()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.document_scanner, color: Colors.white),
              title: const Text('Legal Documents',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const legalDocuments.LegalDocuments()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.white),
              title:
                  const Text('Logout', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          _buildGreetingCard(),
          const SizedBox(height: 20),
          Expanded(
            child: _buildFeatureGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingCard() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.gavel, size: 50, color: blueColor),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Good Morning, Admin!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Here’s what’s happening today in your legal system:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final List<Map<String, dynamic>> features = [
      {'icon': Icons.people, 'title': 'Manage Clients'},
      {'icon': Icons.library_books, 'title': 'Manage Cases'},
      {'icon': Icons.document_scanner, 'title': 'Legal Documents'},
      {'icon': Icons.notifications, 'title': 'Notifications'},
      {'icon': Icons.attach_money, 'title': 'Billing'},
      {'icon': Icons.report, 'title': 'Reports'},
      {
        'icon': Icons.report_problem,
        'title': 'Manage Complaints'
      }, // Add this line
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        return _buildFeatureCard(
            features[index]['icon'], features[index]['title']);
      },
    );
  }

  Widget _buildFeatureCard(IconData icon, String title) {
    return Card(
      color: lightBlueColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          // Add feature-specific logic
          if (title == 'Manage Clients') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => manageClients.ManageClients()),
            );
          } else if (title == 'Manage Cases') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => manageCases.ManageCases()),
            );
          } else if (title == 'Manage Complaints') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => manageComplaints.ManageComplaints()),
            );
          } else if (title == 'Legal Documents') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const legalDocuments.LegalDocuments()),
            );
          } else if (title == 'Notifications') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      const notifications.NotificationsPage()),
            );
          } else if (title == 'Billing') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const billing.BillingPage()),
            );
          } else if (title == 'Reports') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const reports.ReportsPage()),
            );
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: blueColor),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

import 'ProfilePage.dart';
import 'Notifications1.dart' as notifications;
import 'ChatPage.dart' as chat;
import 'TokenUtils.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'ManageClients.dart' as manageClients;
import 'ManageCases.dart' as manageCases;
import 'Reports.dart' as reports;
import 'package:flutter/foundation.dart'; // Import to check if running on web
import 'LoginPage.dart';

const Color primaryColor = Color.fromARGB(255, 1, 25, 65);
const Color secondaryColor = Color.fromARGB(255, 1, 25, 65);
const Color lightBlueColor = Color(0xFFe0f2f7); // A very light blue
const Color accentColor = Color.fromARGB(255, 1, 25, 65);
const Color backgroundColor = Color(0xFFF0F4F8);
const Color textPrimaryColor = Color.fromARGB(255, 1, 25, 65);
const Color textSecondaryColor =
    Colors.white70; // For secondary text on dark backgrounds
const Color blueColor = Color.fromARGB(255, 1, 25, 65); // Main blue
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
  String adminName = 'Admin'; // Default name
  String adminEmail = 'admin@example.com'; // Default email
  String adminPicUrl = ''; // To store the profile picture URL
  String adminId = '';
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
    final admindata = kIsWeb
        ? 'http://192.168.0.186:4000/adminRoutes/get-my-info' // For Web (Chrome)
        : 'http://10.0.2.2:4000/adminRoutes/get-my-info'; // For Android Emulator

    print("admindata is $admindata");

    final response = await http.post(
      Uri.parse(admindata),
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

  String _constructImageUrl(String relativePath) {
    final String baseUrl;
    if (kIsWeb) {
      baseUrl = 'http://192.168.0.186:4000'; //or the actual ip
    } else {
      baseUrl = 'http://10.0.2.2:4000';
    }
    print('the pic issssssss :$baseUrl/$relativePath');

    return '$baseUrl/$relativePath';
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
        adminId = data['user']['id'].toString() ?? '0';
        adminName = data['user']['username'] ?? 'Admin';
        adminEmail = data['user']['email'] ?? 'admin@example.com';
        adminPicUrl = data['user']['profilePic'] ?? '';
        adminPicUrl = _constructImageUrl(adminPicUrl);

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
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth < 700;
      return Scaffold(
        appBar: _buildAppBar(isMobile),
        drawer: isMobile ? _buildDrawer(isMobile) : null,
        body: _buildBody(isMobile, constraints),
      );
    });
  }

  PreferredSizeWidget _buildAppBar(bool isMobile) {
    return AppBar(
      title: Text(
        'JustiPro Admin $adminName Dashboard', // Corrected string interpolation
        style: TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      backgroundColor: primaryColor,
      leading: isMobile
          ? _buildDrawerButton()
          : null, // On web we don't need hamburger
    );
  }

  Widget _buildDrawerButton() {
    return Builder(builder: (context) {
      return IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          });
    });
  }

  Widget _buildBody(bool isMobile, BoxConstraints constraints) {
    return Row(
      children: [
        if (!isMobile) // Show drawer as a sidebar for large screens
          _buildDrawer(isMobile),
        Expanded(
            child: _buildDashboardContent(
                isMobile, constraints)) // Expand content to fill
      ],
    );
  }

  Widget _buildDrawer(bool isMobile) {
    return Drawer(
      child: Container(
        width: isMobile ? null : 250, // Drawer width for larger screens
        color: primaryColor,
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: secondaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: isMobile ? 30 : 35,
                    backgroundColor: Colors.white,
                    backgroundImage: adminPicUrl.isNotEmpty
                        ? NetworkImage(adminPicUrl)
                        : null,
                    child: adminPicUrl.isEmpty
                        ? Icon(
                            Icons.person,
                            size: isMobile ? 40 : 50,
                            color: primaryColor,
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    adminName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 16 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    adminEmail,
                    style: TextStyle(
                      color: textSecondaryColor,
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.dashboard, 'Dashboard', () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdminDashboardPage()));
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
            _buildDrawerItem(Icons.bar_chart, 'Reports', () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => reports.ReportsPage()),
              );
            }),
            _buildDrawerItem(Icons.notifications, 'Notifications', () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => notifications.NotificationPage()),
              );
            }),
            _buildDrawerItem(Icons.chat, 'Chat', () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => chat.ChatPage(),
                ),
              );
            }),
            _buildDrawerItem(Icons.account_circle, 'Admin Profile', () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            }),
            _buildDrawerItem(Icons.logout, 'Logout', () {
              onTap:
              () async {
                var box = await Hive.openBox('userBox');
                await box.delete('token');
                await box.delete('token_expiration');
                if (ScaffoldMessenger.of(context).mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Future.delayed(const Duration(seconds: 0), () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AnimatedLoginPage()));
                    });
                  });
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AnimatedLoginPage()),
                );
              };
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, Function() onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 20),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
      hoverColor: secondaryColor.withOpacity(0.2),
      splashColor: secondaryColor.withOpacity(0.4),
    );
  }

  Widget _buildDashboardContent(bool isMobile, BoxConstraints constraints) {
    return Container(
      color: backgroundColor,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildSearchRow(isMobile),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(12.0),
            sliver: SliverToBoxAdapter(
              child: _buildKeyMetrics(isMobile),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchRow(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: lightBlueColor),
                ),
              ),
            ),
          ),
          if (isMobile) ...[
            IconButton(
              icon: Icon(Icons.notifications, color: blueColor),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => notifications.NotificationPage()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.chat, color: blueColor),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => chat.ChatPage(),
                  ),
                );
              },
            ),
          ],
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

  Widget _buildKeyMetrics(bool isMobile) {
    // Placeholder data - Replace with your data source
    final List<Map<String, dynamic>> metrics = [
      {'label': 'Total Clients', 'value': 250, 'icon': Icons.people},
      {'label': 'Active Cases', 'value': 75, 'icon': Icons.folder_open},
      {'label': 'Pending Invoices', 'value': 15, 'icon': Icons.pending},
      {
        'label': 'Monthly Revenue',
        'value': '\$12,500',
        'icon': Icons.attach_money
      },
    ];

    return GridView.builder(
        shrinkWrap: true, //Add this
        padding: const EdgeInsets.all(12.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isMobile ? 2 : 4,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio: 1.1,
        ),
        itemCount: metrics.length,
        itemBuilder: (context, index) {
          return _buildMetricCard(metrics[index]);
        });
  }

  Widget _buildMetricCard(Map<String, dynamic> metric) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8.0,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  metric['icon'],
                  size: 28,
                  color: accentColor,
                ),
                const SizedBox(width: 8),
                Text(
                  metric['label'],
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color.fromARGB(255, 96, 94, 94),
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                metric['value'].toString(),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textPrimaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphicalReports(bool isMobile) {
    return const SizedBox();
  }
}

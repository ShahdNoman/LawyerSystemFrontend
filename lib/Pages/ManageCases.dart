import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firstproj/Pages/TokenUtils.dart';
import 'dart:async';
import 'package:firstproj/Pages/ProfilePage.dart';
import 'package:intl/intl.dart'; // For formatting the date
import 'package:firstproj/Pages/AdminDashboardPage.dart' as adminDashboardPage;
import 'package:firstproj/Pages/ManageClients.dart' as manageClients;
import 'package:firstproj/Pages/ManageCases.dart' as manageCases;
import 'package:firstproj/Pages/Reports.dart' as reports;
import 'package:firstproj/Pages/Billing.dart' as billing;
import 'package:firstproj/Pages/Notifications.dart' as notifications;

import 'package:hive_flutter/hive_flutter.dart';

const Color blueColor = Color(0xFF0F3460);
const Color backgroundColor = Colors.white;
const Color lightBlueColor = Color(0xFFADD8E6);

class ManageCases extends StatefulWidget {
  ManageCases({Key? key}) : super(key: key);

  @override
  _ManageCasesState createState() => _ManageCasesState();
}

class _ManageCasesState extends State<ManageCases> {
  late String token = ""; // Initialize token with an empty string
  bool isLoading = false;
  String fetchedData = '';
  late Timer _timer;
  String adminName = 'Admin'; // Default name
  String adminEmail = 'admin@example.com'; // Default email
  String adminPicUrl = ''; // To store the profile picture URL
  List<dynamic> filteredCases = [];
  TextEditingController _searchController = TextEditingController();
  List<dynamic> displayedCases = []; // To show filtered cases
  TextEditingController caseTitleController = TextEditingController();
  TextEditingController caseDescriptionController = TextEditingController();
  TextEditingController caseClientController = TextEditingController();
  TextEditingController caseStatusController = TextEditingController();
  TextEditingController caseIdToDeleteController = TextEditingController();
  String selectedStatus = 'Open'; // Declare selectedStatus here
  String errorMessage = '';
  List<dynamic> cases = [];
  List<dynamic> selectedNotification = [];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      TokenUtils.checkTokenExpiration(context);
    });
    _fetchAdminData();
    _fetchCases();
    _getToken();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _filterCases(String query) {
    if (query.isEmpty) {
      setState(() {
        displayedCases = cases;
      });
    } else {
      // Filter cases based on the query
      setState(() {
        displayedCases = cases.where((caseData) {
          return caseData['case_number']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              caseData['case_status']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  Future<void> _getToken() async {
    var box = await Hive.openBox('userBox');
    final tokenFromBox = box.get('token');
    if (tokenFromBox == null || tokenFromBox.isEmpty) {
      // Redirect to login page if no token is found
      Navigator.pushReplacementNamed(context, '/');
    } else {
      setState(() {
        token = tokenFromBox; // Store token in the state
      });
    }
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
    } else if (response.statusCode == 429) {
      throw Exception('Too many requests. Please try again later.');
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

  Future<void> _fetchCases() async {
    try {
      var box = await Hive.openBox('userBox');
      final token = box.get('token');

      if (token == null || token.isEmpty) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      final List<dynamic> data =
          await fetchCases(token); // Fetch all cases once

      setState(() {
        cases = data; // Store the fetched cases
        displayedCases = cases;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching cases: $e';
      });
      print('Error: $e');
    }
  }

  Future<List<dynamic>> fetchCases(String token) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:4000/adminRoutes/viewAll-cases'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      // Parse and return the response body as a list of users
      return json.decode(response.body) as List<dynamic>;
    } else if (response.statusCode == 429) {
      throw Exception('Too many requests. Please try again later.');
    } else {
      throw Exception(
          'Failed to load admin data. Status Code: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAttachmentsForCase(
      int caseId, String token) async {
    final response = await http.post(
      Uri.parse(
          'http://10.0.2.2:4000/adminRoutes/get-attachment'), // Adjust the URL to match your backend endpoint
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'case_id': caseId, // Send case_id in the body
      }),
    );
    print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      try {
        final responseData = json.decode(response.body);
        print('Decoded response: $responseData');
        if (responseData.containsKey('attachments')) {
          return List<Map<String, dynamic>>.from(responseData['attachments']);
        } else {
          throw Exception('No attachments found in the response.');
        }
      } catch (e) {
        print('Error parsing response: $e');
        throw Exception('Failed to parse attachments data.');
      }
    } else if (response.statusCode == 429) {
      throw Exception('Too many requests. Please try again later.');
    } else {
      throw Exception(
          'Failed to load attachments. Status Code: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchComplaintsForCase(
      int caseId, String token) async {
    final response = await http.post(
      Uri.parse(
          'http://10.0.2.2:4000/adminRoutes/get-complaint'), // Adjust the URL to match your backend endpoint
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'case_id': caseId, // Send case_id in the body
      }),
    );
    print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      try {
        final responseData = json.decode(response.body);
        print('Decoded response: $responseData');
        if (responseData.containsKey('complaints')) {
          return List<Map<String, dynamic>>.from(responseData['complaints']);
        } else {
          throw Exception('No attachments found in the response.');
        }
      } catch (e) {
        print('Error parsing response: $e');
        throw Exception('Failed to parse attachments data.');
      }
    } else if (response.statusCode == 429) {
      throw Exception('Too many requests. Please try again later.');
    } else {
      throw Exception(
          'Failed to load attachments. Status Code: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchSessionsForCase(
      int caseId, String token) async {
    final response = await http.post(
      Uri.parse(
          'http://10.0.2.2:4000/adminRoutes/get-sessions'), // Adjust the URL to match your backend endpoint
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'case_id': caseId, // Send case_id in the body
      }),
    );
    print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      print('Response body: ${response.body}');
      return List<Map<String, dynamic>>.from(
          json.decode(response.body)['sessions']);
    } else if (response.statusCode == 429) {
      throw Exception('Too many requests. Please try again later.');
    } else {
      throw Exception(
          'Failed to load payments. Status Code: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPaymentsForCase(
      int caseId, String token) async {
    final response = await http.post(
      Uri.parse(
          'http://10.0.2.2:4000/adminRoutes/get-payments'), // Adjust the URL to match your backend endpoint
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'case_id': caseId, // Send case_id in the body
      }),
    );
    print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      print('Response body: ${response.body}');
      return List<Map<String, dynamic>>.from(
          json.decode(response.body)['payments']);
    } else if (response.statusCode == 429) {
      throw Exception('Too many requests. Please try again later.');
    } else {
      throw Exception(
          'Failed to load payments. Status Code: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Cases',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Color(0xFF0F3460),
      ),
      drawer: _buildDrawer(),
      body: _buildCasesContent(),
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
                    adminName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    adminEmail,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem('Dashboard', Icons.dashboard, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const adminDashboardPage.AdminDashboardPage(),
                ),
              );
            }),
            _buildDrawerItem('Manage Clients', Icons.people, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => manageClients.ManageClients(),
                ),
              );
            }),
            _buildDrawerItem('Manage Cases', Icons.library_books, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => manageCases.ManageCases(),
                ),
              );
            }),
            _buildDrawerItem('Notifications', Icons.notifications, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => notifications.NotificationPage()),
              );
            }),
            _buildDrawerItem('Chat', Icons.chat, () {
              // Add chat navigation logic
            }),
            _buildDrawerItem('Admin Profile', Icons.account_circle, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            }),
            _buildDrawerItem('Logout', Icons.logout, () {
              Navigator.pushReplacementNamed(context, '/');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController, // Use the controller here
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                      color: const Color.fromARGB(
                          255, 12, 60, 100)), // You can use your own color here
                ),
              ),
              onChanged: (query) {
                _filterCases(query); // Filter cases as user types
              },
            ),
          ),
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

  Widget _buildCasesContent() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSearchRow(),
        if (displayedCases.isNotEmpty)
          ...displayedCases.map((caseData) {
            return Card(
              color: Colors.white,
              elevation: 8.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              margin: const EdgeInsets.symmetric(vertical: 10.0),
              child: InkWell(
                onTap: () {
                  _showCaseDetails(caseData);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Case #${caseData['case_number']}',
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Status: ${caseData['case_status']}',
                        style: const TextStyle(
                          fontSize: 14.0,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.blue,
                          size: 24.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),

        // If no cases are found
        if (displayedCases.isEmpty)
          const Center(
            child: Text(
              "No cases available.",
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
      ],
    );
  }

  void _showCaseDetails(Map<String, dynamic> caseData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    Text(
                      "Case Details - #${caseData['case_number']}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    const TabBar(
                      labelColor: Colors.blue,
                      indicatorColor: Colors.blue,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(text: "Payments"),
                        Tab(text: "Attachments"),
                        Tab(text: "Sessions"),
                        Tab(text: "Complaints"),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildPaymentsTab(caseData),
                          _buildAttachmentsTab(caseData),
                          _buildSessionsTab(caseData),
                          _buildComplaintsTab(caseData),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentsTab(Map<String, dynamic> caseData) {
    // Retrieve the case_id from caseData
    final caseId = caseData['id'];

    // Check if case_id is null
    if (caseId == null) {
      return const Center(child: Text("Case ID is missing."));
    }
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchPaymentsForCase(
          caseId, token), // Fetch payments for the specific case
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text("No payments available for this case."));
        } else {
          final payments = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                "Payments for Case #${caseData['case_number']}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 16.0),
              ...payments.map((payment) {
                // Log the entire payment object to check if 'paymentDate' is present
                print('Payment object: $payment');

                String rawDate = payment['paymentDate'].toString();
                print('Raw payment date: $rawDate');

                String formattedDate = '';
                if (rawDate.isNotEmpty) {
                  try {
                    DateTime paymentDate =
                        DateTime.parse(rawDate); // Parsing ISO 8601 date format
                    formattedDate =
                        DateFormat('yyyy-MM-dd').format(paymentDate);
                    print('Formatted Date: $formattedDate');
                  } catch (e) {
                    print('Error parsing payment date: $rawDate');
                  }
                }

                // Format the amount
                double amount = payment['amount'] != null
                    ? double.tryParse(payment['amount'].toString()) ?? 0.0
                    : 0.0;
                String formattedAmount = '\$${amount.toStringAsFixed(2)}';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.payment,
                                  color: Colors.green, size: 24),
                              const SizedBox(width: 8.0),
                              Text(
                                "Payment of $formattedAmount",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  color: Colors.blue, size: 18),
                              const SizedBox(width: 8.0),
                              Text(
                                'Payment Date: $formattedDate',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Colors.orange,
                                size: 18,
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                "Status: ${payment['paymentStatus']}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        }
      },
    );
  }

  Widget _buildComplaintsTab(Map<String, dynamic> caseData) {
    // Retrieve the case_id from caseData
    final caseId = caseData['id'];

    // Check if case_id is null
    if (caseId == null) {
      return const Center(child: Text("Case ID is missing."));
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchComplaintsForCase(
          caseId, token), // Fetch complaints for the specific case
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text("No complaints available for this case."));
        } else {
          final complaints = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                "Complaints for Case #${caseData['case_number']}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 16.0),
              ...complaints.map((complaint) {
                // Log the entire complaint object to check if 'creationDate' is present
                print('Complaint object: $complaint');

                String rawDate = complaint['creationDate'].toString();
                print('Raw complaint date: $rawDate');

                String formattedDate = '';
                if (rawDate.isNotEmpty) {
                  try {
                    DateTime complaintDate =
                        DateTime.parse(rawDate); // Parsing ISO 8601 date format
                    formattedDate =
                        DateFormat('yyyy-MM-dd').format(complaintDate);
                    print('Formatted Date: $formattedDate');
                  } catch (e) {
                    print('Error parsing complaint date: $rawDate');
                  }
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.report_problem,
                                  color: Colors.red, size: 24),
                              const SizedBox(width: 8.0),
                              Text(
                                "Complaint Type: ${complaint['complaintType']}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            children: [
                              Icon(Icons.date_range,
                                  color: Colors.blue, size: 18),
                              const SizedBox(width: 8.0),
                              Text(
                                'Complaint Date: $formattedDate',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            "Details: ${complaint['complaintDetails']}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            children: [
                              Icon(Icons.account_circle,
                                  color: Colors.green, size: 18),
                              const SizedBox(width: 8.0),
                              Text(
                                "Complainant ID: ${complaint['id']}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            children: [
                              Icon(Icons.gavel, color: Colors.orange, size: 18),
                              const SizedBox(width: 8.0),
                              Text(
                                "Accused ID: ${complaint['accusedId']}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.purple, size: 18),
                              const SizedBox(width: 8.0),
                              Text(
                                "Status: ${complaint['complaintStatus']}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        }
      },
    );
  }

  Widget _buildAttachmentsTab(Map<String, dynamic> caseData) {
    // Retrieve the case_id from caseData
    final caseId = caseData['id'];

    // Check if case_id is null
    if (caseId == null) {
      return const Center(child: Text("Case ID is missing."));
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchAttachmentsForCase(
          caseId, token), // Fetch attachments for the specific case
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text("No attachments available for this case."));
        } else {
          final attachments = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                "Attachments for Case #${caseData['case_number']}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 16.0),
              ...attachments.map((attachment) {
                // Log the entire attachment object to check details
                print('Attachment object: $attachment');

                String fileName = attachment['filePath'] ?? 'Unknown';
                String fileType = attachment['fileType'] ?? 'Unknown';
                String uploadedBy =
                    'User ID: ${attachment['uploadedByUserId'] ?? 'N/A'}';
                String uploadTime = attachment['uploadTime'] ?? 'N/A';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.attach_file,
                                  color: Colors.blue, size: 24),
                              const SizedBox(width: 8.0),
                              Text(
                                "File: $fileName",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            children: [
                              Icon(Icons.description,
                                  color: Colors.green, size: 18),
                              const SizedBox(width: 8.0),
                              Text(
                                'File Type: $fileType',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  color: Colors.orange, size: 18),
                              const SizedBox(width: 8.0),
                              Text(
                                "Uploaded By: $uploadedBy",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  color: Colors.blue, size: 18),
                              const SizedBox(width: 8.0),
                              Text(
                                'Upload Time: $uploadTime',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        }
      },
    );
  }

  Widget _buildSessionsTab(Map<String, dynamic> caseData) {
    // Retrieve the case_id from caseData
    final caseId = caseData['id'];

    // Check if case_id is null
    if (caseId == null) {
      return const Center(child: Text("Case ID is missing."));
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchSessionsForCase(
          caseId, token), // Fetch sessions for the specific case
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text("No sessions available for this case."));
        } else {
          final sessions = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                "Sessions for Case #${caseData['case_number']}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 16.0),
              ...sessions.map((session) {
                // Log the entire session object to check details
                print('Session object: $session');

                String sessionDate = session['sessionDate'] ?? 'Unknown';
                String sessionDetails =
                    session['sessionDetails'] ?? 'No details available';
                String sessionStatus = session['sessionStatus'] ?? 'Unknown';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.blue),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  "Session Date: 2024-12-13T22:00:00.000Z",
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow
                                      .ellipsis, // Optional: truncates text if it overflows
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            children: [
                              Icon(Icons.details,
                                  color: Colors.green, size: 18),
                              const SizedBox(width: 8.0),
                              Text(
                                'Details: $sessionDetails',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.orange, size: 18),
                              const SizedBox(width: 8.0),
                              Text(
                                "Status: $sessionStatus",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        }
      },
    );
  }

  void _showDeleteConfirmationDialog(String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Text("Are you sure you want to delete this Case?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cancel action
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _deleteCase(userId); // Convert to String
                print("Case with ID $userId deleted.");
                Navigator.pop(context); // Close dialog
              },
              child: Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddCaseDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Case'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: caseTitleController,
                decoration: const InputDecoration(labelText: 'Case Title'),
              ),
              TextFormField(
                controller: caseDescriptionController,
                decoration:
                    const InputDecoration(labelText: 'Case Description'),
              ),
              TextFormField(
                controller: caseClientController,
                decoration: const InputDecoration(labelText: 'Client Name'),
              ),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedStatus = newValue!;
                  });
                },
                items: <String>['Open', 'Closed', 'Pending']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _addCase(
                  caseTitleController.text,
                  caseDescriptionController.text,
                  caseClientController.text,
                  selectedStatus,
                );
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addCase(
      String title, String description, String client, String status) async {
    setState(() {
      isLoading = true;
    });

    if (title.isEmpty ||
        description.isEmpty ||
        client.isEmpty ||
        status.isEmpty) {
      setState(() {
        fetchedData = 'Please fill in all required fields.';
      });
      setState(() {
        isLoading = false;
      });
      return;
    }

    var box = await Hive.openBox('userBox');
    String? token = box.get('token');

    if (token == null || token.isEmpty) {
      setState(() {
        fetchedData = 'No token provided. Please log in again.';
      });
      setState(() {
        isLoading = false;
      });
      return;
    }

    final response = await http.post(
      Uri.parse('http://10.0.2.2:4000/adminRoutes/create-case'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'title': title,
        'description': description,
        'client': client,
        'status': status,
      }),
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 201) {
      setState(() {
        fetchedData = 'Case added successfully!';
      });
    } else {
      setState(() {
        fetchedData = 'Error adding case: ${response.body}';
      });
    }
  }

  void _showUpdateCaseDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Case Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller:
                    caseIdToDeleteController, // For entering the case ID
                decoration: const InputDecoration(labelText: 'Case ID'),
              ),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedStatus = newValue!;
                  });
                },
                items: <String>['Open', 'Closed', 'Pending']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _updateCaseStatus(
                  caseIdToDeleteController.text,
                  selectedStatus,
                );
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateCaseStatus(String caseId, String status) async {
    setState(() {
      isLoading = true;
    });

    var box = await Hive.openBox('userBox');
    String? token = box.get('token');

    final response = await http.put(
      Uri.parse('http://10.0.2.2:4000/adminRoutes/update-case-status/$caseId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'status': status,
      }),
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      setState(() {
        fetchedData = 'Case status updated successfully!';
      });
    } else {
      setState(() {
        fetchedData = 'Error updating case: ${response.body}';
      });
    }
  }

  void _showDeleteCaseDialog() {
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Case'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter the Case ID to delete:'),
              TextFormField(
                controller: _controller,
                decoration: const InputDecoration(hintText: 'Enter Case ID'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                String caseId = _controller.text;
                if (caseId.isNotEmpty) {
                  _deleteCase(caseId);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid Case ID.')),
                  );
                }
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCase(String caseId) async {
    setState(() {
      isLoading = true;
    });

    var box = await Hive.openBox('userBox');
    String? token = box.get('token');

    final response = await http.delete(
      Uri.parse('http://10.0.2.2:4000/adminRoutes/delete-case/$caseId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      setState(() {
        fetchedData = 'Case deleted successfully!';
      });
    } else {
      setState(() {
        fetchedData = 'Error deleting case: ${response.body}';
      });
    }
  }
}

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
import 'package:firstproj/Pages/ChatPage.dart' as chat;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart'; // Import to check if running on web

const Color blueColor = Color(0xFF0F3460);
const Color backgroundColor = Colors.white;
const Color lightBlueColor = Color(0xFF0F3460);

class ManageCases extends StatefulWidget {
  ManageCases({Key? key}) : super(key: key);

  @override
  _ManageCasesState createState() => _ManageCasesState();
}

class _ManageCasesState extends State<ManageCases> {
  late String token = "";
  bool isLoading = false;
  String fetchedData = '';
  late Timer _timer;
  String adminName = 'Admin';
  String adminEmail = 'admin@example.com';
  String adminPicUrl = '';
  List<dynamic> filteredCases = [];
  TextEditingController _searchController = TextEditingController();
  List<dynamic> displayedCases = [];
  TextEditingController caseTitleController = TextEditingController();
  TextEditingController caseDescriptionController = TextEditingController();
  TextEditingController caseClientController = TextEditingController();
  TextEditingController caseStatusController = TextEditingController();
  TextEditingController caseIdToDeleteController = TextEditingController();
  String selectedStatus = 'Open';
  String errorMessage = '';
  List<dynamic> cases = [];
  List<dynamic> selectedNotification = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
      Navigator.pushReplacementNamed(context, '/');
    } else {
      setState(() {
        token = tokenFromBox;
      });
    }
  }

  Future<Map<String, dynamic>> fetchAdminData(String token) async {
    final admindata = kIsWeb
        ? 'http://192.168.88.4:4000/adminRoutes/get-my-info'
        : 'http://10.0.2.2:4000/adminRoutes/get-my-info';

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
      return json.decode(response.body);
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

      final data = await fetchAdminData(token);
      setState(() {
        isLoading = false;
        adminName = data['user']['username'] ?? 'Admin';
        adminEmail = data['user']['email'] ?? 'admin@example.com';
        adminPicUrl = data['user']['profilePic'] ?? '';
        adminPicUrl = _constructImageUrl(adminPicUrl);
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        fetchedData = 'Error fetching admin data: $e';
      });
    }
  }

  String _constructImageUrl(String? relativePath) {
    if (relativePath != null) {
      final String baseUrl;
      if (kIsWeb) {
        baseUrl = 'http://192.168.88.4:4000';
      } else {
        baseUrl = 'http://10.0.2.2:4000';
      }
      return '$baseUrl/$relativePath';
    } else {
      return '';
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

      final List<dynamic> data = await fetchCases(token);

      setState(() {
        cases = data;
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
    final casedata = kIsWeb
        ? 'http://192.168.88.4:4000/adminRoutes/viewAll-cases'
        : 'http://10.0.2.2:4000/adminRoutes/viewAll-cases';

    print("casedata is $casedata");

    final response = await http.get(
      Uri.parse(casedata),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
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
    final attdata = kIsWeb
        ? 'http://192.168.88.4:4000/adminRoutes/get-attachment'
        : 'http://10.0.2.2:4000/adminRoutes/get-attachment';

    print("attdata is $attdata");

    final response = await http.post(
      Uri.parse(attdata),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'case_id': caseId,
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
    final compdata = kIsWeb
        ? 'http://192.168.88.4:4000/adminRoutes/get-complaint'
        : 'http://10.0.2.2:4000/adminRoutes/get-complaint';

    print("compdata is $compdata");

    final response = await http.post(
      Uri.parse(compdata),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'case_id': caseId,
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
    final sessdata = kIsWeb
        ? 'http://192.168.88.4:4000/adminRoutes/get-sessions'
        : 'http://10.0.2.2:4000/adminRoutes/get-sessions';

    print("sessdata is $sessdata");

    final response = await http.post(
      Uri.parse(sessdata),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'case_id': caseId,
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
    final paydata = kIsWeb
        ? 'http://192.168.88.4:4000/adminRoutes/get-payments'
        : 'http://10.0.2.2:4000/adminRoutes/get-payments';

    print("paydata is $paydata");

    final response = await http.post(
      Uri.parse(paydata),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'case_id': caseId,
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
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text(
          'Manage Cases',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Color.fromARGB(255, 1, 25, 65),
        leading: MediaQuery.of(context).size.width <= 600
            ? IconButton(
                icon: Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              )
            : null,
      ),
      drawer: MediaQuery.of(context).size.width <= 600 ? _buildDrawer() : null,
      body: Row(children: [
        if (MediaQuery.of(context).size.width > 600) _buildPermanentDrawer(),
        Expanded(
          child: _buildCasesContent(),
        ),
      ]),
    );
  }

  Widget _buildPermanentDrawer() {
    return Container(
      width: 250, // Set the width of the permanent drawer
      color: Color(0xFF0F3460),
      child: _buildDrawer(),
    );
  }

  Widget _buildDrawer() {
    return Container(
      color: Color.fromARGB(255, 1, 25, 65),
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 1, 25, 65),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      adminPicUrl.isNotEmpty ? NetworkImage(adminPicUrl) : null,
                  child: adminPicUrl.isEmpty
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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => chat.ChatPage()),
            );
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
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      BorderSide(color: const Color.fromARGB(255, 12, 60, 100)),
                ),
              ),
              onChanged: (query) {
                _filterCases(query);
              },
            ),
          ),
          if (MediaQuery.of(context).size.width > 600) ...[
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
                // Navigator.pushReplacement(
                //   context,
                //   MaterialPageRoute(builder: (context) => chat.ChatPage()),
                // );
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
          ]
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
              margin: EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal:
                      MediaQuery.of(context).size.width > 600 ? 20.0 : 0.0),
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
    showDialog(
      context: context,
      barrierDismissible: true, // Optional: Dismiss dialog when tapped outside
      builder: (BuildContext context) {
        return Center(
          // Center the dialog on the screen
          child: Dialog(
            insetPadding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width > 600
                    ? 60
                    : 16), // Add horizontal padding to center the content
            elevation: 8.0, // Add elevation
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(12.0)), // Add rounded corners
            child: Container(
              width: MediaQuery.of(context).size.width *
                  (MediaQuery.of(context).size.width > 600 ? 0.7 : 1),
              padding: const EdgeInsets.all(16.0),
              child: DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    Text(
                      "Case Details - #${caseData['case_number']}",
                      style: const TextStyle(
                          fontSize: 22, // Increased font size for title
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 16.0),
                    TabBar(
                      labelColor: Colors.blue, // set label color to blue
                      indicatorColor: Colors
                          .blue, // set selected tab indicator color to blue
                      unselectedLabelColor:
                          Colors.grey, // set unselected label color to grey
                      tabs: const [
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
            ),
          ),
        );
      },
    );
  }
  // void _showCaseDetails(Map<String, dynamic> caseData) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     builder: (BuildContext context) {
  //       return DraggableScrollableSheet(
  //         expand: false,
  //         builder: (context, scrollController) {
  //           return Container(
  //             padding: EdgeInsets.all(16.0),
  //             width: MediaQuery.of(context).size.width *
  //                 (MediaQuery.of(context).size.width > 600 ? 0.7 : 1),
  //             child: DefaultTabController(
  //               length: 4,
  //               child: Column(
  //                 children: [
  //                   Text(
  //                     "Case Details - #${caseData['case_number']}",
  //                     style: const TextStyle(
  //                       fontSize: 18,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                   const SizedBox(height: 16.0),
  //                   const TabBar(
  //                     labelColor: Colors.blue,
  //                     indicatorColor: Colors.blue,
  //                     unselectedLabelColor: Colors.grey,
  //                     tabs: [
  //                       Tab(text: "Payments"),
  //                       Tab(text: "Attachments"),
  //                       Tab(text: "Sessions"),
  //                       Tab(text: "Complaints"),
  //                     ],
  //                   ),
  //                   Expanded(
  //                     child: TabBarView(
  //                       children: [
  //                         _buildPaymentsTab(caseData),
  //                         _buildAttachmentsTab(caseData),
  //                         _buildSessionsTab(caseData),
  //                         _buildComplaintsTab(caseData),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  Widget _buildPaymentsTab(Map<String, dynamic> caseData) {
    final caseId = caseData['id'];
    if (caseId == null) {
      return const Center(child: Text("Case ID is missing."));
    }
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchPaymentsForCase(caseId, token),
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
                String rawDate = payment['paymentDate'].toString();
                String formattedDate = '';
                if (rawDate.isNotEmpty) {
                  try {
                    DateTime paymentDate =
                        DateTime.parse(rawDate); // Parsing ISO 8601 date format
                    formattedDate =
                        DateFormat('yyyy-MM-dd').format(paymentDate);
                  } catch (e) {
                    print('Error parsing payment date: $rawDate');
                  }
                }
                double amount = payment['amount'] != null
                    ? double.tryParse(payment['amount'].toString()) ?? 0.0
                    : 0.0;
                String formattedAmount = '\$${amount.toStringAsFixed(2)}';

                return Card(
                  elevation: 4.0,
                  margin: EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal:
                          MediaQuery.of(context).size.width > 600 ? 40.0 : 0.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(Icons.payment,
                            "Payment of $formattedAmount", Colors.green),
                        const SizedBox(height: 8.0),
                        _buildDetailRow(Icons.calendar_today,
                            'Payment Date: $formattedDate', Colors.blue),
                        const SizedBox(height: 8.0),
                        _buildDetailRow(
                            Icons.access_time,
                            "Status: ${payment['paymentStatus']}",
                            Colors.orange),
                      ],
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
    final caseId = caseData['id'];
    if (caseId == null) {
      return const Center(child: Text("Case ID is missing."));
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchComplaintsForCase(caseId, token),
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
                String rawDate = complaint['creationDate'].toString();
                String formattedDate = '';
                if (rawDate.isNotEmpty) {
                  try {
                    DateTime complaintDate =
                        DateTime.parse(rawDate); // Parsing ISO 8601 date format
                    formattedDate =
                        DateFormat('yyyy-MM-dd').format(complaintDate);
                  } catch (e) {
                    print('Error parsing payment date: $rawDate');
                  }
                }
                return Card(
                  elevation: 4.0,
                  margin: EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal:
                          MediaQuery.of(context).size.width > 600 ? 40.0 : 0.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                            Icons.report_problem,
                            "Complaint Type: ${complaint['complaintType']}",
                            Colors.red),
                        const SizedBox(height: 8.0),
                        _buildDetailRow(Icons.date_range,
                            'Complaint Date: $formattedDate', Colors.blue),
                        const SizedBox(height: 8.0),
                        _buildDetailRow(
                            Icons.description,
                            "Details: ${complaint['complaintDetails']}",
                            Colors.black),
                        const SizedBox(height: 8.0),
                        _buildDetailRow(Icons.account_circle,
                            "Complainant ID: ${complaint['id']}", Colors.green),
                        const SizedBox(height: 8.0),
                        _buildDetailRow(
                            Icons.gavel,
                            "Accused ID: ${complaint['accusedId']}",
                            Colors.orange),
                        const SizedBox(height: 8.0),
                        _buildDetailRow(
                            Icons.info_outline,
                            "Status: ${complaint['complaintStatus']}",
                            Colors.purple),
                      ],
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
    final caseId = caseData['id'];
    if (caseId == null) {
      return const Center(child: Text("Case ID is missing."));
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchAttachmentsForCase(caseId, token),
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
                String fileName = attachment['filePath'] ?? 'Unknown';
                String fileType = attachment['fileType'] ?? 'Unknown';
                String uploadedBy =
                    'User ID: ${attachment['uploadedByUserId'] ?? 'N/A'}';
                String uploadTime = attachment['uploadTime'] ?? 'N/A';
                return Card(
                  elevation: 4.0,
                  margin: EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal:
                          MediaQuery.of(context).size.width > 600 ? 40.0 : 0.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                            Icons.attach_file, "File: $fileName", Colors.blue),
                        const SizedBox(height: 8.0),
                        _buildDetailRow(Icons.description,
                            'File Type: $fileType', Colors.green),
                        const SizedBox(height: 8.0),
                        _buildDetailRow(Icons.access_time,
                            "Uploaded By: $uploadedBy", Colors.orange),
                        const SizedBox(height: 8.0),
                        _buildDetailRow(Icons.calendar_today,
                            'Upload Time: $uploadTime', Colors.blue),
                      ],
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
    final caseId = caseData['id'];
    if (caseId == null) {
      return const Center(child: Text("Case ID is missing."));
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchSessionsForCase(caseId, token),
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
                String sessionDate = session['sessionDate'] ?? 'Unknown';
                String sessionDetails =
                    session['sessionDetails'] ?? 'No details available';
                String sessionStatus = session['sessionStatus'] ?? 'Unknown';
                return Card(
                  elevation: 4.0,
                  margin: EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal:
                          MediaQuery.of(context).size.width > 600 ? 40.0 : 0.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                            Icons.calendar_today,
                            "Session Date: 2024-12-13T22:00:00.000Z",
                            Colors.blue),
                        const SizedBox(height: 8.0),
                        _buildDetailRow(Icons.details,
                            'Details: $sessionDetails', Colors.green),
                        const SizedBox(height: 8.0),
                        _buildDetailRow(Icons.info, "Status: $sessionStatus",
                            Colors.orange),
                      ],
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

  Widget _buildDetailRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
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
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _deleteCase(userId);
                print("Case with ID $userId deleted.");
                Navigator.pop(context);
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
        if (ScaffoldMessenger.of(context).mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please fill in all required fields.')),
          );
        }
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
        if (ScaffoldMessenger.of(context).mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No token provided. Please log in again.')),
          );
        }
      });
      setState(() {
        isLoading = false;
      });
      return;
    }
    final crecase = kIsWeb
        ? 'http://192.168.88.4:4000/adminRoutes/create-case'
        : 'http://10.0.2.2:4000/adminRoutes/create-case';

    print("crecase is $crecase");

    final response = await http.post(
      Uri.parse(crecase),
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
        if (ScaffoldMessenger.of(context).mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Case added successfully!')),
          );
        }
      });
    } else {
      setState(() {
        if (ScaffoldMessenger.of(context).mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error adding case!!')),
          );
        }
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
    final updcase = kIsWeb
        ? 'http://192.168.88.4:4000/adminRoutes/update-case-status/$caseId'
        : 'http://10.0.2.2:4000/adminRoutes/update-case-status/$caseId';

    print("updcase is $updcase");

    final response = await http.put(
      Uri.parse(updcase),
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
        if (ScaffoldMessenger.of(context).mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Case status updated successfully!')),
          );
        }
      });
    } else {
      setState(() {
        if (ScaffoldMessenger.of(context).mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error updating case!')),
          );
        }
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
    final delecase = kIsWeb
        ? 'http://192.168.88.4:4000/adminRoutes/delete-case/$caseId'
        : 'http://10.0.2.2:4000/adminRoutes/delete-case/$caseId';

    print("delecase is $delecase");

    final response = await http.delete(
      Uri.parse(delecase),
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
        if (ScaffoldMessenger.of(context).mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Case deleted successfully!')),
          );
        }
      });
    } else {
      setState(() {
        fetchedData = 'Error deleting case: ${response.body}';
        if (ScaffoldMessenger.of(context).mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error deleting case!!')),
          );
        }
      });
    }
  }
}

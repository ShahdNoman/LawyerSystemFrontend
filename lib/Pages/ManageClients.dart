import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:firstproj/Pages/ProfilePage.dart';
import 'package:firstproj/Pages/TokenUtils.dart';
import 'package:firstproj/Pages/AdminDashboardPage.dart' as adminDashboardPage;
import 'package:firstproj/Pages/ManageClients.dart' as manageClients;
import 'package:firstproj/Pages/ManageCases.dart' as manageCases;
import 'package:firstproj/Pages/Reports.dart' as reports;
import 'package:firstproj/Pages/Billing.dart' as billing;
import 'package:firstproj/Pages/Notifications.dart' as notifications;
import 'package:firstproj/Pages/ChatPage.dart' as chat;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/foundation.dart'; // Import to check if running on web

const Color blueColor = Color(0xFF0F3460);
const Color backgroundColor = Colors.white;
const Color lightBlueColor = Color(0xFFADD8E6);

class ManageClients extends StatefulWidget {
  @override
  _ManageClientsState createState() => _ManageClientsState();
}

class _ManageClientsState extends State<ManageClients> {
  bool isLoading = true;
  String fetchedData = '';
  late Timer _timer;
  List<dynamic> filteredUsers = [];
  List<dynamic> users = [];
  String adminName = 'Admin'; // Default name
  String adminEmail = 'admin@example.com'; // Default email
  String adminPicUrl = ''; // To store the profile picture URL

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      TokenUtils.checkTokenExpiration(context);
    });
    _fetchAdminData();
    _fetchUsers();
    _searchController.addListener(() {
      _onSearchChanged();
    });
    // Apply filter as user types
  }

  void _onSearchChanged() {
    String searchTerm = _searchController.text.toLowerCase();

    setState(() {
      filteredUsers = users.where((user) {
        return (user['email']?.toLowerCase().contains(searchTerm) ?? false) ||
            (user['phone_number']?.toLowerCase().contains(searchTerm) ??
                false) ||
            (user['full_name']?.toLowerCase().contains(searchTerm) ?? false) ||
            (user['membership_number']?.toLowerCase().contains(searchTerm) ??
                false) ||
            (user['judge_number']?.toLowerCase().contains(searchTerm) ??
                false) ||
            (user['id_number']?.toLowerCase().contains(searchTerm) ?? false) ||
            (user['registration_date']?.toLowerCase().contains(searchTerm) ??
                false) ||
            (user['bio']?.toLowerCase().contains(searchTerm) ?? false);
      }).toList();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  TextEditingController clientNameController = TextEditingController();
  TextEditingController clientEmailController = TextEditingController();
  TextEditingController clientRoleController = TextEditingController();
  TextEditingController clientPhoneNumberController = TextEditingController();
  TextEditingController clientFullNameController = TextEditingController();
  TextEditingController clientMembershipNumberController =
      TextEditingController();
  TextEditingController clientUsernameController = TextEditingController();
  TextEditingController clientIdToDeleteController = TextEditingController();
  TextEditingController clientJudgeNumberController = TextEditingController();
  TextEditingController clientIdNumberController = TextEditingController();
  TextEditingController clientStatusController = TextEditingController();
  TextEditingController clientPasswordController = TextEditingController();
  TextEditingController _searchController = TextEditingController();
  String selectedStatus = 'Active'; // Declare selectedStatus here
  bool _isHovered = false;

  Future<Map<String, dynamic>> fetchAdminData(String token) async {
    final admindata = kIsWeb
        ? 'http://192.168.88.11:4000/adminRoutes/get-my-info' // For Web (Chrome)
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
        adminPicUrl = _constructImageUrl(adminPicUrl);
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        fetchedData = 'Error fetching admin data: $e';
      });
    }
  }

  String errorMessage = '';
  Future<void> _fetchUsers() async {
    try {
      var box = await Hive.openBox('userBox');
      final token = box.get('token');

      if (token == null || token.isEmpty) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      final List<dynamic> data = await fetchUsers(token);

      setState(() {
        users = data; // Store the fetched users
        filteredUsers = List.from(users); // Initially show all users
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching users: $e';
      });
      print('Error: $e');
    }
  }

  Future<List<dynamic>> fetchUsers(String token) async {
    final userdata = kIsWeb
        ? 'http://192.168.88.11:4000/adminRoutes/viewAll-users' // For Web (Chrome)
        : 'http://10.0.2.2:4000/adminRoutes/viewAll-users'; // For Android Emulator

    print("userdata is $userdata");

    final response = await http.get(
      Uri.parse(userdata),
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
    } else {
      throw Exception(
          'Failed to load admin data. Status Code: ${response.statusCode}');
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredUsers = users.where((user) {
        return user.values
            .any((value) => value.toString().toLowerCase().contains(query));
      }).toList();
    });
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text(
  //         'Manage Clients',
  //         style: TextStyle(color: Colors.white, fontSize: 18),
  //       ),
  //       backgroundColor: Color(0xFF0F3460),
  //     ),
  //     drawer: _buildDrawer(),
  //     body: _buildClientContent(),
  //   );
  // }

  // Widget _buildDrawer() {
  //   return Drawer(
  //     child: Container(
  //       color: Color(0xFF0F3460),
  //       child: ListView(
  //         children: [
  //           DrawerHeader(
  //             decoration: BoxDecoration(
  //               color: Color(0xFFADD8E6),
  //             ),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 CircleAvatar(
  //                   radius: 35,
  //                   backgroundColor: Colors.white,
  //                   backgroundImage: adminPicUrl.isNotEmpty
  //                       ? NetworkImage(adminPicUrl) // Use fetched image URL
  //                       : null, // If no image URL, fallback to default icon
  //                   child: adminPicUrl
  //                           .isEmpty // Fallback to default icon if no image
  //                       ? Icon(
  //                           Icons.person,
  //                           size: 50,
  //                           color: Color(0xFF0F3460),
  //                         )
  //                       : null,
  //                 ),
  //                 const SizedBox(height: 10),
  //                 Text(
  //                   adminName,
  //                   style: TextStyle(
  //                     color: Colors.white,
  //                     fontSize: 20,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //                 Text(
  //                   adminEmail,
  //                   style: TextStyle(
  //                     color: Colors.white70,
  //                     fontSize: 14,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           _buildDrawerItem('Dashboard', Icons.dashboard, () {
  //             Navigator.pushReplacement(
  //               context,
  //               MaterialPageRoute(
  //                 builder: (context) =>
  //                     const adminDashboardPage.AdminDashboardPage(),
  //               ),
  //             );
  //           }),
  //           _buildDrawerItem('Manage Clients', Icons.people, () {
  //             Navigator.pushReplacement(
  //               context,
  //               MaterialPageRoute(
  //                 builder: (context) => manageClients.ManageClients(),
  //               ),
  //             );
  //           }),
  //           _buildDrawerItem('Manage Cases', Icons.library_books, () {
  //             Navigator.pushReplacement(
  //               context,
  //               MaterialPageRoute(
  //                 builder: (context) => manageCases.ManageCases(),
  //               ),
  //             );
  //           }),
  //           _buildDrawerItem('Notifications', Icons.notifications, () {
  //             Navigator.pushReplacement(
  //               context,
  //               MaterialPageRoute(
  //                   builder: (context) => notifications.NotificationPage()),
  //             );
  //           }),
  //           _buildDrawerItem('Chat', Icons.chat, () {
  //             Navigator.pushReplacement(
  //               context,
  //               MaterialPageRoute(builder: (context) => chat.ChatPage()),
  //             );
  //           }),
  //           _buildDrawerItem('Admin Profile', Icons.account_circle, () {
  //             Navigator.pushReplacement(
  //               context,
  //               MaterialPageRoute(builder: (context) => ProfilePage()),
  //             );
  //           }),
  //           _buildDrawerItem('Logout', Icons.logout, () {
  //             Navigator.pushReplacementNamed(context, '/');
  //           }),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildDrawerItem(String title, IconData icon, VoidCallback onTap) {
  //   return ListTile(
  //     leading: Icon(icon, color: Colors.white),
  //     title: Text(title, style: TextStyle(color: Colors.white)),
  //     onTap: onTap,
  //   );
  // }

  // void _showChatDialog(Map<String, dynamic> user) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text("Chat with ${user['username']}"),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Text("Start a conversation with ${user['username']}."),
  //             SizedBox(height: 10),
  //             TextField(
  //               decoration: InputDecoration(
  //                 labelText: "Enter your message",
  //                 border: OutlineInputBorder(),
  //               ),
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(context); // Close the dialog
  //             },
  //             child: Text("Cancel"),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               // Handle sending the message
  //               print("Message sent to ${user['username']}");
  //               Navigator.pop(context);
  //             },
  //             child: Text("Send"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // void _showUserDetailsDialog(Map<String, dynamic> user) {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: Column(
  //           children: [
  //             // Profile picture with active status
  //             Stack(
  //               children: [
  //                 CircleAvatar(
  //                   radius: 40,
  //                   backgroundImage:
  //                       _constructImageUrl(user['profile_picture']) != null
  //                           ? NetworkImage(
  //                               _constructImageUrl(user['profile_picture']))
  //                           : AssetImage('assets/images/default-profile.png')
  //                               as ImageProvider,
  //                 ),
  //                 Positioned(
  //                   top: 0,
  //                   right: 0,
  //                   child: Container(
  //                     width: 12,
  //                     height: 12,
  //                     decoration: BoxDecoration(
  //                       color: user['status'] == 'Active'
  //                           ? Colors.green
  //                           : Colors.grey,
  //                       shape: BoxShape.circle,
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             SizedBox(height: 8),
  //             Text(
  //               user['username'] ?? 'User Details',
  //               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
  //             ),
  //             Text(user['role'] ?? 'N/A'),
  //           ],
  //         ),
  //         content: SingleChildScrollView(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               _buildDetailRow('Email:', user['email'] ?? 'N/A', Icons.email),
  //               _buildDetailRow(
  //                   'Phone:', user['phone_number'] ?? 'N/A', Icons.phone),
  //               _buildDetailRow(
  //                   'Full Name:', user['full_name'] ?? 'N/A', Icons.person),
  //               _buildDetailRow('Membership Number:',
  //                   user['membership_number'] ?? 'N/A', Icons.card_membership),
  //               _buildDetailRow('Judge Number:', user['judge_number'] ?? 'N/A',
  //                   Icons.gavel),
  //               _buildDetailRow('ID Number:', user['id_number'] ?? 'N/A',
  //                   Icons.perm_identity),
  //               _buildDetailRow('Registration Date:',
  //                   user['registration_date'] ?? 'N/A', Icons.date_range),
  //               _buildDetailRow('Bio:', user['bio'] ?? 'N/A', Icons.info),
  //             ],
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: Text("Close"),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(context); // Close dialog before initiating chat
  //               _showChatDialog(user); // Initiates chat
  //             },
  //             child: Text(
  //               "Chat",
  //               style: TextStyle(color: Colors.blue),
  //             ),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(
  //                   context); // Close dialog before delete confirmation
  //               _showDeleteConfirmationDialog(
  //                   user['id'].toString()); // Delete confirmation
  //             },
  //             child: Text(
  //               "Delete",
  //               style: TextStyle(color: Colors.red),
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // void _showDeleteConfirmationDialog(String userId) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text("Confirm Delete"),
  //         content: Text("Are you sure you want to delete this user?"),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(context); // Cancel action
  //             },
  //             child: Text("Cancel"),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               _deleteClient(userId); // Convert to String
  //               print("User with ID $userId deleted.");
  //               Navigator.pop(context); // Close dialog
  //             },
  //             child: Text(
  //               "Delete",
  //               style: TextStyle(color: Colors.red),
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // Widget _buildDetailRow(String label, String value, IconData icon) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 8.0),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Icon(icon, color: Colors.blue, size: 20), // Icon for each detail
  //         SizedBox(width: 8.0), // Space between icon and text
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(label,
  //                   style: TextStyle(
  //                       fontWeight: FontWeight.bold, color: Colors.black54)),
  //               SizedBox(height: 4.0),
  //               Text(value, style: TextStyle(color: Colors.black)),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildClientContent() {
  //   return Container(
  //     color: backgroundColor,
  //     child: Column(
  //       children: [
  //         _buildSearchRow(), // Add the search bar at the top
  //         // Show a loading indicator if the data is being fetched
  //         if (isLoading) const Center(child: CircularProgressIndicator()),
  //         // Display the user list or a "no clients" message
  //         Expanded(
  //           child: isLoading
  //               ? const Center(
  //                   child:
  //                       CircularProgressIndicator()) // Show loading if still fetching
  //               : users.isEmpty
  //                   ? const Center(
  //                       child:
  //                           Text("No clients available.")) // No clients found
  //                   : _buildManageClientsForm(), // Build the user list if data is available
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildSearchRow() {
  //   return Padding(
  //     padding: const EdgeInsets.all(8.0),
  //     child: Row(
  //       children: [
  //         Expanded(
  //           child: TextField(
  //             controller: _searchController, // Attach the controller
  //             onChanged: (value) {
  //               // Trigger search logic on text change
  //               _onSearchChanged();
  //             },
  //             decoration: InputDecoration(
  //               hintText: 'Search...',
  //               prefixIcon: Icon(Icons.search),
  //               border: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(30),
  //                 borderSide: BorderSide(color: lightBlueColor),
  //               ),
  //             ),
  //           ),
  //         ),
  //         IconButton(
  //           icon: Icon(Icons.notifications, color: blueColor),
  //           onPressed: () {
  //             Navigator.pushReplacement(
  //               context,
  //               MaterialPageRoute(
  //                   builder: (context) => notifications.NotificationPage()),
  //             );
  //           },
  //         ),
  //         IconButton(
  //           icon: Icon(Icons.chat, color: blueColor),
  //           onPressed: () {
  //             Navigator.pushReplacement(
  //               context,
  //               MaterialPageRoute(builder: (context) => chat.ChatPage()),
  //             );
  //           },
  //         ),
  //         IconButton(
  //           icon: Icon(Icons.account_circle, color: blueColor),
  //           onPressed: () {
  //             Navigator.pushReplacement(
  //               context,
  //               MaterialPageRoute(builder: (context) => ProfilePage()),
  //             );
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildManageClientsForm() {
  //   return SingleChildScrollView(
  //     child: Column(
  //       children: [
  //         SizedBox(
  //           height: 16.0, // Space between the button and the list of users
  //         ),
  //         Card(
  //           elevation: 4.0,
  //           margin: const EdgeInsets.symmetric(
  //               horizontal: 16.0), // Add horizontal padding
  //           shape: RoundedRectangleBorder(
  //             borderRadius:
  //                 BorderRadius.circular(12.0), // Smooth rounded corners
  //           ),
  //           child: Padding(
  //             padding: const EdgeInsets.all(8.0),
  //             child: Row(
  //               mainAxisAlignment:
  //                   MainAxisAlignment.spaceBetween, // Aligns items neatly
  //               children: [
  //                 Text(
  //                   "Manage Admins",
  //                   style: TextStyle(
  //                     fontSize: 16.0,
  //                     fontWeight: FontWeight.bold,
  //                     color: Colors.black87,
  //                   ),
  //                 ),
  //                 GestureDetector(
  //                   onTap: () {
  //                     _showAddClientDialog(); // Show the dialog when the button is tapped
  //                   },
  //                   child: MouseRegion(
  //                     onEnter: (_) {
  //                       setState(() {
  //                         _isHovered = true; // Show text when hovering
  //                       });
  //                     },
  //                     onExit: (_) {
  //                       setState(() {
  //                         _isHovered = false; // Hide text when not hovering
  //                       });
  //                     },
  //                     child: AnimatedContainer(
  //                       duration: const Duration(
  //                           milliseconds: 200), // Smooth animation
  //                       padding: const EdgeInsets.symmetric(
  //                           vertical: 8.0,
  //                           horizontal: 12.0), // Comfortable padding
  //                       decoration: BoxDecoration(
  //                         color: Colors.green, // Vibrant green background
  //                         borderRadius:
  //                             BorderRadius.circular(12), // More rounded corners
  //                         boxShadow: [
  //                           BoxShadow(
  //                             color:
  //                                 Colors.black.withOpacity(0.1), // Soft shadow
  //                             blurRadius: 6, // Smooth blur
  //                             offset: Offset(
  //                                 0, 4), // Downward offset for natural shadow
  //                           ),
  //                         ],
  //                       ),
  //                       child: Row(
  //                         mainAxisSize:
  //                             MainAxisSize.min, // Minimize size to fit content
  //                         children: [
  //                           Icon(
  //                             Icons.add,
  //                             color: Colors.white,
  //                             size: 20.0, // Subtle reduction in icon size
  //                           ),
  //                           SizedBox(width: 8.0), // Space between icon and text
  //                           AnimatedOpacity(
  //                             opacity: _isHovered
  //                                 ? 1.0
  //                                 : 0.0, // Show text only when hovered
  //                             duration:
  //                                 Duration(milliseconds: 200), // Smooth fade
  //                             child: Text(
  //                               'Add Admin',
  //                               style: TextStyle(
  //                                 fontSize:
  //                                     14.0, // Adjusted font size for readability
  //                                 color: Colors.white,
  //                                 fontWeight: FontWeight.w600, // Slightly bold
  //                               ),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //         isLoading
  //             ? const Center(child: CircularProgressIndicator())
  //             : errorMessage.isNotEmpty
  //                 ? Center(child: Text(errorMessage)) // Display error message
  //                 : (filteredUsers.isEmpty && users.isEmpty)
  //                     ? const Center(child: Text("No users found."))
  //                     : Container(
  //                         height:
  //                             650, // Set a fixed height for the list to ensure scrolling
  //                         child: ListView.builder(
  //                           shrinkWrap: true,
  //                           physics: AlwaysScrollableScrollPhysics(),
  //                           itemCount: filteredUsers.isNotEmpty
  //                               ? filteredUsers.length
  //                               : users
  //                                   .length, // Use filtered users if available
  //                           itemBuilder: (context, index) {
  //                             final user = filteredUsers.isNotEmpty
  //                                 ? filteredUsers[index]
  //                                 : users[index]; // Choose the appropriate list
  //                             return GestureDetector(
  //                               onTap: () => _showUserDetailsDialog(user),
  //                               child: Card(
  //                                 margin: EdgeInsets.all(10),
  //                                 child: ListTile(
  //                                   leading: Stack(
  //                                     alignment: Alignment
  //                                         .topRight, // Align the status circle at the top right
  //                                     children: [
  //                                       // User's profile picture
  //                                       CircleAvatar(
  //                                         radius: 30, // Profile picture size
  //                                         backgroundImage: _constructImageUrl(
  //                                                     user[
  //                                                         'profile_picture']) !=
  //                                                 null
  //                                             ? NetworkImage(_constructImageUrl(
  //                                                 user[
  //                                                     'profile_picture'])) // For network images
  //                                             : AssetImage(
  //                                                     'assets/images/default-profile.png')
  //                                                 as ImageProvider, // For local assets
  //                                       ),
  //                                       // Active status circle at the top-right of the profile picture
  //                                       Positioned(
  //                                         top:
  //                                             0, // Position the status circle at the top
  //                                         right: 0, // Position it on the right
  //                                         child: Container(
  //                                           width:
  //                                               12, // Size of the status circle
  //                                           height: 12,
  //                                           decoration: BoxDecoration(
  //                                             color: user['status'] == 'Active'
  //                                                 ? Colors.green
  //                                                 : Colors.grey,
  //                                             shape: BoxShape.circle,
  //                                           ),
  //                                         ),
  //                                       ),
  //                                     ],
  //                                   ),
  //                                   title: Text(user['username'] ?? 'Unknown'),
  //                                   subtitle: Text(user['role'] ?? 'N/A'),
  //                                   trailing: Row(
  //                                     mainAxisSize: MainAxisSize.min,
  //                                     children: [
  //                                       ElevatedButton(
  //                                         onPressed: () {
  //                                           _showChatDialog(
  //                                               user); // Open Chat dialog
  //                                         },
  //                                         style: ElevatedButton.styleFrom(
  //                                           backgroundColor: Colors
  //                                               .blue, // Customize button color
  //                                           shape: RoundedRectangleBorder(
  //                                             borderRadius:
  //                                                 BorderRadius.circular(4),
  //                                           ),
  //                                           padding: EdgeInsets.symmetric(
  //                                               horizontal: 8,
  //                                               vertical: 4), // Smaller padding
  //                                         ),
  //                                         child: Row(
  //                                           mainAxisSize: MainAxisSize.min,
  //                                           children: [
  //                                             Icon(Icons.chat,
  //                                                 size: 12,
  //                                                 color: Colors
  //                                                     .white), // Very small chat icon
  //                                             SizedBox(
  //                                                 width:
  //                                                     2), // Minimal spacing between icon and text
  //                                             Text(
  //                                               "Chat",
  //                                               style: TextStyle(
  //                                                   fontSize: 10,
  //                                                   color: Colors
  //                                                       .white), // Smaller text
  //                                             ),
  //                                           ],
  //                                         ),
  //                                       ),
  //                                       SizedBox(
  //                                           width:
  //                                               6), // Smaller spacing between buttons
  //                                       ElevatedButton(
  //                                         onPressed: () {
  //                                           _showDeleteConfirmationDialog(user[
  //                                                   'id']
  //                                               .toString()); // Confirm Delete
  //                                         },
  //                                         style: ElevatedButton.styleFrom(
  //                                           backgroundColor: Colors
  //                                               .red, // Customize delete button color
  //                                           shape: RoundedRectangleBorder(
  //                                             borderRadius:
  //                                                 BorderRadius.circular(4),
  //                                           ),
  //                                           padding: EdgeInsets.symmetric(
  //                                               horizontal: 8,
  //                                               vertical: 4), // Smaller padding
  //                                         ),
  //                                         child: Row(
  //                                           mainAxisSize: MainAxisSize.min,
  //                                           children: [
  //                                             Icon(Icons.delete,
  //                                                 size: 12,
  //                                                 color: Colors
  //                                                     .white), // Very small delete icon
  //                                             SizedBox(
  //                                                 width:
  //                                                     2), // Minimal spacing between icon and text
  //                                             Text(
  //                                               "Delete",
  //                                               style: TextStyle(
  //                                                   fontSize: 10,
  //                                                   color: Colors
  //                                                       .white), // Smaller text
  //                                             ),
  //                                           ],
  //                                         ),
  //                                       ),
  //                                     ],
  //                                   ),
  //                                 ),
  //                               ),
  //                             );
  //                           },
  //                         ),
  //                       ),
  //       ],
  //     ),
  //   );
  // }

  // void _showUpdateClientDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: const Text('Update Client Status'),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             TextFormField(
  //               controller:
  //                   clientIdNumberController, // For entering the client ID
  //               decoration: const InputDecoration(labelText: 'Client ID'),
  //             ),
  //             DropdownButtonFormField<String>(
  //               value: clientStatusController.text.isEmpty
  //                   ? 'Active' // Default value
  //                   : clientStatusController.text,
  //               onChanged: (String? newValue) {
  //                 setState(() {
  //                   clientStatusController.text = newValue!;
  //                 });
  //               },
  //               items: <String>['Active', 'Inactive']
  //                   .map<DropdownMenuItem<String>>((String value) {
  //                 return DropdownMenuItem<String>(
  //                   value: value,
  //                   child: Text(value),
  //                 );
  //               }).toList(),
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               // Ensure the fields are not empty before updating
  //               if (clientIdNumberController.text.isNotEmpty &&
  //                   clientStatusController.text.isNotEmpty) {
  //                 _updateClientStatus(
  //                   clientIdNumberController.text,
  //                   clientStatusController.text,
  //                 );
  //                 Navigator.pop(context); // Close the dialog
  //               } else {
  //                 // Optionally show an error if fields are empty
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   const SnackBar(content: Text("Please fill all fields")),
  //                 );
  //               }
  //             },
  //             child: const Text('Update'),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(context); // Close the dialog
  //             },
  //             child: const Text('Cancel'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // Future<void> _deleteClient(String userId) async {
  //   setState(() {
  //     isLoading = true;
  //   });

  //   var box = await Hive.openBox('userBox');
  //   String? token = box.get('token');

  //   final deleuser = kIsWeb
  //       ? 'http://192.168.88.13:4000/adminRoutes/delete-user/$userId' // For Web (Chrome)
  //       : 'http://10.0.2.2:4000/adminRoutes/delete-user/$userId'; // For Android Emulator

  //   print("deleuser is $deleuser");

  //   final response = await http.delete(
  //     Uri.parse(deleuser),
  //     headers: {
  //       'Authorization': 'Bearer $token',
  //     },
  //   );

  //   setState(() {
  //     isLoading = false;
  //   });

  //   if (response.statusCode == 200) {
  //     setState(() {
  //       fetchedData = 'Client deleted successfully!';
  //     });
  //   } else {
  //     setState(() {
  //       fetchedData = 'Error deleting client: ${response.body}';
  //     });
  //   }
  // }

  // Future<void> _addClient(String username, String password, String email,
  //     String phoneNumber, String fullName, String status) async {
  //   setState(() {
  //     isLoading = true;
  //   });

  //   if (username.isEmpty ||
  //       password.isEmpty ||
  //       email.isEmpty ||
  //       phoneNumber.isEmpty ||
  //       fullName.isEmpty ||
  //       status.isEmpty) {
  //     setState(() {
  //       fetchedData = 'Please fill in all required fields.';
  //     });
  //     setState(() {
  //       isLoading = false;
  //     });
  //     return;
  //   }

  //   var box = await Hive.openBox('userBox');
  //   String? token = box.get('token');

  //   if (token == null || token.isEmpty) {
  //     setState(() {
  //       fetchedData = 'No token provided. Please log in again.';
  //     });
  //     setState(() {
  //       isLoading = false;
  //     });
  //     return;
  //   }
  //   final creadmin = kIsWeb
  //       ? 'http://192.168.88.13:4000/adminRoutes/create-admin' // For Web (Chrome)
  //       : 'http://10.0.2.2:4000/adminRoutes/create-admin'; // For Android Emulator

  //   print("creadmin is $creadmin");

  //   final response = await http.post(
  //     Uri.parse(creadmin),
  //     headers: <String, String>{
  //       'Content-Type': 'application/json; charset=UTF-8',
  //       'Authorization': 'Bearer $token',
  //     },
  //     body: jsonEncode(<String, String>{
  //       'username': username,
  //       'password': password,
  //       'email': email,
  //       'phone_number': phoneNumber,
  //       'full_name': fullName,
  //       'status': status,
  //     }),
  //   );

  //   setState(() {
  //     isLoading = false;
  //   });

  //   if (response.statusCode == 201) {
  //     setState(() {
  //       fetchedData = 'Client added successfully!';
  //     });
  //   } else {
  //     setState(() {
  //       fetchedData = 'Error creating admin user: ${response.body}';
  //     });
  //   }
  // }

  // String _constructImageUrl(String relativePath) {
  //   final String baseUrl;
  //   if (kIsWeb) {
  //     baseUrl = 'http://192.168.88.13:4000'; //or the actual ip
  //   } else {
  //     baseUrl = 'http://10.0.2.2:4000';
  //   }
  //   print('the pic issssssss :$baseUrl/$relativePath');

  //   return '$baseUrl/$relativePath';
  // }

  // void _showAddClientDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: const Text('Add Admin'),
  //         content: SingleChildScrollView(
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               TextFormField(
  //                 controller: clientUsernameController,
  //                 decoration: const InputDecoration(labelText: 'Username'),
  //               ),
  //               TextFormField(
  //                 controller: clientPasswordController,
  //                 decoration: const InputDecoration(labelText: 'Password'),
  //               ),
  //               TextFormField(
  //                 controller: clientEmailController,
  //                 decoration: const InputDecoration(labelText: 'Email'),
  //               ),
  //               TextFormField(
  //                 controller: clientPhoneNumberController,
  //                 decoration: const InputDecoration(labelText: 'Phone Number'),
  //               ),
  //               TextFormField(
  //                 controller: clientFullNameController,
  //                 decoration: const InputDecoration(labelText: 'Full Name'),
  //               ),
  //               DropdownButtonFormField<String>(
  //                 value: selectedStatus,
  //                 onChanged: (String? newValue) {
  //                   setState(() {
  //                     selectedStatus = newValue!;
  //                   });
  //                 },
  //                 items: <String>['Active', 'Inactive']
  //                     .map<DropdownMenuItem<String>>((String value) {
  //                   return DropdownMenuItem<String>(
  //                     value: value,
  //                     child: Text(value),
  //                   );
  //                 }).toList(),
  //               ),
  //             ],
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               _addClient(
  //                 clientUsernameController.text,
  //                 clientPasswordController.text,
  //                 clientEmailController.text,
  //                 clientPhoneNumberController.text,
  //                 clientFullNameController.text,
  //                 selectedStatus,
  //               );
  //               Navigator.pop(context);
  //             },
  //             child: const Text('Add'),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(context);
  //             },
  //             child: const Text('Cancel'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // Future<void> _updateClientStatus(String userId, String status) async {
  //   setState(() {
  //     isLoading = true;
  //   });

  //   var box = await Hive.openBox('userBox');
  //   String? token = box.get('token');

  //   final updauser = kIsWeb
  //       ? 'http://192.168.88.13:4000/adminRoutes/update-user-status/$userId' // For Web (Chrome)
  //       : 'http://10.0.2.2:4000/adminRoutes/update-user-status/$userId'; // For Android Emulator

  //   print("updauser is $updauser");

  //   final response = await http.put(
  //     Uri.parse(updauser),
  //     headers: <String, String>{
  //       'Content-Type': 'application/json; charset=UTF-8',
  //       'Authorization': 'Bearer $token',
  //     },
  //     body: jsonEncode(<String, String>{
  //       'status': status,
  //     }),
  //   );

  //   setState(() {
  //     isLoading = false;
  //   });

  //   if (response.statusCode == 200) {
  //     setState(() {
  //       fetchedData = 'Client status updated successfully!';
  //     });
  //   } else {
  //     setState(() {
  //       fetchedData = 'Error updating client status: ${response.body}';
  //     });
  //   }
  // }


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
   PreferredSizeWidget _buildAppBar(bool isMobile){
    return  AppBar(
      title: const Text(
        'Manage Clients',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
      backgroundColor: const Color(0xFF0F3460),
    );
  }

    Widget _buildBody(bool isMobile, BoxConstraints constraints){
     return Row(
       children: [
         if (!isMobile) _buildDrawer(isMobile),
          Expanded(child: _buildClientContent(isMobile, constraints))
       ],
     );
    }
    Widget _buildDrawer(bool isMobile){
      return Drawer(
        child: Container(
          width: isMobile ? null : 250,
          color: const Color(0xFF0F3460),
          child: ListView(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xFFADD8E6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: isMobile ? 30 : 35,
                      backgroundColor: Colors.white,
                      backgroundImage: adminPicUrl.isNotEmpty
                          ? NetworkImage(adminPicUrl) // Use fetched image URL
                          : null, // If no image URL, fallback to default icon
                      child: adminPicUrl
                          .isEmpty // Fallback to default icon if no image
                          ? Icon(
                        Icons.person,
                        size: isMobile ? 40 : 50,
                        color: const Color(0xFF0F3460),
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
                        color: Colors.white70,
                        fontSize: isMobile ? 12 : 14,
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
        ),
      );
    }

  Widget _buildDrawerItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  void _showChatDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Chat with ${user['username']}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Start a conversation with ${user['username']}."),
              const SizedBox(height: 10),
              const TextField(
                decoration: InputDecoration(
                  labelText: "Enter your message",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                // Handle sending the message
                print("Message sent to ${user['username']}");
                Navigator.pop(context);
              },
              child: const Text("Send"),
            ),
          ],
        );
      },
    );
  }

  void _showUserDetailsDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Column(
            children: [
              // Profile picture with active status
              Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        _constructImageUrl(user['profile_picture']) != null
                            ? NetworkImage(
                                _constructImageUrl(user['profile_picture']))
                            : AssetImage('assets/images/default-profile.png')
                                as ImageProvider,
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: user['status'] == 'Active'
                            ? Colors.green
                            : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                user['username'] ?? 'User Details',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(user['role'] ?? 'N/A'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Email:', user['email'] ?? 'N/A', Icons.email),
                _buildDetailRow(
                    'Phone:', user['phone_number'] ?? 'N/A', Icons.phone),
                _buildDetailRow(
                    'Full Name:', user['full_name'] ?? 'N/A', Icons.person),
                _buildDetailRow('Membership Number:',
                    user['membership_number'] ?? 'N/A', Icons.card_membership),
                _buildDetailRow('Judge Number:', user['judge_number'] ?? 'N/A',
                    Icons.gavel),
                _buildDetailRow('ID Number:', user['id_number'] ?? 'N/A',
                    Icons.perm_identity),
                _buildDetailRow('Registration Date:',
                    user['registration_date'] ?? 'N/A', Icons.date_range),
                _buildDetailRow('Bio:', user['bio'] ?? 'N/A', Icons.info),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog before initiating chat
                _showChatDialog(user); // Initiates chat
              },
              child: const Text(
                "Chat",
                style: TextStyle(color: Colors.blue),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                    context); // Close dialog before delete confirmation
                _showDeleteConfirmationDialog(
                    user['id'].toString()); // Delete confirmation
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: const Text("Are you sure you want to delete this user?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cancel action
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _deleteClient(userId); // Convert to String
                print("User with ID $userId deleted.");
                Navigator.pop(context); // Close dialog
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 4.0),
                Text(value, style: const TextStyle(color: Colors.black)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientContent(bool isMobile, BoxConstraints constraints) {
    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          _buildSearchRow(isMobile), // Add the search bar at the top
          if (isLoading)
            const Center(child: CircularProgressIndicator()),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : users.isEmpty
                    ? const Center(
                        child: Text("No clients available."))
                    : _buildManageClientsForm(isMobile, constraints),
          ),
        ],
      ),
    );
  }
   Widget _buildSearchRow(bool isMobile){
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _onSearchChanged();
              },
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
         if (isMobile) ... [
           IconButton(
             icon: const Icon(Icons.notifications, color: blueColor),
             onPressed: () {
              // Navigator.pushReplacement(
              //   context,
              //   MaterialPageRoute(
              //       builder: (context) => notifications.NotificationPage()),
              // );
             },
           ),
           IconButton(
             icon: const Icon(Icons.chat, color: blueColor),
             onPressed: () {
              // Navigator.pushReplacement(
              //   context,
              //   MaterialPageRoute(builder: (context) => chat.ChatPage()),
              // );
             },
           ),
         ],
          IconButton(
            icon: const Icon(Icons.account_circle, color: blueColor),
            onPressed: () {
              // Navigator.pushReplacement(
              //   context,
              //   MaterialPageRoute(builder: (context) => ProfilePage()),
              // );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildManageClientsForm(bool isMobile, BoxConstraints constraints) {
      return SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 16.0, // Space between the button and the list of users
            ),
            Card(
              elevation: 4.0,
              margin: const EdgeInsets.symmetric(
                  horizontal: 16.0), // Add horizontal padding
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(12.0), // Smooth rounded corners
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // Aligns items neatly
                  children: [
                    const Text(
                      "Manage Admins",
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _showAddClientDialog(); // Show the dialog when the button is tapped
                      },
                      child: MouseRegion(
                        onEnter: (_) {
                          setState(() {
                            _isHovered = true; // Show text when hovering
                          });
                        },
                        onExit: (_) {
                          setState(() {
                            _isHovered = false; // Hide text when not hovering
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(
                              milliseconds: 200), // Smooth animation
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 12.0), // Comfortable padding
                          decoration: BoxDecoration(
                            color: Colors.green, // Vibrant green background
                            borderRadius:
                            BorderRadius.circular(12), // More rounded corners
                            boxShadow: [
                              BoxShadow(
                                color:
                                Colors.black.withOpacity(0.1), // Soft shadow
                                blurRadius: 6, // Smooth blur
                                offset: const Offset(
                                    0, 4), // Downward offset for natural shadow
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize:
                            MainAxisSize.min, // Minimize size to fit content
                            children: [
                              const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20.0, // Subtle reduction in icon size
                              ),
                              const SizedBox(width: 8.0), // Space between icon and text
                              AnimatedOpacity(
                                opacity: _isHovered
                                    ? 1.0
                                    : 0.0, // Show text only when hovered
                                duration:
                                const Duration(milliseconds: 200), // Smooth fade
                                child: const Text(
                                  'Add Admin',
                                  style: TextStyle(
                                    fontSize:
                                    14.0, // Adjusted font size for readability
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600, // Slightly bold
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                ? Center(child: Text(errorMessage)) // Display error message
                : (filteredUsers.isEmpty && users.isEmpty)
                ? const Center(child: Text("No users found."))
                : Container(
              height: isMobile ? null : 650 ,
              child: ListView.builder(
                shrinkWrap: isMobile ? true : false,
                physics: isMobile ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
                itemCount: filteredUsers.isNotEmpty
                    ? filteredUsers.length
                    : users
                    .length, // Use filtered users if available
                itemBuilder: (context, index) {
                  final user = filteredUsers.isNotEmpty
                      ? filteredUsers[index]
                      : users[index];
                  return GestureDetector(
                    onTap: () => _showUserDetailsDialog(user),
                    child: Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        leading: Stack(
                          alignment: Alignment
                              .topRight,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: _constructImageUrl(
                                  user[
                                  'profile_picture']) !=
                                  null
                                  ? NetworkImage(_constructImageUrl(
                                  user[
                                  'profile_picture']))
                                  : AssetImage(
                                  'assets/images/default-profile.png')
                              as ImageProvider,
                            ),
                            Positioned(
                              top:
                              0,
                              right: 0,
                              child: Container(
                                width:
                                12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: user['status'] == 'Active'
                                      ? Colors.green
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        title: Text(user['username'] ?? 'Unknown'),
                        subtitle: Text(user['role'] ?? 'N/A'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                _showChatDialog(
                                    user);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors
                                    .blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(4),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4),
                              ),
                              child:  Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.chat,
                                      size: 12,
                                      color: Colors
                                          .white),
                                  const SizedBox(
                                      width:
                                      2),
                                  const Text(
                                    "Chat",
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors
                                            .white),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                                width:
                                6),
                            ElevatedButton(
                              onPressed: () {
                                _showDeleteConfirmationDialog(user[
                                'id']
                                    .toString());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors
                                    .red,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(4),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.delete,
                                      size: 12,
                                      color: Colors
                                          .white),
                                  const SizedBox(
                                      width:
                                      2),
                                  const Text(
                                    "Delete",
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors
                                            .white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
  }

  void _showUpdateClientDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Client Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller:
                    clientIdNumberController,
                decoration: const InputDecoration(labelText: 'Client ID'),
              ),
              DropdownButtonFormField<String>(
                value: clientStatusController.text.isEmpty
                    ? 'Active'
                    : clientStatusController.text,
                onChanged: (String? newValue) {
                  setState(() {
                    clientStatusController.text = newValue!;
                  });
                },
                items: <String>['Active', 'Inactive']
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
                if (clientIdNumberController.text.isNotEmpty &&
                    clientStatusController.text.isNotEmpty) {
                  _updateClientStatus(
                    clientIdNumberController.text,
                    clientStatusController.text,
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill all fields")),
                  );
                }
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

  Future<void> _deleteClient(String userId) async {
    setState(() {
      isLoading = true;
    });

    var box = await Hive.openBox('userBox');
    String? token = box.get('token');

    final deleuser = kIsWeb
        ? 'http://192.168.88.11:4000/adminRoutes/delete-user/$userId' // For Web (Chrome)
        : 'http://10.0.2.2:4000/adminRoutes/delete-user/$userId'; // For Android Emulator

    print("deleuser is $deleuser");

    final response = await http.delete(
      Uri.parse(deleuser),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      setState(() {
        fetchedData = 'Client deleted successfully!';
      });
    } else {
      setState(() {
        fetchedData = 'Error deleting client: ${response.body}';
      });
    }
  }

  Future<void> _addClient(String username, String password, String email,
      String phoneNumber, String fullName, String status) async {
    setState(() {
      isLoading = true;
    });

    if (username.isEmpty ||
        password.isEmpty ||
        email.isEmpty ||
        phoneNumber.isEmpty ||
        fullName.isEmpty ||
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
    final creadmin = kIsWeb
        ? 'http://192.168.88.11:4000/adminRoutes/create-admin' // For Web (Chrome)
        : 'http://10.0.2.2:4000/adminRoutes/create-admin'; // For Android Emulator

    print("creadmin is $creadmin");

    final response = await http.post(
      Uri.parse(creadmin),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
        'email': email,
        'phone_number': phoneNumber,
        'full_name': fullName,
        'status': status,
      }),
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 201) {
      setState(() {
        fetchedData = 'Client added successfully!';
      });
    } else {
      setState(() {
        fetchedData = 'Error creating admin user: ${response.body}';
      });
    }
  }

  String _constructImageUrl(String? relativePath) {
    if (relativePath != null) {
       final String baseUrl;
       if (kIsWeb) {
        baseUrl = 'http://192.168.88.11:4000'; //or the actual ip
      } else {
         baseUrl = 'http://10.0.2.2:4000';
      }
       return '$baseUrl/$relativePath';
    } else {
      return '';
    }
  }

  void _showAddClientDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Admin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: clientUsernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                TextFormField(
                  controller: clientPasswordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                TextFormField(
                  controller: clientEmailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextFormField(
                  controller: clientPhoneNumberController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
                TextFormField(
                  controller: clientFullNameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedStatus = newValue!;
                    });
                  },
                  items: <String>['Active', 'Inactive']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _addClient(
                  clientUsernameController.text,
                  clientPasswordController.text,
                  clientEmailController.text,
                  clientPhoneNumberController.text,
                  clientFullNameController.text,
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

  Future<void> _updateClientStatus(String userId, String status) async {
    setState(() {
      isLoading = true;
    });

    var box = await Hive.openBox('userBox');
    String? token = box.get('token');

    final updauser = kIsWeb
        ? 'http://192.168.88.11:4000/adminRoutes/update-user-status/$userId' // For Web (Chrome)
        : 'http://10.0.2.2:4000/adminRoutes/update-user-status/$userId'; // For Android Emulator

    print("updauser is $updauser");

    final response = await http.put(
      Uri.parse(updauser),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
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
        fetchedData = 'Client status updated successfully!';
      });
    } else {
      setState(() {
        fetchedData = 'Error updating client status: ${response.body}';
      });
    }
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firstproj/Pages/AdminDashboardPage.dart' as adminDashboardPage;
import 'package:firstproj/Pages/ManageClients.dart' as manageClients;
import 'package:firstproj/Pages/ManageCases.dart' as manageCases;
import 'package:firstproj/Pages/LegalDocuments.dart' as legalDocuments;
import 'package:firstproj/Pages/Reports.dart' as reports;
import 'package:firstproj/Pages/Billing.dart' as billing;
import 'package:firstproj/Pages/Notifications.dart' as notifications;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firstproj/Pages/ManageComplaints.dart' as manageComplaints;

const Color blueColor = Color(0xFF1E88E5);

class ManageClients extends StatefulWidget {
  @override
  _ManageClientsState createState() => _ManageClientsState();
}

class _ManageClientsState extends State<ManageClients> {
  bool isLoading = false;
  String fetchedData = '';
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
  String selectedStatus = 'Active'; // Declare selectedStatus here

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Clients')),
      drawer: _buildDrawer(), // Adding Drawer here
      body: _buildManageClientsForm(),
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
            _buildDrawerItem('Manage Complaints', Icons.library_books, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => manageComplaints.ManageComplaints(),
                ),
              );
            }),
            _buildDrawerItem('Legal Documents', Icons.document_scanner, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const legalDocuments.LegalDocuments(),
                ),
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

  Widget _buildManageClientsForm() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // First Card (Add)
        Card(
          color: Colors.green,
          elevation: 4.0,
          child: ListTile(
            contentPadding: EdgeInsets.all(16.0),
            title: Text(
              'Add New Admin',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Icon(Icons.add, color: Colors.white),
            onTap: () {
              _showAddClientDialog();
            },
          ),
        ),
        SizedBox(height: 16.0),

        // Second Card (Update)
        Card(
          color: Colors.yellow,
          elevation: 4.0,
          child: ListTile(
            contentPadding: EdgeInsets.all(16.0),
            title: Text(
              'Update Client Status',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Icon(Icons.update, color: Colors.black),
            onTap: () {
              _showUpdateClientDialog();
            },
          ),
        ),
        SizedBox(height: 16.0),

        // Third Card (Delete)
        Card(
          color: Colors.red,
          elevation: 4.0,
          child: ListTile(
            contentPadding: EdgeInsets.all(16.0),
            title: Text(
              'Delete Client',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Icon(Icons.delete, color: Colors.white),
            onTap: () {
              _showDeleteClientDialog(); // No need to pass clientId here, since it will be entered in the dialog
            },
          ),
        ),
        SizedBox(height: 16.0),

        // Loading or Fetched Data
        isLoading
            ? const Center(child: CircularProgressIndicator())
            : Text(fetchedData),
      ],
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
                    clientIdNumberController, // For entering the client ID
                decoration: const InputDecoration(labelText: 'Client ID'),
              ),
              DropdownButtonFormField<String>(
                value: clientStatusController.text.isEmpty
                    ? 'Active' // Default value
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
                _updateClientStatus(
                  clientIdNumberController.text,
                  clientStatusController.text,
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

  void _showDeleteClientDialog() {
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Client'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter the Client ID to delete:'),
              TextFormField(
                controller: _controller,
                decoration: const InputDecoration(hintText: 'Enter Client ID'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                String clientId = _controller.text;
                if (clientId.isNotEmpty) {
                  _deleteClient(clientId);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid Client ID.')),
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

  Future<void> _deleteClient(String userId) async {
    setState(() {
      isLoading = true;
    });

    var box = await Hive.openBox('userBox');
    String? token = box.get('token');

    final response = await http.delete(
      Uri.parse('http://10.0.2.2:4000/adminRoutes/delete-user/$userId'),
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

    final response = await http.post(
      Uri.parse('http://10.0.2.2:4000/adminRoutes/create-admin'),
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

  void _showAddClientDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Client'),
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

    final response = await http.put(
      Uri.parse('http://10.0.2.2:4000/adminRoutes/update-user-status/$userId'),
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

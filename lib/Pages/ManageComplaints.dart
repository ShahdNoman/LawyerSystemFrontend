import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firstproj/Pages/AdminDashboardPage.dart' as adminDashboardPage;
import 'package:firstproj/Pages/ManageClients.dart' as manageClients;
import 'package:firstproj/Pages/ManageComplaints.dart' as manageComplaints;
import 'package:firstproj/Pages/LegalDocuments.dart' as legalDocuments;
import 'package:firstproj/Pages/Reports.dart' as reports;
import 'package:firstproj/Pages/Billing.dart' as billing;
import 'package:firstproj/Pages/Notifications.dart' as notifications;
import 'package:firstproj/Pages/ManageCases.dart' as manageCases;
import 'package:hive_flutter/hive_flutter.dart';

const Color blueColor = Color(0xFF1E88E5);

class ManageComplaints extends StatefulWidget {
  @override
  _ManageComplaintsState createState() => _ManageComplaintsState();
}

class _ManageComplaintsState extends State<ManageComplaints> {
  bool isLoading = false;
  String fetchedData = '';
  TextEditingController complaintTitleController = TextEditingController();
  TextEditingController complaintDescriptionController =
      TextEditingController();
  TextEditingController complaintClientController = TextEditingController();
  TextEditingController complaintStatusController = TextEditingController();
  TextEditingController complaintIdToDeleteController = TextEditingController();
  String selectedStatus = 'Open'; // Declare selectedStatus here

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Complaints')),
      drawer: _buildDrawer(), // Adding Drawer here
      body: _buildManageComplaintsForm(),
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
            _buildDrawerItem('Manage Cases', Icons.people, () {
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

  Widget _buildManageComplaintsForm() {
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
              'Add New Complaint',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Icon(Icons.add, color: Colors.white),
            onTap: () {
              _showAddComplaintDialog();
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
              'Update Complaint Status',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Icon(Icons.update, color: Colors.black),
            onTap: () {
              _showUpdateComplaintDialog();
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
              'Delete Complaint',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Icon(Icons.delete, color: Colors.white),
            onTap: () {
              _showDeleteComplaintDialog();
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

  void _showAddComplaintDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Complaint'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: complaintTitleController,
                decoration: const InputDecoration(labelText: 'Complaint Title'),
              ),
              TextFormField(
                controller: complaintDescriptionController,
                decoration:
                    const InputDecoration(labelText: 'Complaint Description'),
              ),
              TextFormField(
                controller: complaintClientController,
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
                _addComplaint(
                  complaintTitleController.text,
                  complaintDescriptionController.text,
                  complaintClientController.text,
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

  Future<void> _addComplaint(
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
      Uri.parse('http://10.0.2.2:4000/adminRoutes/create-complaint'),
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
        fetchedData = 'Complaint added successfully!';
      });
    } else {
      setState(() {
        fetchedData = 'Error adding complaint: ${response.body}';
      });
    }
  }

  void _showUpdateComplaintDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Complaint Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller:
                    complaintIdToDeleteController, // For entering the complaint ID
                decoration: const InputDecoration(labelText: 'Complaint ID'),
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
                _updateComplaintStatus(
                  complaintIdToDeleteController.text,
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

  Future<void> _updateComplaintStatus(String complaintId, String status) async {
    setState(() {
      isLoading = true;
    });

    var box = await Hive.openBox('userBox');
    String? token = box.get('token');

    final response = await http.put(
      Uri.parse(
          'http://10.0.2.2:4000/adminRoutes/update-complaint-status/$complaintId'),
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
        fetchedData = 'Complaint status updated successfully!';
      });
    } else {
      setState(() {
        fetchedData = 'Error updating complaint: ${response.body}';
      });
    }
  }

  void _showDeleteComplaintDialog() {
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Complaint'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter the Complaint ID to delete:'),
              TextFormField(
                controller: _controller,
                decoration:
                    const InputDecoration(hintText: 'Enter Complaint ID'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                String complaintId = _controller.text;
                if (complaintId.isNotEmpty) {
                  _deleteComplaint(complaintId);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid Complaint ID.')),
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

  Future<void> _deleteComplaint(String complaintId) async {
    setState(() {
      isLoading = true;
    });

    var box = await Hive.openBox('userBox');
    String? token = box.get('token');

    final response = await http.delete(
      Uri.parse(
          'http://10.0.2.2:4000/adminRoutes/delete-complaint/$complaintId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      setState(() {
        fetchedData = 'Complaint deleted successfully!';
      });
    } else {
      setState(() {
        fetchedData = 'Error deleting complaint: ${response.body}';
      });
    }
  }
}

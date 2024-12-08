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
import 'package:firstproj/Pages/ManageComplaints.dart' as manageComplaints;

import 'package:hive_flutter/hive_flutter.dart';

const Color blueColor = Color(0xFF1E88E5);

class ManageCases extends StatefulWidget {
  @override
  _ManageCasesState createState() => _ManageCasesState();
}

class _ManageCasesState extends State<ManageCases> {
  bool isLoading = false;
  String fetchedData = '';
  TextEditingController caseTitleController = TextEditingController();
  TextEditingController caseDescriptionController = TextEditingController();
  TextEditingController caseClientController = TextEditingController();
  TextEditingController caseStatusController = TextEditingController();
  TextEditingController caseIdToDeleteController = TextEditingController();
  String selectedStatus = 'Open'; // Declare selectedStatus here

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Cases')),
      drawer: _buildDrawer(), // Adding Drawer here
      body: _buildManageCasesForm(),
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

  Widget _buildManageCasesForm() {
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
              'Add New Case',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Icon(Icons.add, color: Colors.white),
            onTap: () {
              _showAddCaseDialog();
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
              'Update Case Status',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Icon(Icons.update, color: Colors.black),
            onTap: () {
              _showUpdateCaseDialog();
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
              'Delete Case',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Icon(Icons.delete, color: Colors.white),
            onTap: () {
              _showDeleteCaseDialog(); // No need to pass caseId here, since it will be entered in the dialog
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

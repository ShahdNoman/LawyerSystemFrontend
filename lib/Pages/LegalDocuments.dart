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

class LegalDocuments extends StatefulWidget {
  const LegalDocuments({Key? key}) : super(key: key);

  @override
  _LegalDocumentsState createState() => _LegalDocumentsState();
}

class _LegalDocumentsState extends State<LegalDocuments> {
  bool isLoading = false;
  String fetchedData = '';
  TextEditingController documentTitleController = TextEditingController();
  TextEditingController documentDescriptionController = TextEditingController();
  TextEditingController documentIdToDeleteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legal Documents')),
      drawer: _buildDrawer(), // Adding Drawer here
      body: _buildLegalDocumentsForm(),
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

  Widget _buildLegalDocumentsForm() {
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
              'Add New Document',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Icon(Icons.add, color: Colors.white),
            onTap: () {
              _showAddDocumentDialog();
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
              'Update Document',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Icon(Icons.update, color: Colors.black),
            onTap: () {
              _showUpdateDocumentDialog();
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
              'Delete Document',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Icon(Icons.delete, color: Colors.white),
            onTap: () {
              _showDeleteDocumentDialog();
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

  void _showAddDocumentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: documentTitleController,
                decoration: const InputDecoration(labelText: 'Document Title'),
              ),
              TextFormField(
                controller: documentDescriptionController,
                decoration:
                    const InputDecoration(labelText: 'Document Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _addDocument(
                  documentTitleController.text,
                  documentDescriptionController.text,
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

  Future<void> _addDocument(String title, String description) async {
    setState(() {
      isLoading = true;
    });

    if (title.isEmpty || description.isEmpty) {
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
      Uri.parse('http://10.0.2.2:4000/adminRoutes/add-attachment'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'title': title,
        'description': description,
      }),
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 201) {
      setState(() {
        fetchedData = 'Document added successfully!';
      });
    } else {
      setState(() {
        fetchedData = 'Error adding document: ${response.body}';
      });
    }
  }

  void _showUpdateDocumentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: documentIdToDeleteController,
                decoration: const InputDecoration(labelText: 'Document ID'),
              ),
              TextFormField(
                controller: documentTitleController,
                decoration: const InputDecoration(labelText: 'Document Title'),
              ),
              TextFormField(
                controller: documentDescriptionController,
                decoration:
                    const InputDecoration(labelText: 'Document Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _updateDocument(
                  documentIdToDeleteController.text,
                  documentTitleController.text,
                  documentDescriptionController.text,
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

  Future<void> _updateDocument(
      String documentId, String title, String description) async {
    setState(() {
      isLoading = true;
    });

    var box = await Hive.openBox('userBox');
    String? token = box.get('token');

    final response = await http.put(
      Uri.parse(
          'http://10.0.2.2:4000/adminRoutes/update-attachments/$documentId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'title': title,
        'description': description,
      }),
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      setState(() {
        fetchedData = 'Document updated successfully!';
      });
    } else {
      setState(() {
        fetchedData = 'Error updating document: ${response.body}';
      });
    }
  }

  void _showDeleteDocumentDialog() {
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter the Document ID'),
              TextFormField(
                controller: _controller,
                decoration: const InputDecoration(labelText: 'Document ID'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _deleteDocument(_controller.text);
                Navigator.pop(context);
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

  Future<void> _deleteDocument(String documentId) async {
    setState(() {
      isLoading = true;
    });

    var box = await Hive.openBox('userBox');
    String? token = box.get('token');

    final response = await http.delete(
      Uri.parse(
          'http://10.0.2.2:4000/adminRoutes/delete-attachment/$documentId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      setState(() {
        fetchedData = 'Document deleted successfully!';
      });
    } else {
      setState(() {
        fetchedData = 'Error deleting document: ${response.body}';
      });
    }
  }
}

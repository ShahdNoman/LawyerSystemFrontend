import 'package:firstproj/Pages/TokenUtils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';

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
  List<dynamic> reportsData = [];

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

  // Function to fetch reports data from the backend
  Future<List<dynamic>> fetchReportsData(String token) async {
    final response = await http.get(
      Uri.parse('https://your-backend-api.com/reports'), // Replace with your backend API URL
      headers: {
        'Authorization': 'Bearer $token', // Use the token for authentication
      },
    );

    if (response.statusCode == 200) {
      // Parse the JSON response and return the reports data
      return json.decode(response.body)['reports'];
    } else {
      throw Exception('Failed to load reports data');
    }
  }

  // Fetching reports data example
  Future<void> _fetchReportsData() async {
    try {
      var box = await Hive.openBox('userBox');
      final token = box.get('token');
      print('Token retrieved: $token');

      if (token == null || token.isEmpty) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      final data = await fetchReportsData(token);
      setState(() {
        isLoading = false;
        reportsData = data;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        reportsData = [];
      });
      print('Error during request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reports',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF0F3460),
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : ListView.builder(
                itemCount: reportsData.length,
                itemBuilder: (context, index) {
                  final report = reportsData[index];
                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      title: Text('Report: ${report['reportName']}'),
                      subtitle: Text('Date: ${report['date']}'),
                      trailing: Text('Status: ${report['status']}'),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchReportsData,
        backgroundColor: blueColor,
        child: Icon(Icons.refresh),
      ),
    );
  }
}

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

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
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

  // Function to fetch notifications data from backend
  Future<Map<String, dynamic>> fetchNotifications(String token) async {
    final response = await http.get(
      Uri.parse('https://your-backend-api.com/notifications'), // Replace with your backend API URL
      headers: {
        'Authorization': 'Bearer $token', // Use the token for authentication
      },
    );

    if (response.statusCode == 200) {
      // Parse the JSON response
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  // Fetching notifications data example
  Future<void> _fetchNotifications() async {
    try {
      var box = await Hive.openBox('userBox');
      final token = box.get('token');
      print('Token retrieved: $token');

      if (token == null || token.isEmpty) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      final notificationsData = await fetchNotifications(token);
      setState(() {
        isLoading = false;
        fetchedData = notificationsData['message'];
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
          'Notifications',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF0F3460),
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(fetchedData),
                  ElevatedButton(
                    onPressed: _fetchNotifications,
                    child: Text('Fetch Notifications'),
                  ),
                ],
              ),
      ),
    );
  }
}

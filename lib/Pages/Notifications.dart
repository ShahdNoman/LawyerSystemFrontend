import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:firstproj/Pages/TokenUtils.dart';
import 'package:firstproj/Pages/AdminDashboardPage.dart' as adminDashboardPage;
import 'package:flutter/foundation.dart'; // Import to check if running on web

class NotificationPage extends StatefulWidget {
  NotificationPage({Key? key}) : super(key: key);

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<dynamic> notifications = [];
  bool isLoading = true;
  String errorMessage = '';
  late String token = ""; // Initialize token with an empty string
  late Timer _timer;

  @override
  void initState() {
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      TokenUtils.checkTokenExpiration(context);
    });
    super.initState();
    _fetchNotifications();
    _getToken();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
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

  Future<void> _fetchNotifications() async {
    try {
      var box = await Hive.openBox('userBox');
      final token = box.get('token');

      if (token == null || token.isEmpty) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }
      final List<dynamic> data =
          await fetchNotifications(token); // Fetch all cases once

      setState(() {
        notifications = data; // Store the fetched cases
        // displayedCases = cases;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching notifications: $e';
      });
      print('Error: $e');
    }
  }

  Future<List<dynamic>> fetchNotifications(String token) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:4000/adminRoutes/viewAll-notifications'),
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
          'Failed to load notifications. Status Code: ${response.statusCode}');
    }
  }

  Future<void> deleteNotification(int notificationId, String token) async {
    final response = await http.delete(
      Uri.parse(
          'http://10.0.2.2:4000/adminRoutes/delete-notification/$notificationId'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      print('Notification deleted');
    } else {
      throw Exception('Failed to delete notification');
    }
  }

  Future<void> deleteAllNotifications(String token) async {
    final response = await http.delete(
      Uri.parse('http://10.0.2.2:4000/adminRoutes/delete-all-notifications'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      print('All notifications deleted');
      // Reload or update the UI after deletion
    } else {
      throw Exception('Failed to delete all notifications');
    }
  }

  Future<void> markNotificationAsRead(int notificationId, String token) async {
    final response = await http.put(
      Uri.parse(
          'http://10.0.2.2:4000/adminRoutes/mark-notification-read/$notificationId'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"id": notificationId}),
    );

    if (response.statusCode == 200) {
      print('Notification marked as read');
      _fetchNotifications();
    } else {
      throw Exception('Failed to mark notification as read');
    }
  }

  Future<void> markAllAsRead(String token) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:4000/adminRoutes/markAll-notifications-read'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      print('All notifications marked as read');
      _fetchNotifications();
    } else {
      throw Exception('Failed to mark all notifications as read');
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return FutureBuilder<List<dynamic>>(
            future: fetchNotifications(token), // Call to fetch notifications
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No notifications available.'));
              }

              final notifications = snapshot.data!;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    adminDashboardPage.AdminDashboardPage()),
                          );
                        },
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // "Mark All as Read" Button
                        ElevatedButton.icon(
                          onPressed: () async {
                            await markAllAsRead(token); // Call function
                          },
                          icon: Icon(Icons.done_all),
                          label: Text("Mark All as Read"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        // "Delete All" Icon Button
                        IconButton(
                          icon: Icon(
                            Icons.delete_forever,
                            color: Colors.red,
                            size: 28,
                          ),
                          onPressed: () async {
                            // Show confirmation dialog before deleting all
                            bool? confirmDelete = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Delete All Notifications'),
                                  content: Text(
                                      'Are you sure you want to delete all notifications? This action cannot be undone.'),
                                  actions: <Widget>[
                                    TextButton(
                                      child: Text('Cancel'),
                                      onPressed: () {
                                        Navigator.of(context).pop(false);
                                      },
                                    ),
                                    TextButton(
                                      child: Text('Delete All'),
                                      onPressed: () {
                                        Navigator.of(context).pop(true);
                                      },
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirmDelete == true) {
                              await deleteAllNotifications(
                                  token); // Call delete API
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  // Notifications List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final notificationType =
                            notification['notification_type'];
                        final message = notification['message'];
                        final isRead = notification['is_read'] == 1;
                        final sendDate = notification['send_date'];

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Icon(
                              Icons.notifications,
                              color: isRead ? Colors.green : Colors.grey,
                              size: 28,
                            ),
                            title: Text(
                              notificationType,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message,
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  sendDate != null
                                      ? 'Sent on: ${sendDate.toString()}'
                                      : 'No date available',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () async {
                              // Mark the individual notification as read
                              await markNotificationAsRead(
                                  notification['id'], token);
                            },
                            trailing: IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 24,
                              ),
                              onPressed: () async {
                                // Show confirmation dialog before deleting a notification
                                bool? confirmDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Delete Notification'),
                                      content: Text(
                                          'Are you sure you want to delete this notification?'),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text('Cancel'),
                                          onPressed: () {
                                            Navigator.of(context).pop(false);
                                          },
                                        ),
                                        TextButton(
                                          child: Text('Delete'),
                                          onPressed: () {
                                            Navigator.of(context).pop(true);
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (confirmDelete == true) {
                                  await deleteNotification(
                                      notification['id'], token);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: Center(
        child: Text('Notifications Page'),
      ),
    );
  }
}

import 'package:LAWYERSYSTEMFRONTEND/Pages/AdminDashboardPage.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'TokenUtils.dart';

class NotificationPage extends StatefulWidget {
  NotificationPage({Key? key}) : super(key: key);

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<dynamic> notifications = [];
  bool isLoading = true;
  String errorMessage = '';
  late String token = "";
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
      Navigator.pushReplacementNamed(context, '/');
    } else {
      setState(() {
        token = tokenFromBox;
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
      final List<dynamic> data = await fetchNotifications(token);

      setState(() {
        notifications = data;
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
      _fetchNotifications();
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
      _fetchNotifications();
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
    return FutureBuilder<List<dynamic>>(
      future: fetchNotifications(token),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final notifications = snapshot.data;

        return Dialog(
          insetPadding: const EdgeInsets.only(top: 80),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: Color(0xFF003366)),
                          onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
                );
              },
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          await markAllAsRead(token);
                        },
                        icon: const Icon(Icons.done_all, color: Colors.white),
                        label:
                        const Text("Mark All as Read", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003366),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                          size: 28,
                        ),
                        onPressed: () async {
                          bool? confirmDelete = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Delete All Notifications'),
                                content: const Text(
                                    'Are you sure you want to delete all notifications? This action cannot be undone.'),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('Cancel'),
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('Delete All'),
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmDelete == true) {
                            await deleteAllNotifications(token);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: notifications == null || notifications.isEmpty
                      ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'There are no notifications yet.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ))
                      : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final notificationType = notification['notification_type'];
                      final message = notification['message'];
                      final isRead = notification['is_read'] == 1;
                      final sendDate = notification['send_date'];
                      final notificationId = notification['id'];

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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF003366),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                sendDate != null
                                    ? 'Sent on: ${sendDate.toString()}'
                                    : 'No date available',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          onTap: () async {
                            await markNotificationAsRead(
                                notificationId, token);
                          },
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 24,
                            ),
                            onPressed: () async {
                              bool? confirmDelete = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Delete Notification'),
                                    content: const Text(
                                        'Are you sure you want to delete this notification?'),
                                    actions: <Widget>[
                                      TextButton(
                                        child: const Text('Cancel'),
                                        onPressed: () {
                                          Navigator.of(context).pop(false);
                                        },
                                      ),
                                      TextButton(
                                        child: const Text('Delete'),
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
                                    notificationId, token);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
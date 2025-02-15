// import 'package:flutter/material.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'dart:async';
// import 'package:firstproj/Pages/TokenUtils.dart';
// import 'package:firstproj/Pages/AdminDashboardPage.dart' as adminDashboardPage;
// import 'package:firstproj/Pages/LoginPage.dart' as loginpage;
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:flutter/scheduler.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/foundation.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart'
//     as localNotifications;

// const Color darkBlueColor = Color(0xFF0F3460);
// const Color darkBackgroundColor = Color(0xFF1A202C);
// const Color lightBlueColor = Color(0xFFADD8E6);
// const Color whiteColor = Colors.white;
// const Color userBubbleColor = Color(0xFF6750A4);
// const Color otherBubbleColor = Color(0xFFD3D3D3);

// // final localNotifications.FlutterLocalNotificationsPlugin
// //     flutterLocalNotificationsPlugin =
// //     localNotifications.FlutterLocalNotificationsPlugin();

// // Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
// //   await Firebase.initializeApp();
// //   print("Handling a background message: ${message.messageId}");
// // }

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized
//   // try {
//   //   await Firebase.initializeApp(); // Initialize Firebase first
//   // } catch (e) {
//   //   print('Error initializing Firebase App: $e');
//   // }

//   // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//   // const localNotifications.AndroidInitializationSettings
//   //     initializationSettingsAndroid =
//   //     localNotifications.AndroidInitializationSettings('@mipmap/ic_launcher');

//   // const localNotifications.InitializationSettings initializationSettings =
//   //     localNotifications.InitializationSettings(
//   //   android: initializationSettingsAndroid,
//   // );
//   // await flutterLocalNotificationsPlugin.initialize(initializationSettings,
//   //     onDidReceiveNotificationResponse: (details) {});

//   runApp(ChatPage());
// }

// class ChatPage extends StatefulWidget {
//   ChatPage({Key? key}) : super(key: key);

//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatPage> {
//   late IO.Socket socket;
//   bool isLoading = true;
//   String fetchedData = '';
//   late Timer _timer;
//   List<dynamic> filteredUsers = [];
//   List<dynamic> users = [];
//   String adminName = 'Admin';
//   String adminEmail = 'admin@example.com';
//   String adminPicUrl = '';
//   String adminId = '';
//   bool isUserSelected = false;
//   String selectedUserName = '';
//   String selectedUserPic = '';
//   String receiverId = '';
//   final ScrollController _scrollController = ScrollController();
//   List<Map<String, dynamic>> chatMessages = []; //change this line
//   late TextEditingController _messageController = TextEditingController();
//   late TextEditingController _searchController = TextEditingController();
//   String _errorMessage = '';
//   int _selectedIndex = 0;

//   @override
//   void initState() {
//     super.initState();
//     // _initLocalNotification();
//     //_getFCMToken();
//     print('Initializing chat page');
//     Future.delayed(Duration(milliseconds: 500), () {
//       _getFCMToken(); // Call _getFCMToken with a delay
//     });
//     _timer = Timer.periodic(Duration(seconds: 30), (timer) {
//       TokenUtils.checkTokenExpiration(context);
//     });
//     _fetchAdminData();
//     _fetchUsers();
//     _initializeWebSocket();

//     _searchController.addListener(_onSearchChanged);
//     WidgetsBinding.instance!.addPostFrameCallback((_) {
//       if (isUserSelected) {
//         _scrollToBottom();
//       }
//     });
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//   }

//   // Future<void> _initLocalNotification() async {
//   //   const localNotifications.AndroidInitializationSettings
//   //       initializationSettingsAndroid =
//   //       localNotifications.AndroidInitializationSettings('@mipmap/ic_launcher');

//   //   const localNotifications.InitializationSettings initializationSettings =
//   //       localNotifications.InitializationSettings(
//   //     android: initializationSettingsAndroid,
//   //   );

//   //   await flutterLocalNotificationsPlugin.initialize(initializationSettings,
//   //       onDidReceiveNotificationResponse: (details) {});
//   // }

//   // void _handleForegroundMessage(RemoteMessage message) {
//   //   print(
//   //       'Received foreground message: ${message.notification?.title} ${message.notification?.body}');
//   //   if (message.notification != null) {
//   //     const localNotifications.AndroidNotificationDetails
//   //         androidNotificationDetails =
//   //         localNotifications.AndroidNotificationDetails(
//   //             'chat_channel_id', // Unique channel ID
//   //             'Chat Messages', // Channel name
//   //             priority: localNotifications.Priority.max,
//   //             importance: localNotifications.Importance.max);
//   //     const localNotifications.NotificationDetails notificationDetails =
//   //         localNotifications.NotificationDetails(
//   //             android: androidNotificationDetails);
//   //     flutterLocalNotificationsPlugin.show(
//   //         message.hashCode,
//   //         message.notification?.title,
//   //         message.notification?.body,
//   //         notificationDetails);
//   //   }
//   // }

//   void listenForIncomingMessages() {
//     try {
//       if (!socket.hasListeners('receive_message')) {
//         socket.on('receive_message', (data) {
//           print('Received message: $data'); // Log when the message is received
//           try {
//             final decodedData = jsonDecode(data);
//             print(
//                 'listenForIncomingMessages: Decoded message: $decodedData'); // Log decoded message
//             print(
//                 "setState called in receive_message"); // Log if setState is called

//             setState(() {
//               if (decodedData['sender_id'].toString() == receiverId ||
//                   decodedData['sender_id'].toString() == adminId) {
//                 // Modified here to include sender_name
//                 chatMessages.add(decodedData);
//                 print(
//                     'listenForIncomingMessages: Updated chatMessages after appending new message: $chatMessages');
//                 _scrollToBottom();
//               } else {
//                 // Update message also if the user is not selected but message belongs to logged in admin
//                 if (decodedData['receiver_id'].toString() ==
//                     adminId.toString()) {
//                   print(
//                       'listenForIncomingMessages: Received message from user ${decodedData['sender_id']} and is not for current user. Updating message list and selecting the user.');

//                   _showNotification(
//                     decodedData['sender_name'] ??
//                         "New Message", // modified here
//                     decodedData['content'] ?? "",
//                   );

//                   // find the user and select user if it is not already selected.
//                   dynamic user;
//                   for (final dynamic u in users) {
//                     if (u['id'].toString() ==
//                         decodedData['sender_id'].toString()) {
//                       user = u;
//                       break;
//                     }
//                   }

//                   if (user != null) {
//                     print(
//                         'listenForIncomingMessages: Calling selectUser for user: ${user['username']}');
//                     selectUser(user);
//                     print(
//                         'listenForIncomingMessages: After selectUser was called for user: ${user['username']}');
//                   } else {
//                     print("User not found. Ignoring message");
//                   }
//                 } else {
//                   print(
//                       'listenForIncomingMessages: Message not for selected user and logged in admin, Ignoring it.');
//                   print("DecodedData is " +
//                       decodedData.toString() +
//                       " and receiverId is: " +
//                       receiverId +
//                       " and adminId is: " +
//                       adminId);
//                 }
//               }
//             });
//           } catch (e) {
//             setState(() {
//               _errorMessage = "Error decoding incoming message: $e";
//             });
//             print('listenForIncomingMessages: Error decoding message: $e');
//           }
//         });
//       }
//     } catch (e, stackTrace) {
//       setState(() {
//         _errorMessage = "Error listening for incoming messages: $e";
//       });
//       print(
//           'listenForIncomingMessages: Error listening for incoming messages: $e');
//       print('listenForIncomingMessages: Stack Trace: $stackTrace');
//     }
//   }

//   Future<void> _sendTokenToServer(
//       String token, String userId, String authToken) async {
//     final userdata = kIsWeb
//         ? 'http://192.168.88.11:4000/adminRoutes/update-my-info' // For Web (Chrome)
//         : 'http://10.0.2.2:4000/adminRoutes/update-my-info'; // For Android Emulator
//     print("Sending token to api $userdata ");
//     try {
//       final response = await http.post(
//         Uri.parse(userdata),
//         headers: <String, String>{
//           'Content-Type': 'application/json; charset=UTF-8',
//           'Authorization': 'Bearer $authToken',
//         },
//         body: jsonEncode({
//           'fcmToken': token,
//         }),
//       );
//       print("Response: ${response.statusCode} body: ${response.body}");
//     } catch (e) {
//       print('Error sending token to backend: $e');
//     }
//   }

//   Future<void> _getFCMToken() async {
//     print("Starting _getFCMToken");
//     try {
//       FirebaseMessaging messaging = FirebaseMessaging.instance;
//       print("FirebaseMessaging.instance created");
//       print("Requesting notification permissions");
//       NotificationSettings settings = await messaging.requestPermission(
//         alert: true,
//         announcement: false,
//         badge: true,
//         carPlay: false,
//         criticalAlert: false,
//         provisional: false,
//         sound: true,
//       );
//       print("Authorization Status: ${settings.authorizationStatus}");

//       if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//         print('User granted permission');
//         try {
//           print('Attempting to get FCM Token');
//           final token = await messaging.getToken();
//           if (token != null) {
//             print("FCM token is: " + token.toString());
//             var box = await Hive.openBox('userBox');
//             final userId = box.get('id');
//             final tokenToSend = box.get('token');
//             print("Token to Send is: " + tokenToSend.toString());
//             await _sendTokenToServer(token, userId, tokenToSend);
//           } else {
//             print("FCM token is null");
//           }
//         } on FirebaseException catch (e) {
//           print('Firebase Exception getting token: $e');
//           print('Firebase Exception: Code = ${e.code} Message = ${e.message}');
//         } catch (e) {
//           print('Error getting token: $e');
//         }
//       } else if (settings.authorizationStatus ==
//           AuthorizationStatus.provisional) {
//         print('User granted provisional permission');
//       } else {
//         print('User declined or has not accepted permission');
//         // If not authorized, request permission again
//         print("Requesting Notification Permissions again");
//       }
//     } on FirebaseException catch (e) {
//       print('Firebase Exception getting permission : $e');
//       print('Firebase Exception: Code = ${e.code} Message = ${e.message}');
//     } catch (e) {
//       print('Error calling _getFCMToken method $e');
//     }
//     FirebaseMessaging messaging = FirebaseMessaging.instance;
//     messaging.onTokenRefresh.listen((fcmToken) async {
//       print('FCM token has refreshed $fcmToken');
//       var box = await Hive.openBox('userBox');
//       final userId = box.get('id');
//       final tokenToSend = box.get('token');
//       await _sendTokenToServer(fcmToken, userId, tokenToSend);
//     });

//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       _handleForegroundMessage(message);
//     });
//   }

//     void _handleForegroundMessage(RemoteMessage message) {
//             print('Received a foreground message ${message.messageId}');
//             // Logic to display a notification or dialog
//     }
//   void _initializeWebSocket() {
//     try {
//       print('Connecting to WebSocket...');

//       final String socketUrl;
//       if (kIsWeb) {
//         // Web: Use machine's IP address
//         socketUrl = 'ws://192.168.88.11:5000';
//       } else {
//         // Emulator: Use 10.0.2.2
//         socketUrl = 'ws://10.0.2.2:5000';
//       }

//       print('Connecting to WebSocket...');
//       socket = IO.io(socketUrl, {
//         'transports': ['websocket'],
//         'autoConnect': true,
//       });
//       if (!socket.connected) {
//         socket.connect();
//       }

//       socket.on('connect', (_) {
//         print('Connected to WebSocket server');
//         _registerUser();
//         listenForIncomingMessages(); // Call this here only, once connected
//       });

//       socket.on('user_status_updated', (data) {
//         try {
//           print('Received user_status_updated: $data');
//           final updatedUser = data;
//           setState(() {
//             print("setState called in user_status_updated");
//             //loop through users and update the status of the updated user.
//             for (final dynamic u in users) {
//               if (u['id'].toString() == updatedUser['id'].toString()) {
//                 u['status'] = updatedUser['status'];
//                 print('User status updated in users to: ' +
//                     updatedUser['status'].toString());
//                 break;
//               }
//             }
//             //also update filtered users:
//             for (final dynamic u in filteredUsers) {
//               if (u['id'].toString() == updatedUser['id'].toString()) {
//                 u['status'] = updatedUser['status'];
//                 print('User status in filtered users updated to: ' +
//                     updatedUser['status'].toString());
//                 break;
//               }
//             }
//           });
//         } catch (e, stackTrace) {
//           print('Error updating user status UI: $e');
//           setState(() {
//             _errorMessage = "Error updating user status UI: $e";
//           });
//           print('Stack Trace: $stackTrace');
//         }
//       });

//       socket.on('connect_error', (error) {
//         print('WebSocket Error: $error');
//         _attemptReconnect();
//       });

//       socket.on('disconnect', (_) {
//         print('Disconnected from WebSocket server');
//         _attemptReconnect();
//       });
//       socket.on('messages_fetched', (data) {
//         try {
//           setState(() {
//             chatMessages = data != null
//                 ? List<Map<String, dynamic>>.from(data)
//                 : []; //modified here
//             print("setState called in messages_fetched");
//           });
//           print('Fetched messages: $chatMessages');
//           _scrollToBottom();
//         } catch (e, stackTrace) {
//           print('Error processing fetched messages: $e');
//           setState(() {
//             _errorMessage = "Error Processing fetched messages: $e";
//           });
//           print('Stack Trace: $stackTrace');
//         }
//       });
//     } catch (e, stackTrace) {
//       print('Error initializing WebSocket: $e');
//       setState(() {
//         _errorMessage = "Error initializing WebSocket: $e";
//       });
//       print('Stack Trace: $stackTrace');
//       _attemptReconnect();
//     }
//   }

//   void _attemptReconnect() {
//     if (socket != null && !socket.connected) {
//       Future.delayed(Duration(seconds: 5), () {
//         print('Attempting to reconnect...');
//         socket.connect();
//       });
//     }
//   }

//   Future<void> _registerUser() async {
//     try {
//       var box = await Hive.openBox('userBox');
//       final token = box.get('token');

//       if (socket.connected && token != null) {
//         socket.emit('register_user', token);
//         print('Sent register_user with token: $token');
//       } else {
//         print('Socket not connected or no token to send');
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = "Error registering user with socket: $e";
//       });
//       print('Error registering user with socket: $e');
//     }
//   }

//   Future<void> sendMessage(String message) async {
//     var box = await Hive.openBox('userBox');
//     String? senderName = box.get('username'); // Make senderName nullable

//     final messageData = {
//       'sender_id': adminId,
//       'receiver_id': receiverId,
//       'content': message,
//       'message_type': 'Text',
//       'send_time': DateTime.now().toUtc().toIso8601String(),
//       'sender_name': adminName ??
//           ' ', // Use an empty string "" as default, not " " (whitespace)
//     };
//     print('sendMessage: Message data BEFORE emit: $messageData');

//     try {
//       if (socket.connected) {
//         print('sendMessage: WebSocket connected, sending message...');
//         socket.emitWithAck(
//           'send_message',
//           messageData,
//           ack: (response) {
//             print('sendMessage: Ack received: $response');
//             if (response != null && response['status'] == 'success') {
//               if (!mounted) return; // Check if mounted before setting state

//               setState(() {
//                 chatMessages.add(messageData);
//                 print(
//                     'sendMessage: Updated chatMessages after appending new message: $chatMessages');
//                 _scrollToBottom();
//               });
//               _messageController.clear();
//             } else {
//               if (!mounted) return; // Check if mounted before setting state

//               setState(() {
//                 _errorMessage =
//                     "Error Sending Message: ${response?['error'] ?? 'Unknown error'}";
//               });
//               print(
//                   'sendMessage: Ack status was not success: ${response?['error'] ?? 'Unknown error'}');
//             }
//           },
//         );
//       } else {
//         print(
//             'sendMessage: WebSocket not connected, attempting to reconnect...');
//         _attemptReconnect();
//       }
//     } catch (e, stackTrace) {
//       if (!mounted) return; // Check if mounted before setting state

//       setState(() {
//         _errorMessage = "Error sending message: $e";
//       });
//       print('sendMessage: Error sending message: $e');
//       print('sendMessage: Stack Trace: $stackTrace');
//     }
//   }

//   Future<void> fetchChatMessages() async {
//     if (!mounted) return; // Check if mounted before setting state
//     print("Fetching chat messages...");
//     setState(() {
//       isLoading = true;
//       _errorMessage = '';
//     });

//     try {
//       if (socket.connected) {
//         socket.emitWithAck(
//           'fetch_messages',
//           {
//             'sender_id': adminId,
//             'receiver_id': receiverId,
//           },
//           ack: (response) {
//             if (response != null && response['status'] == 'success') {
//               if (!mounted) return; // Check if mounted before setting state

//               setState(() {
//                 chatMessages =
//                     List<Map<String, dynamic>>.from(response['messages'] ?? []);
//                 isLoading = false;
//                 _scrollToBottom();
//               });
//               print(
//                   'fetchChatMessages: Successfully fetched messages: $chatMessages');
//             } else {
//               if (!mounted) return; // Check if mounted before setting state

//               setState(() {
//                 isLoading = false;
//                 _errorMessage =
//                     "Error fetching messages: ${response?['error'] ?? 'Unknown error'}";
//               });
//               print(
//                   'fetchChatMessages: Failed to fetch messages: ${response != null ? response['error'] : 'Unknown error'}');
//             }
//           },
//         );
//       } else {
//         if (!mounted) return; // Check if mounted before setting state

//         setState(() {
//           isLoading = false;
//           _errorMessage = "Websocket disconnected";
//         });
//         print(
//             'fetchChatMessages: WebSocket is not connected. Attempting to reconnect...');
//         _attemptReconnect();
//       }
//     } catch (e, stackTrace) {
//       if (!mounted) return; // Check if mounted before setting state

//       setState(() {
//         isLoading = false;
//         _errorMessage = "Error Fetching Messages: $e";
//       });
//       print('Error fetching messages: $e');
//       print('Stack Trace: $stackTrace');
//     }
//   }

//   Future<void> _showNotification(String title, String body) async {
//     const localNotifications.AndroidNotificationDetails
//         androidNotificationDetails =
//         localNotifications.AndroidNotificationDetails(
//             'chat_channel_id', // use the same channel ID as for FCM messages
//             'Chat Messages',
//             priority: localNotifications.Priority.max,
//             importance: localNotifications.Importance.max);

//     const localNotifications.NotificationDetails notificationDetails =
//         localNotifications.NotificationDetails(
//             android: androidNotificationDetails);

//     await flutterLocalNotificationsPlugin.show(
//         DateTime.now().microsecond, // Unique ID for each notification
//         title,
//         body,
//         notificationDetails);
//   }

//   void _scrollToBottom() {
//     SchedulerBinding.instance!.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
//       }
//     });
//   }

//   Future<Map<String, dynamic>> fetchAdminData(String token) async {
//     final admindata = kIsWeb
//         ? 'http://192.168.88.11:4000/adminRoutes/get-my-info'
//         : 'http://10.0.2.2:4000/adminRoutes/get-my-info';

//     print("admindata is $admindata");

//     final response = await http.post(
//       Uri.parse(admindata),
//       headers: <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//         'Authorization': 'Bearer $token',
//       },
//     );

//     print('Response status: ${response.statusCode}');
//     print('Response body: ${response.body}');

//     if (response.statusCode == 200) {
//       return json.decode(response.body);
//     } else {
//       throw Exception(
//           'Failed to load admin data. Status Code: ${response.statusCode}');
//     }
//   }

//   Future<void> _fetchAdminData() async {
//     try {
//       var box = await Hive.openBox('userBox');
//       final token = box.get('token');

//       if (token == null || token.isEmpty) {
//         Navigator.pushReplacementNamed(context, '/');
//         return;
//       }
//       final data = await fetchAdminData(token);
//       if (!mounted) return; // Check if mounted before setting state

//       setState(() {
//         isLoading = false;
//         adminName = data['user']['username'] ?? 'Admin';
//         adminEmail = data['user']['email'] ?? 'admin@example.com';
//         adminPicUrl = data['user']['profilePic'] ?? '';
//         adminPicUrl = _constructImageUrl(adminPicUrl);
//         print('the pic issssssss : $adminPicUrl');
//         adminId = data['user']['id'].toString() ?? '';
//       });
//     } catch (e) {
//       if (!mounted) return; // Check if mounted before setting state

//       setState(() {
//         isLoading = false;
//         fetchedData = 'Error fetching admin data: $e';
//       });
//     }
//   }

//   String _constructImageUrl(String relativePath) {
//     final String baseUrl;
//     if (kIsWeb) {
//       baseUrl = 'http://192.168.88.11:4000';
//     } else {
//       baseUrl = 'http://10.0.2.2:4000';
//     }
//     print('the pic issssssss :$baseUrl/$relativePath');

//     return '$baseUrl/$relativePath';
//   }

//   Future<void> _fetchUsers() async {
//     try {
//       var box = await Hive.openBox('userBox');
//       final token = box.get('token');

//       if (token == null || token.isEmpty) {
//         Navigator.pushReplacementNamed(context, '/');
//         return;
//       }
//       final List<dynamic> data = await fetchUsers(token);
//       if (!mounted) return; // Check if mounted before setting state
//       setState(() {
//         users = data;
//         filteredUsers = List.from(users);
//         isLoading = false;
//       });
//     } catch (e) {
//       if (!mounted) return; // Check if mounted before setting state

//       setState(() {
//         isLoading = false;
//         _errorMessage = 'Error fetching users: $e';
//       });
//       print('Error: $e');
//     }
//   }

//   Future<List<dynamic>> fetchUsers(String token) async {
//     final userdata = kIsWeb
//         ? 'http://192.168.88.11:4000/adminRoutes/viewAll-users'
//         : 'http://10.0.2.2:4000/adminRoutes/viewAll-users';

//     print("userdata is $userdata");

//     final response = await http.get(
//       Uri.parse(userdata),
//       headers: <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//         'Authorization': 'Bearer $token',
//       },
//     );

//     if (response.statusCode == 200) {
//       return json.decode(response.body) as List<dynamic>;
//     } else {
//       throw Exception(
//           'Failed to load admin data. Status Code: ${response.statusCode}');
//     }
//   }

//   void _onSearchChanged() {
//     String searchTerm = _searchController.text.toLowerCase();
//     if (!mounted) return; // Check if mounted before setting state

//     setState(() {
//       filteredUsers = users.where((user) {
//         return (user['email']?.toLowerCase().contains(searchTerm) ?? false) ||
//             (user['phone_number']?.toLowerCase().contains(searchTerm) ??
//                 false) ||
//             (user['full_name']?.toLowerCase().contains(searchTerm) ?? false) ||
//             (user['membership_number']?.toLowerCase().contains(searchTerm) ??
//                 false) ||
//             (user['judge_number']?.toLowerCase().contains(searchTerm) ??
//                 false) ||
//             (user['id_number']?.toLowerCase().contains(searchTerm) ?? false) ||
//             (user['registration_date']?.toLowerCase().contains(searchTerm) ??
//                 false) ||
//             (user['bio']?.toLowerCase().contains(searchTerm) ?? false);
//       }).toList();
//     });
//   }

//   String _formatDate(String date) {
//     try {
//       final DateTime parsedDate = DateTime.parse(date);
//       final DateTime localTime = parsedDate.toLocal();
//       final DateFormat formatter = DateFormat('hh:mm a');
//       return formatter.format(localTime);
//     } catch (e) {
//       print('Error formatting date: $e');
//       return 'Invalid Date';
//     }
//   }

//   @override
//   void dispose() {
//     _timer.cancel();
//     _searchController.removeListener(_onSearchChanged);
//     _searchController.dispose();
//     _messageController.dispose();
//     _scrollController.dispose();
//     if (socket.connected) {
//       socket.disconnect();
//     }
//     socket.dispose();
//     super.dispose();
//     print('Disposing chat page');
//   }

//   void selectUser(dynamic user) {
//     if (!mounted) return; // Check if mounted before setting state

//     setState(() {
//       selectedUserName = user['username'] ?? 'Unknown';
//       selectedUserPic = _constructImageUrl(user['profile_picture']) ?? '';
//       isUserSelected = true;
//       receiverId = user['id'].toString();
//       chatMessages = [];
//       fetchChatMessages();
//     });
//   }

//   void closeChat() {
//     if (!mounted) return;
//     setState(() {
//       isUserSelected = false;
//       selectedUserName = '';
//       selectedUserPic = '';
//       receiverId = ' ';
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         bool isMobile = constraints.maxWidth < 600;
//         return Scaffold(
//           backgroundColor: whiteColor,
//           appBar: _buildAppBar(isMobile),
//           body: _buildBody(isMobile),
//           floatingActionButton: _buildFloatingActionButton(
//               isMobile), // Only shown on mobile when a user isn't selected
//         );
//       },
//     );
//   }

//   PreferredSizeWidget _buildAppBar(bool isMobile) {
//     return AppBar(
//       backgroundColor: darkBlueColor,
//       title: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           if (!isUserSelected)
//             Padding(
//               padding: const EdgeInsets.only(right: 8.0),
//               child: CircleAvatar(
//                 backgroundImage: adminPicUrl.isNotEmpty
//                     ? NetworkImage(adminPicUrl)
//                     : AssetImage('assets/images/default-profile.png')
//                         as ImageProvider,
//                 radius: isMobile ? 20 : 30,
//               ),
//             ),
//           Text(isUserSelected ? selectedUserName : 'Hello,\n $adminName',
//               style:
//                   TextStyle(fontSize: isMobile ? 18 : 24, color: whiteColor)),
//         ],
//       ),
//       leading: isUserSelected
//           ? IconButton(
//               icon: Icon(
//                 Icons.arrow_back,
//                 color: whiteColor,
//               ),
//               onPressed: () {
//                 if (!mounted) return; // Check if mounted before setting state

//                 setState(() {
//                   isUserSelected = false;
//                   selectedUserName = '';
//                   selectedUserPic = '';
//                   receiverId = ' ';
//                 });
//               },
//             )
//           : null,
//       actions: [
//         if (isUserSelected)
//           Padding(
//             padding: const EdgeInsets.only(left: 10, right: 10),
//             child: Container(
//                 decoration:
//                     BoxDecoration(color: whiteColor, shape: BoxShape.circle),
//                 child: IconButton(
//                     onPressed: () {},
//                     icon: Icon(
//                       Icons.videocam,
//                       color: lightBlueColor,
//                     ))),
//           ),
//         if (isUserSelected)
//           Padding(
//             padding: const EdgeInsets.only(right: 10),
//             child: Container(
//               decoration:
//                   BoxDecoration(color: whiteColor, shape: BoxShape.circle),
//               child: IconButton(
//                   onPressed: () {},
//                   icon: Icon(
//                     Icons.call,
//                     color: lightBlueColor,
//                   )),
//             ),
//           ),
//         if (!isUserSelected) ...[
//           PopupMenuButton<String>(
//             icon: Icon(
//               Icons.more_vert,
//               color: whiteColor,
//             ),
//             onSelected: (String value) {
//               if (value == 'Close Chat') {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) =>
//                         const adminDashboardPage.AdminDashboardPage(),
//                   ),
//                 );
//               }
//             },
//             itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
//               PopupMenuItem<String>(
//                 value: 'Close Chat',
//                 child: ListTile(
//                   leading: Icon(
//                     Icons.exit_to_app,
//                     color: darkBlueColor,
//                   ),
//                   title: Text(
//                     'Close Chat',
//                     style: TextStyle(color: darkBlueColor),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ]
//       ],
//       toolbarHeight: isMobile ? 80 : 100,
//     );
//   }

//   Widget _buildBody(bool isMobile) {
//     return Column(
//       children: [
//         if (!isUserSelected) ...[
//           if (_selectedIndex == 0)
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: TextField(
//                 style: TextStyle(color: darkBlueColor),
//                 controller: _searchController,
//                 decoration: InputDecoration(
//                   hintText: 'Search...',
//                   hintStyle: TextStyle(color: darkBlueColor),
//                   prefixIcon: Icon(
//                     Icons.search,
//                     color: Colors.grey,
//                   ),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(20),
//                     borderSide: BorderSide(color: lightBlueColor),
//                   ),
//                   enabledBorder: OutlineInputBorder(
//                     borderSide: BorderSide(color: Colors.grey.shade800),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderSide: BorderSide(color: lightBlueColor),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                 ),
//                 onChanged: (value) {
//                   _onSearchChanged();
//                 },
//               ),
//             ),
//           Expanded(
//             child: ListView.builder(
//               scrollDirection: Axis.horizontal,
//               itemCount: filteredUsers.length,
//               itemBuilder: (context, index) {
//                 final user = filteredUsers[index];
//                 return GestureDetector(
//                   onTap: () => selectUser(user),
//                   child: Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 8),
//                     child: Column(
//                       children: [
//                         CircleAvatar(
//                           radius: isMobile ? 30 : 40,
//                           backgroundImage: _constructImageUrl(
//                                       user['profile_picture']) !=
//                                   null
//                               ? NetworkImage(
//                                   _constructImageUrl(user['profile_picture']))
//                               : AssetImage('assets/images/default-profile.png')
//                                   as ImageProvider,
//                         ),
//                         SizedBox(height: 5),
//                         Text(
//                           user['username'] ?? 'User',
//                           style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: darkBlueColor),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//         if (isUserSelected) ...[
//           if (_errorMessage.isNotEmpty)
//             Expanded(
//                 child: Center(
//                     child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Text(
//                 _errorMessage,
//                 style: TextStyle(color: Colors.red),
//                 textAlign: TextAlign.center,
//               ),
//             )))
//           else if (isLoading)
//             Expanded(
//               child: Center(
//                 child: CircularProgressIndicator(color: darkBlueColor),
//               ),
//             )
//           else if (chatMessages.isEmpty)
//             Expanded(
//                 child: Center(
//                     child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Text(
//                           "No Messages, Start a Conversation",
//                           style: TextStyle(color: Colors.grey),
//                           textAlign: TextAlign.center,
//                         ))))
//           else
//             Expanded(
//                 child: ListView.builder(
//               controller: _scrollController,
//               itemCount: chatMessages.length,
//               itemBuilder: (context, index) {
//                 final message = chatMessages[index];
//                 final isFromMe =
//                     message['sender_id'].toString() == adminId.toString();

//                 return Align(
//                   alignment:
//                       isFromMe ? Alignment.centerRight : Alignment.centerLeft,
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 8.0, vertical: 4.0),
//                     child: MessageBubble(
//                       text: message['content'] ?? '',
//                       isUser: isFromMe,
//                       attachment: message['message_type'] == 'Attachment',
//                       alignment: isFromMe
//                           ? CrossAxisAlignment.end
//                           : CrossAxisAlignment.start,
//                       time: _formatDate(message['send_time'].toString()),
//                       senderName: adminName ?? '', //modified here
//                     ),
//                   ),
//                 );
//               },
//             )),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: _buildChatInput(isMobile),
//           ),
//         ]
//       ],
//     );
//   }

//   Widget _buildChatInput(bool isMobile) {
//     return Container(
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: darkBlueColor,
//         borderRadius: BorderRadius.circular(25.0),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.2),
//             spreadRadius: 1,
//             blurRadius: 3,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           IconButton(
//               onPressed: () {},
//               icon: const Icon(
//                 Icons.mic,
//                 color: whiteColor,
//               )),
//           Expanded(
//               child: TextField(
//                   style: TextStyle(color: whiteColor),
//                   controller: _messageController,
//                   decoration: InputDecoration(
//                       hintText: 'Type your message...',
//                       hintStyle: TextStyle(color: Colors.grey),
//                       border: InputBorder.none))),
//           IconButton(
//               onPressed: () {
//                 final message = _messageController.text;
//                 if (message.isNotEmpty) {
//                   sendMessage(message);
//                 }
//               },
//               icon: const Icon(
//                 Icons.send,
//                 color: whiteColor,
//               ))
//         ],
//       ),
//     );
//   }

//   Widget? _buildFloatingActionButton(bool isMobile) {
//     return !isUserSelected && isMobile && _selectedIndex == 0
//         ? FloatingActionButton(
//             onPressed: () {
//               // Implement action when

//               // Implement action when starting a new chat
//             },
//             backgroundColor: darkBlueColor,
//             child: const Icon(
//               Icons.chat_bubble_outline,
//               color: whiteColor,
//             ),
//           )
//         : null;
//   }
// }

// class MessageBubble extends StatelessWidget {
//   final String text;
//   final bool isUser;
//   final CrossAxisAlignment alignment;
//   final bool attachment;
//   final String time;
//   final String senderName; //modified here

//   const MessageBubble({
//     super.key,
//     required this.text,
//     this.isUser = false,
//     this.alignment = CrossAxisAlignment.start,
//     this.attachment = false,
//     required this.time,
//     this.senderName = '', //modified here
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Column(
//         crossAxisAlignment: alignment,
//         children: [
//           if (attachment)
//             _buildAttachment()
//           else
//             CustomPaint(
//               painter: ChatBubblePainter(
//                   isUser: isUser,
//                   color: isUser ? darkBlueColor : otherBubbleColor),
//               child: Container(
//                 padding: const EdgeInsets.all(10),
//                 child: Column(
//                   crossAxisAlignment: isUser
//                       ? CrossAxisAlignment.end
//                       : CrossAxisAlignment.start,
//                   children: [
//                     if (!isUser)
//                       Text(senderName,
//                           style: TextStyle(
//                               fontSize: 12, color: Colors.grey)), //added here
//                     Text(text,
//                         style: TextStyle(
//                             color: isUser ? whiteColor : Colors.black)),
//                     Row(mainAxisSize: MainAxisSize.min, children: [
//                       Text(
//                         time,
//                         style: TextStyle(fontSize: 12, color: Colors.grey),
//                       ),
//                       if (isUser) // Example: show 'sent' icon if from me.
//                         Icon(
//                           Icons.done_all,
//                           size: 14,
//                           color: Colors.grey,
//                         )
//                     ])
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAttachment() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(8),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(Icons.file_present_outlined),
//             const SizedBox(
//               width: 4,
//             ),
//             Text(text),
//             const SizedBox(
//               width: 4,
//             ),
//             const Icon(Icons.download),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class ChatBubblePainter extends CustomPainter {
//   final bool isUser;
//   final Color color;

//   ChatBubblePainter({required this.isUser, required this.color});
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..color = color;
//     final path = Path();
//     final borderRadius = 20.0;

//     if (isUser) {
//       path.moveTo(0, size.height);
//       path.lineTo(size.width - borderRadius, size.height);
//       path.quadraticBezierTo(
//           size.width, size.height, size.width, size.height - borderRadius);
//       path.lineTo(size.width, borderRadius);
//       path.quadraticBezierTo(size.width, 0, size.width - borderRadius, 0);
//       path.lineTo(borderRadius, 0);
//       path.quadraticBezierTo(0, 0, 0, borderRadius);
//     } else {
//       path.moveTo(borderRadius, size.height);
//       path.lineTo(size.width, size.height);
//       path.lineTo(size.width, size.height - borderRadius);
//       path.quadraticBezierTo(size.width, 0, size.width - borderRadius, 0);
//       path.lineTo(borderRadius, 0);
//       path.quadraticBezierTo(0, 0, 0, borderRadius);
//       path.lineTo(0, size.height - borderRadius);
//       path.quadraticBezierTo(0, size.height, borderRadius, size.height);
//     }

//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return false;
//   }
// }

// late IO.Socket socket;
// bool isLoading = true;
// String fetchedData = '';
// late Timer _timer;
// List<dynamic> filteredUsers = [];
// List<dynamic> users = [];
// String adminName = 'Admin';
// String adminEmail = 'admin@example.com';
// String adminPicUrl = '';
// String adminId = '';
// bool isUserSelected = false;
// String selectedUserName = '';
// String selectedUserPic = '';
// String receiverId = '';
// final ScrollController _scrollController = ScrollController();
// List<Map<String, dynamic>> chatMessages = []; //change this line
// late TextEditingController _messageController = TextEditingController();
// late TextEditingController _searchController = TextEditingController();
// String _errorMessage = '';
// int _selectedIndex = 0;

// @override
// void initState() {
//   super.initState();
//   print('Initializing chat page');
//   _timer = Timer.periodic(Duration(seconds: 30), (timer) {
//     TokenUtils.checkTokenExpiration(context);
//   });
//   _fetchAdminData();
//   _fetchUsers();
//   _initializeWebSocket();
//   _searchController.addListener(_onSearchChanged);
//   WidgetsBinding.instance!.addPostFrameCallback((_) {
//     if (isUserSelected) {
//       _scrollToBottom();
//     }
//   });
// }

// @override
// void didChangeDependencies() {
//   super.didChangeDependencies();
// }

// void listenForIncomingMessages() {
//   try {
//     if (!socket.hasListeners('receive_message')) {
//       socket.on('receive_message', (data) {
//         print('Received message: $data'); // Log when the message is received
//         try {
//           final decodedData = jsonDecode(data);
//           print(
//               'listenForIncomingMessages: Decoded message: $decodedData'); // Log decoded message
//           print(
//               "setState called in receive_message"); // Log if setState is called

//           setState(() {
//             if (decodedData['sender_id'].toString() == receiverId ||
//                 decodedData['sender_id'].toString() == adminId) {
//               // Modified here to include sender_name
//               chatMessages.add(decodedData);
//               print(
//                   'listenForIncomingMessages: Updated chatMessages after appending new message: $chatMessages');
//               _scrollToBottom();
//             } else {
//               // Update message also if the user is not selected but message belongs to logged in admin
//               if (decodedData['receiver_id'].toString() ==
//                   adminId.toString()) {
//                 print(
//                     'listenForIncomingMessages: Received message from user ${decodedData['sender_id']} and is not for current user. Updating message list and selecting the user.');

//                 _showNotification(
//                   decodedData['sender_name'] ??
//                       "New Message", // modified here
//                   decodedData['content'] ?? "",
//                 );

//                 // find the user and select user if it is not already selected.
//                 dynamic user;
//                 for (final dynamic u in users) {
//                   if (u['id'].toString() ==
//                       decodedData['sender_id'].toString()) {
//                     user = u;
//                     break;
//                   }
//                 }

//                 if (user != null) {
//                   print(
//                       'listenForIncomingMessages: Calling selectUser for user: ${user['username']}');
//                   selectUser(user);
//                   print(
//                       'listenForIncomingMessages: After selectUser was called for user: ${user['username']}');
//                 } else {
//                   print("User not found. Ignoring message");
//                 }
//               } else {
//                 print(
//                     'listenForIncomingMessages: Message not for selected user and logged in admin, Ignoring it.');
//                 print("DecodedData is " +
//                     decodedData.toString() +
//                     " and receiverId is: " +
//                     receiverId +
//                     " and adminId is: " +
//                     adminId);
//               }
//             }
//           });
//         } catch (e) {
//           setState(() {
//             _errorMessage = "Error decoding incoming message: $e";
//           });
//           print('listenForIncomingMessages: Error decoding message: $e');
//         }
//       });
//     }
//   } catch (e, stackTrace) {
//     setState(() {
//       _errorMessage = "Error listening for incoming messages: $e";
//     });
//     print(
//         'listenForIncomingMessages: Error listening for incoming messages: $e');
//     print('listenForIncomingMessages: Stack Trace: $stackTrace');
//   }
// }

// Future<void> _sendTokenToServer(
//     String token, String userId, String authToken) async {
//   final userdata = kIsWeb
//       ? 'http://192.168.88.10:4000/adminRoutes/update-my-info' // For Web (Chrome)
//       : 'http://10.0.2.2:4000/adminRoutes/update-my-info'; // For Android Emulator
//   print("Sending token to api $userdata ");
//   try {
//     final response = await http.post(
//       Uri.parse(userdata),
//       headers: <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//         'Authorization': 'Bearer $authToken',
//       },
//       body: jsonEncode({
//         'fcmToken': token,
//       }),
//     );
//     print("Response: ${response.statusCode} body: ${response.body}");
//   } catch (e) {
//     print('Error sending token to backend: $e');
//   }
// }

// Future<void> _getFCMToken() async {
//   try {
//     var box = await Hive.openBox('userBox');
//     final token = box.get('token');
//     if (token != null) {
//       final userId = box.get('id');
//       final tokenToSend = box.get('token');
//       await _sendTokenToServer(token, userId, tokenToSend);
//     }
//   } catch (e) {
//     print('Error getting token: $e');
//   }
// }

// void _initializeWebSocket() {
//   try {
//     print('Connecting to WebSocket...');

//     final String socketUrl;
//     if (kIsWeb) {
//       // Web: Use machine's IP address
//       socketUrl = 'ws://192.168.88.10:5000';
//     } else {
//       // Emulator: Use 10.0.2.2
//       socketUrl = 'ws://10.0.2.2:5000';
//     }

//     print('Connecting to WebSocket...');
//     socket = IO.io(socketUrl, {
//       'transports': ['websocket'],
//       'autoConnect': true,
//     });
//     if (!socket.connected) {
//       socket.connect();
//     }

//     socket.on('connect', (_) {
//       print('Connected to WebSocket server');
//       _registerUser();
//       listenForIncomingMessages(); // Call this here only, once connected
//     });

//     socket.on('user_status_updated', (data) {
//       try {
//         print('Received user_status_updated: $data');
//         final updatedUser = data;
//         setState(() {
//           print("setState called in user_status_updated");
//           //loop through users and update the status of the updated user.
//           for (final dynamic u in users) {
//             if (u['id'].toString() == updatedUser['id'].toString()) {
//               u['status'] = updatedUser['status'];
//               print('User status updated in users to: ' +
//                   updatedUser['status'].toString());
//               break;
//             }
//           }
//           //also update filtered users:
//           for (final dynamic u in filteredUsers) {
//             if (u['id'].toString() == updatedUser['id'].toString()) {
//               u['status'] = updatedUser['status'];
//               print('User status in filtered users updated to: ' +
//                   updatedUser['status'].toString());
//               break;
//             }
//           }
//         });
//       } catch (e, stackTrace) {
//         print('Error updating user status UI: $e');
//         setState(() {
//           _errorMessage = "Error updating user status UI: $e";
//         });
//         print('Stack Trace: $stackTrace');
//       }
//     });

//     socket.on('connect_error', (error) {
//       print('WebSocket Error: $error');
//       _attemptReconnect();
//     });

//     socket.on('disconnect', (_) {
//       print('Disconnected from WebSocket server');
//       _attemptReconnect();
//     });
//     socket.on('messages_fetched', (data) {
//       try {
//         setState(() {
//           chatMessages = data != null
//               ? List<Map<String, dynamic>>.from(data)
//               : []; //modified here
//           print("setState called in messages_fetched");
//         });
//         print('Fetched messages: $chatMessages');
//         _scrollToBottom();
//       } catch (e, stackTrace) {
//         print('Error processing fetched messages: $e');
//         setState(() {
//           _errorMessage = "Error Processing fetched messages: $e";
//         });
//         print('Stack Trace: $stackTrace');
//       }
//     });
//   } catch (e, stackTrace) {
//     print('Error initializing WebSocket: $e');
//     setState(() {
//       _errorMessage = "Error initializing WebSocket: $e";
//     });
//     print('Stack Trace: $stackTrace');
//     _attemptReconnect();
//   }
// }

// void _showNotification(String title, String body) async {
//        if(_navigatorKey.currentContext != null) {
//           _showNotification(_navigatorKey.currentContext!, title, body);
//       }
//     }
// void _attemptReconnect() {
//   if (socket != null && !socket.connected) {
//     Future.delayed(Duration(seconds: 5), () {
//       print('Attempting to reconnect...');
//       socket.connect();
//     });
//   }
// }

// Future<void> _registerUser() async {
//   try {
//     var box = await Hive.openBox('userBox');
//     final token = box.get('token');

//     if (socket.connected && token != null) {
//       socket.emit('register_user', token);
//       print('Sent register_user with token: $token');
//     } else {
//       print('Socket not connected or no token to send');
//     }
//   } catch (e) {
//     setState(() {
//       _errorMessage = "Error registering user with socket: $e";
//     });
//     print('Error registering user with socket: $e');
//   }
// }

// Future<void> sendMessage(String message) async {
//   var box = await Hive.openBox('userBox');
//   String? senderName = box.get('username'); // Make senderName nullable

//   final messageData = {
//     'sender_id': adminId,
//     'receiver_id': receiverId,
//     'content': message,
//     'message_type': 'Text',
//     'send_time': DateTime.now().toUtc().toIso8601String(),
//     'sender_name': adminName ??
//         ' ', // Use an empty string "" as default, not " " (whitespace)
//   };
//   print('sendMessage: Message data BEFORE emit: $messageData');

//   try {
//     if (socket.connected) {
//       print('sendMessage: WebSocket connected, sending message...');
//       socket.emitWithAck(
//         'send_message',
//         messageData,
//         ack: (response) {
//           print('sendMessage: Ack received: $response');
//           if (response != null && response['status'] == 'success') {
//             if (!mounted) return; // Check if mounted before setting state

//             setState(() {
//               chatMessages.add(messageData);
//               print(
//                   'sendMessage: Updated chatMessages after appending new message: $chatMessages');
//               _scrollToBottom();
//             });
//             _messageController.clear();
//           } else {
//             if (!mounted) return; // Check if mounted before setting state

//             setState(() {
//               _errorMessage =
//                   "Error Sending Message: ${response?['error'] ?? 'Unknown error'}";
//             });
//             print(
//                 'sendMessage: Ack status was not success: ${response?['error'] ?? 'Unknown error'}');
//           }
//         },
//       );
//     } else {
//       print(
//           'sendMessage: WebSocket not connected, attempting to reconnect...');
//       _attemptReconnect();
//     }
//   } catch (e, stackTrace) {
//     if (!mounted) return; // Check if mounted before setting state

//     setState(() {
//       _errorMessage = "Error sending message: $e";
//     });
//     print('sendMessage: Error sending message: $e');
//     print('sendMessage: Stack Trace: $stackTrace');
//   }
// }

// Future<void> fetchChatMessages() async {
//   if (!mounted) return; // Check if mounted before setting state
//   print("Fetching chat messages...");
//   setState(() {
//     isLoading = true;
//     _errorMessage = '';
//   });

//   try {
//     if (socket.connected) {
//       socket.emitWithAck(
//         'fetch_messages',
//         {
//           'sender_id': adminId,
//           'receiver_id': receiverId,
//         },
//         ack: (response) {
//           if (response != null && response['status'] == 'success') {
//             if (!mounted) return; // Check if mounted before setting state

//             setState(() {
//               chatMessages =
//                   List<Map<String, dynamic>>.from(response['messages'] ?? []);
//               isLoading = false;
//               _scrollToBottom();
//             });
//             print(
//                 'fetchChatMessages: Successfully fetched messages: $chatMessages');
//           } else {
//             if (!mounted) return; // Check if mounted before setting state

//             setState(() {
//               isLoading = false;
//               _errorMessage =
//                   "Error fetching messages: ${response?['error'] ?? 'Unknown error'}";
//             });
//             print(
//                 'fetchChatMessages: Failed to fetch messages: ${response != null ? response['error'] : 'Unknown error'}');
//           }
//         },
//       );
//     } else {
//       if (!mounted) return; // Check if mounted before setting state

//       setState(() {
//         isLoading = false;
//         _errorMessage = "Websocket disconnected";
//       });
//       print(
//           'fetchChatMessages: WebSocket is not connected. Attempting to reconnect...');
//       _attemptReconnect();
//     }
//   } catch (e, stackTrace) {
//     if (!mounted) return; // Check if mounted before setting state

//     setState(() {
//       isLoading = false;
//       _errorMessage = "Error Fetching Messages: $e";
//     });
//     print('Error fetching messages: $e');
//     print('Stack Trace: $stackTrace');
//   }
// }

// void _scrollToBottom() {
//   SchedulerBinding.instance!.addPostFrameCallback((_) {
//     if (_scrollController.hasClients) {
//       _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
//     }
//   });
// }

// Future<Map<String, dynamic>> fetchAdminData(String token) async {
//   final admindata = kIsWeb
//       ? 'http://192.168.88.10:4000/adminRoutes/get-my-info'
//       : 'http://10.0.2.2:4000/adminRoutes/get-my-info';

//   print("admindata is $admindata");

//   final response = await http.post(
//     Uri.parse(admindata),
//     headers: <String, String>{
//       'Content-Type': 'application/json; charset=UTF-8',
//       'Authorization': 'Bearer $token',
//     },
//   );

//   print('Response status: ${response.statusCode}');
//   print('Response body: ${response.body}');

//   if (response.statusCode == 200) {
//     return json.decode(response.body);
//   } else {
//     throw Exception(
//         'Failed to load admin data. Status Code: ${response.statusCode}');
//   }
// }

// Future<void> _fetchAdminData() async {
//   try {
//     var box = await Hive.openBox('userBox');
//     final token = box.get('token');

//     if (token == null || token.isEmpty) {
//       Navigator.pushReplacementNamed(context, '/');
//       return;
//     }
//     final data = await fetchAdminData(token);
//     if (!mounted) return; // Check if mounted before setting state

//     setState(() {
//       isLoading = false;
//       adminName = data['user']['username'] ?? 'Admin';
//       adminEmail = data['user']['email'] ?? 'admin@example.com';
//       adminPicUrl = data['user']['profilePic'] ?? '';
//       adminPicUrl = _constructImageUrl(adminPicUrl);
//       print('the pic issssssss : $adminPicUrl');
//       adminId = data['user']['id'].toString() ?? '';
//     });
//   } catch (e) {
//     if (!mounted) return; // Check if mounted before setting state

//     setState(() {
//       isLoading = false;
//       fetchedData = 'Error fetching admin data: $e';
//     });
//   }
// }

// String _constructImageUrl(String relativePath) {
//   final String baseUrl;
//   if (kIsWeb) {
//     baseUrl = 'http://192.168.88.10:4000';
//   } else {
//     baseUrl = 'http://10.0.2.2:4000';
//   }
//   print('the pic issssssss :$baseUrl/$relativePath');

//   return '$baseUrl/$relativePath';
// }

// Future<void> _fetchUsers() async {
//   try {
//     var box = await Hive.openBox('userBox');
//     final token = box.get('token');

//     if (token == null || token.isEmpty) {
//       Navigator.pushReplacementNamed(context, '/');
//       return;
//     }
//     final List<dynamic> data = await fetchUsers(token);
//     if (!mounted) return; // Check if mounted before setting state

//     setState(() {
//       users = data;
//       filteredUsers = List.from(users);
//       isLoading = false;
//     });
//   } catch (e) {
//     if (!mounted) return; // Check if mounted before setting state

//     setState(() {
//       isLoading = false;
//       _errorMessage = 'Error fetching users: $e';
//     });
//     print('Error: $e');
//   }
// }

// Future<List<dynamic>> fetchUsers(String token) async {
//   final userdata = kIsWeb
//       ? 'http://192.168.88.10:4000/adminRoutes/viewAll-users'
//       : 'http://10.0.2.2:4000/adminRoutes/viewAll-users';

//   print("userdata is $userdata");

//   final response = await http.get(
//     Uri.parse(userdata),
//     headers: <String, String>{
//       'Content-Type': 'application/json; charset=UTF-8',
//       'Authorization': 'Bearer $token',
//     },
//   );

//   if (response.statusCode == 200) {
//     return json.decode(response.body) as List<dynamic>;
//   } else {
//     throw Exception(
//         'Failed to load admin data. Status Code: ${response.statusCode}');
//   }
// }

// void _onSearchChanged() {
//   String searchTerm = _searchController.text.toLowerCase();
//   if (!mounted) return; // Check if mounted before setting state

//   setState(() {
//     filteredUsers = users.where((user) {
//       return (user['email']?.toLowerCase().contains(searchTerm) ?? false) ||
//           (user['phone_number']?.toLowerCase().contains(searchTerm) ??
//               false) ||
//           (user['full_name']?.toLowerCase().contains(searchTerm) ?? false) ||
//           (user['membership_number']?.toLowerCase().contains(searchTerm) ??
//               false) ||
//           (user['judge_number']?.toLowerCase().contains(searchTerm) ??
//               false) ||
//           (user['id_number']?.toLowerCase().contains(searchTerm) ?? false) ||
//           (user['registration_date']?.toLowerCase().contains(searchTerm) ??
//               false) ||
//           (user['bio']?.toLowerCase().contains(searchTerm) ?? false);
//     }).toList();
//   });
// }

// String _formatDate(String date) {
//   try {
//     final DateTime parsedDate = DateTime.parse(date);
//     final DateTime localTime = parsedDate.toLocal();
//     final DateFormat formatter = DateFormat('hh:mm a');
//     return formatter.format(localTime);
//   } catch (e) {
//     print('Error formatting date: $e');
//     return 'Invalid Date';
//   }
// }

// @override
// void dispose() {
//   _timer.cancel();
//   _searchController.removeListener(_onSearchChanged);
//   _searchController.dispose();
//   _messageController.dispose();
//   _scrollController.dispose();
//   if (socket.connected) {
//     socket.disconnect();
//   }
//   socket.dispose();
//   super.dispose();
//   print('Disposing chat page');
// }

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import 'package:firstproj/Pages/TokenUtils.dart';
import 'package:firstproj/Pages/AdminDashboardPage.dart' as adminDashboardPage;
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; //Import RemoteMessage
import 'package:firstproj/main.dart';

const Color darkBlueColor = Color(0xFF0F3460);
const Color darkBackgroundColor = Color(0xFF1A202C);
const Color lightBlueColor = Color(0xFFADD8E6);
const Color whiteColor = Colors.white;
const Color userBubbleColor = Color(0xFF6750A4);
const Color otherBubbleColor = Color(0xFFD3D3D3);

class ChatPage extends StatefulWidget {
  ChatPage({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatPage> {
  late IO.Socket socket;
  bool isLoading = true;
  String fetchedData = '';
  late Timer _timer;
  List<dynamic> filteredUsers = [];
  List<dynamic> users = [];
  String adminName = 'Admin';
  String adminEmail = 'admin@example.com';
  String adminPicUrl = '';
  String adminId = '';
  bool isUserSelected = false;
  String selectedUserName = '';
  String selectedUserPic = '';
  String receiverId = '';
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> chatMessages = []; //change this line
  late TextEditingController _messageController = TextEditingController();
  late TextEditingController _searchController = TextEditingController();
  String _errorMessage = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    print('Initializing chat page');
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      TokenUtils.checkTokenExpiration(context);
    });
    _fetchAdminData();
    _fetchUsers();
    _initializeWebSocket();
    _getFCMToken();

    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      if (isUserSelected) {
        _scrollToBottom();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void listenForIncomingMessages() {
    try {
      if (!socket.hasListeners('receive_message')) {
        socket.on('receive_message', (data) {
          print('Received message: $data'); // Log when the message is received
          try {
            if (data is String) {
              print("received data: " + data.toString());
              final decodedData = jsonDecode(data.toString());
              print(
                  'listenForIncomingMessages: Decoded message: $decodedData'); // Log decoded message
              print(
                  "setState called in receive_message"); // Log if setState is called
              print(
                  'listenForIncomingMessages: receiverId: $receiverId, adminId: $adminId, sender_id ${decodedData['sender_id']}, receiver_id ${decodedData['receiver_id']}');
              setState(() {
                if (decodedData['sender_id'].toString() == receiverId ||
                    decodedData['sender_id'].toString() == adminId) {
                  // If message is for current user or admin.
                  chatMessages.add(decodedData);
                  print(
                      'listenForIncomingMessages: Updated chatMessages after appending new message: $chatMessages');
                  _showNotification(
                    context, // Use the context here
                    decodedData['sender_name'] ??
                        "New Message", // modified here
                    decodedData['content'] ?? "",
                  );

                  _scrollToBottom();
                }
                //Update message also if the user is not selected but message belongs to logged in admin
                else if (decodedData['receiver_id'].toString() ==
                    adminId.toString()) {
                  print(
                      'listenForIncomingMessages: Received message from user ${decodedData['sender_id']} and is not for current user. Updating message list and selecting the user.');

                  print(
                      'jewbsdjfbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb');
                  _showNotification(
                    context, // Use the context here
                    decodedData['sender_name'] ??
                        "New Message", // modified here
                    decodedData['content'] ?? "",
                  );

                  // find the user and select user if it is not already selected.
                  final user = users.firstWhere(
                      (u) =>
                          u['id'].toString() ==
                          decodedData['sender_id'].toString(),
                      orElse: () => null);

                  if (user != null) {
                    print(
                        'listenForIncomingMessages: Calling selectUser for user: ${user['username']}');
                    selectUser(user);
                    print(
                        'listenForIncomingMessages: After selectUser was called for user: ${user['username']}');
                  } else {
                    print("User not found. Ignoring message");
                  }
                } else {
                  print(
                      'listenForIncomingMessages: Message not for selected user and logged in admin, Ignoring it.');
                  print("DecodedData is " +
                      decodedData.toString() +
                      " and receiverId is: " +
                      receiverId +
                      " and adminId is: " +
                      adminId);
                }
              });
            } else {
              setState(() {
                _errorMessage = "Invalid string received: $data";
              });
              print(
                  'listenForIncomingMessages: Invalid string received: $data');
            }
          } on FormatException catch (e) {
            setState(() {
              _errorMessage =
                  "Format Exception: Error decoding incoming message: $e";
            });
            print(
                'listenForIncomingMessages: FormatException Error decoding message: $e');
          } catch (e) {
            setState(() {
              _errorMessage = "Error decoding incoming message: $e";
            });
            print('listenForIncomingMessages: Error decoding message: $e');
          }
        });
      }
    } catch (e, stackTrace) {
      setState(() {
        _errorMessage = "Error listening for incoming messages: $e";
      });
      print(
          'listenForIncomingMessages: Error listening for incoming messages: $e');
      print('listenForIncomingMessages: Stack Trace: $stackTrace');
    }
  }

  void _showNotification(
      BuildContext context, String title, String body) async {
    print(
        '_showNotification called with title: $title, body: $body, context: $context');
    // Create a dummy message to use for dialog
    RemoteMessage dummyMessage = RemoteMessage(
        notification: RemoteNotification(title: title, body: body));

    _firebaseMessagingForegroundHandler(dummyMessage, context);
  }

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // This is where all messages are going to be handled
  Future<void> _firebaseMessagingForegroundHandler(
      RemoteMessage message, BuildContext context) async {
    print('_firebaseMessagingForegroundHandler called, context: $context');
    if (context != null) {
      print(
          ' _firebaseMessagingForegroundHandler: context is available, calling show foreground dialog');
      showForegroundDialog(context, message);
    } else {
      print(
          '_firebaseMessagingForegroundHandler: context is not available, adding to the queue');
    }
  }

  void showForegroundDialog(BuildContext context, RemoteMessage message) {
    print("showDialog called, message.notification: ${message.notification}");
    // showDialog(
    //   context: context,
    //   builder: (context) => AlertDialog(
    //     title: Text(message.notification?.title ?? 'Notification'),
    //     content: Text(message.notification?.body ?? 'New Message'),
    //     actions: [
    //       TextButton(
    //         onPressed: () => Navigator.pop(context),
    //         child: const Text('Close'),
    //       ),
    //     ],
    //   ),
    // );
    // OverlayEntry? overlayEntry;

    // overlayEntry = OverlayEntry(
    //   builder: (context) => Positioned(
    //     top: 50,
    //     left: 20,
    //     right: 20,
    //     child: Material(
    //       color: Colors.transparent,
    //       child: Container(
    //         padding: const EdgeInsets.all(16),
    //         decoration: BoxDecoration(
    //           color: Colors.grey[300],
    //           borderRadius: BorderRadius.circular(10),
    //           border: Border.all(color: Colors.grey.shade400, width: 1.0),
    //         ),
    //         child: Column(
    //           mainAxisSize: MainAxisSize.min,
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: [
    //             Row(
    //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //               children: [
    //                 Row(
    //                   children: [
    //                     Container(
    //                       padding: const EdgeInsets.all(2.0),
    //                       decoration: BoxDecoration(
    //                           color: Colors.blue,
    //                           borderRadius: BorderRadius.circular(2.0)),
    //                       child: const Text(
    //                         "On",
    //                         style:
    //                             TextStyle(color: Colors.white, fontSize: 14.0),
    //                       ),
    //                     ),
    //                     const SizedBox(width: 8),
    //                     const Text(
    //                       "ONSHAPE",
    //                       style: TextStyle(
    //                           fontWeight: FontWeight.w500,
    //                           fontSize: 15.0,
    //                           color: Colors.black87),
    //                     ),
    //                   ],
    //                 ),
    //                 Text(
    //                   '${DateTime.now().hour}:${DateTime.now().minute} ',
    //                   style: const TextStyle(
    //                       fontSize: 13.0, color: Colors.black87),
    //                 )
    //               ],
    //             ),
    //             const SizedBox(height: 8),
    //             Text(
    //               message.notification?.body ?? '',
    //               style: const TextStyle(fontSize: 16, color: Colors.black87),
    //             ),
    //           ],
    //         ),
    //       ),
    //     ),
    //   ),
    // );
    // Overlay.of(context).insert(overlayEntry);

    // Future.delayed(const Duration(seconds: 5), () {
    //   overlayEntry?.remove();
    // });

    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade400, width: 1.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.0),
                          decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(2.0)),
                          child: const Icon(
                            Icons.notifications,
                            size: 14.0,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          adminName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15.0,
                              color: Colors.black87),
                        ),
                      ],
                    ),
                    Text(
                      '${DateTime.now().hour}:${DateTime.now().minute} ',
                      style: const TextStyle(
                          fontSize: 13.0, color: Colors.black87),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message.notification?.body ?? '',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(overlayEntry);

    Future.delayed(const Duration(seconds: 5), () {
      overlayEntry?.remove();
    });
  }

  Future<void> _sendTokenToServer(
      String token, String userId, String authToken) async {
    final userdata = kIsWeb
        ? 'http://192.168.88.4:4000/adminRoutes/update-fcm-token'
        : 'http://10.0.2.2:4000/adminRoutes/update-fcm-token';
    print("Sending token to api $userdata with userId: $adminId");
    try {
      final response = await http.post(
        Uri.parse(userdata),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'fcmToken': token,
          'userId': adminId, // Include userId in request body
        }),
      );
      print("Response: ${response.statusCode} body: ${response.body}");
    } catch (e) {
      print('Error sending token to backend: $e');
    }
  }

  Future<void> _getFCMToken() async {
    try {
      var box = await Hive.openBox('userBox');
      final fcm = await FirebaseMessaging.instance.getToken();
      if (fcm != null) {
        final tokenToSend = box.get('token');
        await _sendTokenToServer(fcm, adminId, tokenToSend);
      }
    } catch (e) {
      print('Error getting token: $e');
    }
  }

  void _initializeWebSocket() {
    try {
      print('Connecting to WebSocket...');

      final String socketUrl;
      if (kIsWeb) {
        // Web: Use machine's IP address
        socketUrl = 'ws://192.168.88.4:5000';
      } else {
        // Emulator: Use 10.0.2.2
        socketUrl = 'ws://10.0.2.2:5000';
      }

      print('Connecting to WebSocket...');
      socket = IO.io(socketUrl, {
        'transports': ['websocket'],
        'autoConnect': true,
      });
      if (!socket.connected) {
        socket.connect();
      }

      socket.on('connect', (_) {
        print('Connected to WebSocket server');
        _registerUser();
        listenForIncomingMessages(); // Call this here only, once connected
      });

      socket.on('user_status_updated', (data) {
        try {
          print('Received user_status_updated: $data');
          final updatedUser = data;
          setState(() {
            print("setState called in user_status_updated");
            //loop through users and update the status of the updated user.
            for (final dynamic u in users) {
              if (u['id'].toString() == updatedUser['id'].toString()) {
                u['status'] = updatedUser['status'];
                print('User status updated in users to: ' +
                    updatedUser['status'].toString());
                break;
              }
            }
            //also update filtered users:
            for (final dynamic u in filteredUsers) {
              if (u['id'].toString() == updatedUser['id'].toString()) {
                u['status'] = updatedUser['status'];
                print('User status in filtered users updated to: ' +
                    updatedUser['status'].toString());
                break;
              }
            }
          });
        } catch (e, stackTrace) {
          print('Error updating user status UI: $e');
          setState(() {
            _errorMessage = "Error updating user status UI: $e";
          });
          print('Stack Trace: $stackTrace');
        }
      });

      socket.on('connect_error', (error) {
        print('WebSocket Error: $error');
        _attemptReconnect();
      });

      socket.on('disconnect', (_) {
        print('Disconnected from WebSocket server');
        _attemptReconnect();
      });
      socket.on('messages_fetched', (data) {
        try {
          setState(() {
            chatMessages = data != null
                ? List<Map<String, dynamic>>.from(data)
                : []; //modified here
            print("setState called in messages_fetched");
          });
          print('Fetched messages: $chatMessages');
          _scrollToBottom();
        } catch (e, stackTrace) {
          print('Error processing fetched messages: $e');
          setState(() {
            _errorMessage = "Error Processing fetched messages: $e";
          });
          print('Stack Trace: $stackTrace');
        }
      });
    } catch (e, stackTrace) {
      print('Error initializing WebSocket: $e');
      setState(() {
        _errorMessage = "Error initializing WebSocket: $e";
      });
      print('Stack Trace: $stackTrace');
      _attemptReconnect();
    }
  }

  // void _showNotification(String title, String body) async {
  //   if (_navigatorKey.currentContext != null) {
  //     _showNotification(_navigatorKey.currentContext!, title, body);
  //   }
  // }

  void _attemptReconnect() {
    if (socket != null && !socket.connected) {
      Future.delayed(Duration(seconds: 5), () {
        print('Attempting to reconnect...');
        socket.connect();
      });
    }
  }

  Future<void> _registerUser() async {
    try {
      var box = await Hive.openBox('userBox');
      final token = box.get('token');

      if (socket.connected && token != null) {
        socket.emit('register_user', token);
        print('Sent register_user with token: $token');
      } else {
        print('Socket not connected or no token to send');
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error registering user with socket: $e";
      });
      print('Error registering user with socket: $e');
    }
  }

  Future<void> sendMessage(String message) async {
    var box = await Hive.openBox('userBox');
    String? senderName = box.get('username'); // Make senderName nullable

    final messageData = {
      'sender_id': adminId,
      'receiver_id': receiverId,
      'content': message,
      'message_type': 'Text',
      'send_time': DateTime.now().toUtc().toIso8601String(),
      'sender_name': adminName ??
          ' ', // Use an empty string "" as default, not " " (whitespace)
    };
    print('sendMessage: Message data BEFORE emit: $messageData');

    try {
      if (socket.connected) {
        print('sendMessage: WebSocket connected, sending message...');
        socket.emitWithAck(
          'send_message',
          messageData,
          ack: (response) {
            print('sendMessage: Ack received: $response');
            if (response != null && response['status'] == 'success') {
              if (!mounted) return; // Check if mounted before setting state

              setState(() {
                chatMessages.add(messageData);
                print(
                    'sendMessage: Updated chatMessages after appending new message: $chatMessages');
                _scrollToBottom();
              });
              _messageController.clear();
            } else {
              if (!mounted) return; // Check if mounted before setting state

              setState(() {
                _errorMessage =
                    "Error Sending Message: ${response?['error'] ?? 'Unknown error'}";
              });
              print(
                  'sendMessage: Ack status was not success: ${response?['error'] ?? 'Unknown error'}');
            }
          },
        );
      } else {
        print(
            'sendMessage: WebSocket not connected, attempting to reconnect...');
        _attemptReconnect();
      }
    } catch (e, stackTrace) {
      if (!mounted) return; // Check if mounted before setting state

      setState(() {
        _errorMessage = "Error sending message: $e";
      });
      print('sendMessage: Error sending message: $e');
      print('sendMessage: Stack Trace: $stackTrace');
    }
  }

  Future<void> fetchChatMessages() async {
    if (!mounted) return; // Check if mounted before setting state
    print("Fetching chat messages...");
    setState(() {
      isLoading = true;
      _errorMessage = '';
    });

    try {
      if (socket.connected) {
        socket.emitWithAck(
          'fetch_messages',
          {
            'sender_id': adminId,
            'receiver_id': receiverId,
          },
          ack: (response) {
            if (response != null && response['status'] == 'success') {
              if (!mounted) return; // Check if mounted before setting state

              setState(() {
                chatMessages =
                    List<Map<String, dynamic>>.from(response['messages'] ?? []);
                isLoading = false;
                _scrollToBottom();
              });
              print(
                  'fetchChatMessages: Successfully fetched messages: $chatMessages');
            } else {
              if (!mounted) return; // Check if mounted before setting state

              setState(() {
                isLoading = false;
                _errorMessage =
                    "Error fetching messages: ${response?['error'] ?? 'Unknown error'}";
              });
              print(
                  'fetchChatMessages: Failed to fetch messages: ${response != null ? response['error'] : 'Unknown error'}');
            }
          },
        );
      } else {
        if (!mounted) return; // Check if mounted before setting state

        setState(() {
          isLoading = false;
          _errorMessage = "Websocket disconnected";
        });
        print(
            'fetchChatMessages: WebSocket is not connected. Attempting to reconnect...');
        _attemptReconnect();
      }
    } catch (e, stackTrace) {
      if (!mounted) return; // Check if mounted before setting state

      setState(() {
        isLoading = false;
        _errorMessage = "Error Fetching Messages: $e";
      });
      print('Error fetching messages: $e');
      print('Stack Trace: $stackTrace');
    }
  }

  void _scrollToBottom() {
    SchedulerBinding.instance!.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
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
      if (!mounted) return; // Check if mounted before setting state

      setState(() {
        isLoading = false;
        adminName = data['user']['username'] ?? 'Admin';
        adminEmail = data['user']['email'] ?? 'admin@example.com';
        adminPicUrl = data['user']['profilePic'] ?? '';
        adminPicUrl = _constructImageUrl(adminPicUrl);
        print('the pic issssssss : $adminPicUrl');
        adminId = data['user']['id'].toString() ?? '';
      });
    } catch (e) {
      if (!mounted) return; // Check if mounted before setting state

      setState(() {
        isLoading = false;
        fetchedData = 'Error fetching admin data: $e';
      });
    }
  }

  String _constructImageUrl(String relativePath) {
    final String baseUrl;
    if (kIsWeb) {
      baseUrl = 'http://192.168.88.4:4000';
    } else {
      baseUrl = 'http://10.0.2.2:4000';
    }
    print('the pic issssssss :$baseUrl/$relativePath');

    return '$baseUrl/$relativePath';
  }

  Future<void> _fetchUsers() async {
    try {
      var box = await Hive.openBox('userBox');
      final token = box.get('token');

      if (token == null || token.isEmpty) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }
      final List<dynamic> data = await fetchUsers(token);
      if (!mounted) return; // Check if mounted before setting state

      setState(() {
        users = data;
        filteredUsers = List.from(users);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return; // Check if mounted before setting state

      setState(() {
        isLoading = false;
        _errorMessage = 'Error fetching users: $e';
      });
      print('Error: $e');
    }
  }

  Future<List<dynamic>> fetchUsers(String token) async {
    final userdata = kIsWeb
        ? 'http://192.168.88.4:4000/adminRoutes/viewAll-users'
        : 'http://10.0.2.2:4000/adminRoutes/viewAll-users';

    print("userdata is $userdata");

    final response = await http.get(
      Uri.parse(userdata),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception(
          'Failed to load admin data. Status Code: ${response.statusCode}');
    }
  }

  void _onSearchChanged() {
    String searchTerm = _searchController.text.toLowerCase();
    if (!mounted) return; // Check if mounted before setting state

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

  String _formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date);
      final DateTime localTime = parsedDate.toLocal();
      final DateFormat formatter = DateFormat('hh:mm a');
      return formatter.format(localTime);
    } catch (e) {
      print('Error formatting date: $e');
      return 'Invalid Date';
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    if (socket.connected) {
      socket.disconnect();
    }
    socket.dispose();
    super.dispose();
    print('Disposing chat page');
  }

  void selectUser(dynamic user) {
    if (!mounted) return; // Check if mounted before setting state

    setState(() {
      selectedUserName = user['username'] ?? 'Unknown';
      selectedUserPic = _constructImageUrl(user['profile_picture']) ?? '';
      isUserSelected = true;
      receiverId = user['id'].toString();
      chatMessages = [];
      fetchChatMessages();
    });
  }

  void closeChat() {
    if (!mounted) return; // Check if mounted before setting state
    setState(() {
      isUserSelected = false;
      selectedUserName = '';
      selectedUserPic = '';
      receiverId = ' ';
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;
        return Scaffold(
          backgroundColor: whiteColor,
          appBar: _buildAppBar(isMobile),
          body: _buildBody(isMobile),
          floatingActionButton: _buildFloatingActionButton(
              isMobile), // Only shown on mobile when a user isn't selected
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(bool isMobile) {
    return AppBar(
      backgroundColor: darkBlueColor,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isUserSelected)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                backgroundImage: adminPicUrl.isNotEmpty
                    ? NetworkImage(adminPicUrl)
                    : AssetImage('assets/images/default-profile.png')
                        as ImageProvider,
                radius: isMobile ? 20 : 30,
              ),
            ),
          Text(isUserSelected ? selectedUserName : 'Hello,\n $adminName',
              style:
                  TextStyle(fontSize: isMobile ? 18 : 24, color: whiteColor)),
        ],
      ),
      leading: isUserSelected
          ? IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: whiteColor,
              ),
              onPressed: () {
                if (!mounted) return; // Check if mounted before setting state

                setState(() {
                  isUserSelected = false;
                  selectedUserName = '';
                  selectedUserPic = '';
                  receiverId = ' ';
                });
              },
            )
          : null,
      actions: [
        if (isUserSelected)
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Container(
                decoration:
                    BoxDecoration(color: whiteColor, shape: BoxShape.circle),
                child: IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.videocam,
                      color: lightBlueColor,
                    ))),
          ),
        if (isUserSelected)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              decoration:
                  BoxDecoration(color: whiteColor, shape: BoxShape.circle),
              child: IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.call,
                    color: lightBlueColor,
                  )),
            ),
          ),
        if (!isUserSelected) ...[
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: whiteColor,
            ),
            onSelected: (String value) {
              if (value == 'Close Chat') {
                Navigator.pushReplacementNamed(context, '/AdminDashboardPage');
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'Close Chat',
                child: ListTile(
                  leading: Icon(
                    Icons.exit_to_app,
                    color: darkBlueColor,
                  ),
                  title: Text(
                    'Close Chat',
                    style: TextStyle(color: darkBlueColor),
                  ),
                ),
              ),
            ],
          ),
        ]
      ],
      toolbarHeight: isMobile ? 80 : 100,
    );
  }

  // Widget _buildBody(bool isMobile) {
  //   return Column(
  //     children: [
  //       if (!isUserSelected) ...[
  //         if (_selectedIndex == 0)
  //           Padding(
  //             padding: const EdgeInsets.all(8.0),
  //             child: TextField(
  //               style: TextStyle(color: darkBlueColor),
  //               controller: _searchController,
  //               decoration: InputDecoration(
  //                 hintText: 'Search...',
  //                 hintStyle: TextStyle(color: darkBlueColor),
  //                 prefixIcon: Icon(
  //                   Icons.search,
  //                   color: Colors.grey,
  //                 ),
  //                 border: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(20),
  //                   borderSide: BorderSide(color: lightBlueColor),
  //                 ),
  //                 enabledBorder: OutlineInputBorder(
  //                   borderSide: BorderSide(color: Colors.grey.shade800),
  //                   borderRadius: BorderRadius.circular(20),
  //                 ),
  //                 focusedBorder: OutlineInputBorder(
  //                   borderSide: BorderSide(color: lightBlueColor),
  //                   borderRadius: BorderRadius.circular(20),
  //                 ),
  //               ),
  //               onChanged: (value) {
  //                 _onSearchChanged();
  //               },
  //             ),
  //           ),
  //         Expanded(
  //           child: ListView.builder(
  //             scrollDirection: Axis.horizontal,
  //             itemCount: filteredUsers.length,
  //             itemBuilder: (context, index) {
  //               final user = filteredUsers[index];
  //               return GestureDetector(
  //                 onTap: () => selectUser(user),
  //                 child: Padding(
  //                   padding: EdgeInsets.symmetric(horizontal: 8),
  //                   child: Column(
  //                     children: [
  //                       CircleAvatar(
  //                         radius: isMobile ? 30 : 40,
  //                         backgroundImage: _constructImageUrl(
  //                                     user['profile_picture']) !=
  //                                 null
  //                             ? NetworkImage(
  //                                 _constructImageUrl(user['profile_picture']))
  //                             : AssetImage('assets/images/default-profile.png')
  //                                 as ImageProvider,
  //                       ),
  //                       SizedBox(height: 5),
  //                       Text(
  //                         user['username'] ?? 'User',
  //                         style: TextStyle(
  //                             fontWeight: FontWeight.bold,
  //                             color: darkBlueColor),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               );
  //             },
  //           ),
  //         ),
  //       ],
  //       if (isUserSelected) ...[
  //         if (_errorMessage.isNotEmpty)
  //           Expanded(
  //               child: Center(
  //                   child: Padding(
  //             padding: const EdgeInsets.all(16.0),
  //             child: Text(
  //               _errorMessage,
  //               style: TextStyle(color: Colors.red),
  //               textAlign: TextAlign.center,
  //             ),
  //           )))
  //         else if (isLoading)
  //           Expanded(
  //             child: Center(
  //               child: CircularProgressIndicator(color: darkBlueColor),
  //             ),
  //           )
  //         else if (chatMessages.isEmpty)
  //           Expanded(
  //               child: Center(
  //                   child: Padding(
  //                       padding: const EdgeInsets.all(16.0),
  //                       child: Text(
  //                         "No Messages, Start a Conversation",
  //                         style: TextStyle(color: Colors.grey),
  //                         textAlign: TextAlign.center,
  //                       ))))
  //         else
  //           Expanded(
  //               child: ListView.builder(
  //             controller: _scrollController,
  //             itemCount: chatMessages.length,
  //             itemBuilder: (context, index) {
  //               final message = chatMessages[index];
  //               final isFromMe =
  //                   message['sender_id'].toString() == adminId.toString();

  //               return Align(
  //                 alignment:
  //                     isFromMe ? Alignment.centerRight : Alignment.centerLeft,
  //                 child: Padding(
  //                   padding: const EdgeInsets.symmetric(
  //                       horizontal: 8.0, vertical: 4.0),
  //                   child: MessageBubble(
  //                     text: message['content'] ?? '',
  //                     isUser: isFromMe,
  //                     attachment: message['message_type'] == 'Attachment',
  //                     alignment: isFromMe
  //                         ? CrossAxisAlignment.end
  //                         : CrossAxisAlignment.start,
  //                     time: _formatDate(message['send_time'].toString()),
  //                     senderName: adminName ?? '', //modified here
  //                   ),
  //                 ),
  //               );
  //             },
  //           )),
  //         Padding(
  //           padding: const EdgeInsets.all(8.0),
  //           child: _buildChatInput(isMobile),
  //         ),
  //       ]
  //     ],
  //   );
  // }

  // Widget _buildBody(bool isMobile) {
  //   print('the lenght offffffffffffff :${filteredUsers.length}');
  //   return Column(
  //     children: [
  //       if (!isUserSelected) ...[
  //         if (_selectedIndex == 0)
  //           Padding(
  //             padding: const EdgeInsets.all(8.0),
  //             child: TextField(
  //               style: TextStyle(color: darkBlueColor),
  //               controller: _searchController,
  //               decoration: InputDecoration(
  //                 hintText: 'Search...',
  //                 hintStyle: TextStyle(color: darkBlueColor),
  //                 prefixIcon: Icon(
  //                   Icons.search,
  //                   color: Colors.grey,
  //                 ),
  //                 border: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(20),
  //                   borderSide: BorderSide(color: lightBlueColor),
  //                 ),
  //                 enabledBorder: OutlineInputBorder(
  //                   borderSide: BorderSide(color: Colors.grey.shade800),
  //                   borderRadius: BorderRadius.circular(20),
  //                 ),
  //                 focusedBorder: OutlineInputBorder(
  //                   borderSide: BorderSide(color: lightBlueColor),
  //                   borderRadius: BorderRadius.circular(20),
  //                 ),
  //               ),
  //               onChanged: (value) {
  //                 _onSearchChanged();
  //               },
  //             ),
  //           ),
  //         Expanded(
  //           child: ListView.builder(
  //               itemCount: filteredUsers.length,
  //               itemBuilder: (context, index) {
  //                 final user = filteredUsers[index];
  //                 return _buildUserListItem(user, isMobile);
  //               }),
  //         ),
  //       ],
  //       if (isUserSelected) ...[
  //         if (_errorMessage.isNotEmpty)
  //           Expanded(
  //               child: Center(
  //                   child: Padding(
  //             padding: const EdgeInsets.all(16.0),
  //             child: Text(
  //               _errorMessage,
  //               style: TextStyle(color: Colors.red),
  //               textAlign: TextAlign.center,
  //             ),
  //           )))
  //         else if (isLoading)
  //           Expanded(
  //             child: Center(
  //               child: CircularProgressIndicator(color: darkBlueColor),
  //             ),
  //           )
  //         else if (chatMessages.isEmpty)
  //           Expanded(
  //               child: Center(
  //                   child: Padding(
  //                       padding: const EdgeInsets.all(16.0),
  //                       child: Text(
  //                         "No Messages, Start a Conversation",
  //                         style: TextStyle(color: Colors.grey),
  //                         textAlign: TextAlign.center,
  //                       ))))
  //         else
  //           Expanded(
  //               child: ListView.builder(
  //             controller: _scrollController,
  //             itemCount: chatMessages.length,
  //             itemBuilder: (context, index) {
  //               final message = chatMessages[index];
  //               final isFromMe =
  //                   message['sender_id'].toString() == adminId.toString();

  //               return Align(
  //                 alignment:
  //                     isFromMe ? Alignment.centerRight : Alignment.centerLeft,
  //                 child: Padding(
  //                   padding: const EdgeInsets.symmetric(
  //                       horizontal: 8.0, vertical: 4.0),
  //                   child: MessageBubble(
  //                     text: message['content'] ?? '',
  //                     isUser: isFromMe,
  //                     attachment: message['message_type'] == 'Attachment',
  //                     alignment: isFromMe
  //                         ? CrossAxisAlignment.end
  //                         : CrossAxisAlignment.start,
  //                     time: _formatDate(message['send_time'].toString()),
  //                     senderName: adminName ?? '',
  //                   ),
  //                 ),
  //               );
  //             },
  //           )),
  //         Padding(
  //           padding: const EdgeInsets.all(8.0),
  //           child: _buildChatInput(isMobile),
  //         ),
  //       ]
  //     ],
  //   );
  // }

  // Widget _buildUserListItem(Map<String, dynamic> user, bool isMobile) {
  //   return GestureDetector(
  //     onTap: () => selectUser(user),
  //     child: Padding(
  //       padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
  //       child: Row(
  //         children: [
  //           CircleAvatar(
  //             radius: isMobile ? 30 : 40,
  //             backgroundImage: _constructImageUrl(user['profile_picture']) !=
  //                     null
  //                 ? NetworkImage(_constructImageUrl(user['profile_picture']))
  //                 : const AssetImage('assets/images/default-profile.png')
  //                     as ImageProvider,
  //           ),
  //           const SizedBox(width: 10),
  //           Expanded(
  //             child: Text(
  //               user['username'] ?? 'User',
  //               style: TextStyle(
  //                   fontWeight: FontWeight.bold, color: darkBlueColor),
  //             ),
  //           ),
  //           IconButton(
  //             icon: const Icon(Icons.chat),
  //             color: lightBlueColor,
  //             onPressed: () => selectUser(user),
  //           )
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildBody(bool isMobile) {
    print('the lenght offffffffffffff :${filteredUsers.length}');
    return Column(
      children: [
        if (!isUserSelected) ...[
          if (_selectedIndex == 0)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                style: TextStyle(color: darkBlueColor),
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: darkBlueColor),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: lightBlueColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade800),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: lightBlueColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onChanged: (value) {
                  _onSearchChanged();
                },
              ),
            ),
          Expanded(
            child: ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  return _buildUserListItem(user, isMobile);
                }),
          ),
        ],
        if (isUserSelected) ...[
          if (_errorMessage.isNotEmpty)
            Expanded(
                child: Center(
                    child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            )))
          else if (isLoading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(color: darkBlueColor),
              ),
            )
          else if (chatMessages.isEmpty)
            Expanded(
                child: Center(
                    child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "No Messages, Start a Conversation",
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ))))
          else
            Expanded(
                child: ListView.builder(
              controller: _scrollController,
              itemCount: chatMessages.length,
              itemBuilder: (context, index) {
                final message = chatMessages[index];
                final isFromMe =
                    message['sender_id'].toString() == adminId.toString();
                return Align(
                  alignment:
                      isFromMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: MessageBubble(
                      text: message['content'] ?? '',
                      isUser: isFromMe,
                      attachment: message['message_type'] == 'Attachment',
                      alignment: isFromMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      time: _formatDate(message['send_time'].toString()),
                      senderName: adminName ?? '',
                    ),
                  ),
                );
              },
            )),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildChatInput(isMobile),
          ),
        ]
      ],
    );
  }

  Widget _buildUserListItem(Map<String, dynamic> user, bool isMobile) {
    return GestureDetector(
      onTap: () => selectUser(user),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: isMobile ? 30 : 40,
              backgroundImage: _constructImageUrl(user['profile_picture']) !=
                      null
                  ? NetworkImage(_constructImageUrl(user['profile_picture']))
                  : const AssetImage('assets/images/default-profile.png')
                      as ImageProvider,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                user['username'] ?? 'User',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: darkBlueColor),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chat),
              color: lightBlueColor,
              onPressed: () => selectUser(user),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: darkBlueColor,
        borderRadius: BorderRadius.circular(25.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.mic,
                color: whiteColor,
              )),
          Expanded(
              child: TextField(
                  style: TextStyle(color: whiteColor),
                  controller: _messageController,
                  decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none))),
          IconButton(
              onPressed: () {
                final message = _messageController.text;
                if (message.isNotEmpty) {
                  sendMessage(message);
                }
              },
              icon: const Icon(
                Icons.send,
                color: whiteColor,
              ))
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton(bool isMobile) {
    return !isUserSelected && isMobile && _selectedIndex == 0
        ? FloatingActionButton(
            onPressed: () {
              // Implement action when

              // Implement action when starting a new chat
            },
            backgroundColor: darkBlueColor,
            child: const Icon(
              Icons.chat_bubble_outline,
              color: whiteColor,
            ),
          )
        : null;
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final CrossAxisAlignment alignment;
  final bool attachment;
  final String time;
  final String senderName; //modified here

  const MessageBubble({
    super.key,
    required this.text,
    this.isUser = false,
    this.alignment = CrossAxisAlignment.start,
    this.attachment = false,
    required this.time,
    this.senderName = '', //modified here
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          if (attachment)
            _buildAttachment()
          else
            CustomPaint(
              painter: ChatBubblePainter(
                  isUser: isUser,
                  color: isUser ? darkBlueColor : otherBubbleColor),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!isUser)
                      Text(senderName,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey)), //added here
                    Text(text,
                        style: TextStyle(
                            color: isUser ? whiteColor : Colors.black)),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        time,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (isUser) // Example: show 'sent' icon if from me.
                        Icon(
                          Icons.done_all,
                          size: 14,
                          color: Colors.grey,
                        )
                    ])
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachment() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.file_present_outlined),
            const SizedBox(
              width: 4,
            ),
            Text(text),
            const SizedBox(
              width: 4,
            ),
            const Icon(Icons.download),
          ],
        ),
      ),
    );
  }
}

class ChatBubblePainter extends CustomPainter {
  final bool isUser;
  final Color color;

  ChatBubblePainter({required this.isUser, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    final borderRadius = 20.0;

    if (isUser) {
      path.moveTo(0, size.height);
      path.lineTo(size.width - borderRadius, size.height);
      path.quadraticBezierTo(
          size.width, size.height, size.width, size.height - borderRadius);
      path.lineTo(size.width, borderRadius);
      path.quadraticBezierTo(size.width, 0, size.width - borderRadius, 0);
      path.lineTo(borderRadius, 0);
      path.quadraticBezierTo(0, 0, 0, borderRadius);
    } else {
      path.moveTo(borderRadius, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, size.height - borderRadius);
      path.quadraticBezierTo(size.width, 0, size.width - borderRadius, 0);
      path.lineTo(borderRadius, 0);
      path.quadraticBezierTo(0, 0, 0, borderRadius);
      path.lineTo(0, size.height - borderRadius);
      path.quadraticBezierTo(0, size.height, borderRadius, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

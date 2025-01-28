// import 'package:flutter/material.dart';
// import 'package:firstproj/Pages/LoginPage.dart' as loginPage;
// import 'Pages/SignUpPage.dart';
// import 'package:firstproj/Pages/DashboardPage.dart' as dashboardPage;
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:firstproj/Pages/AdminDashboardPage.dart' as adminDashboardPage;
// import 'package:firstproj/Pages/ManageClients.dart' as manageClients;
// import 'package:firstproj/Pages/ManageCases.dart' as manageCases;
// import 'package:firstproj/Pages/Reports.dart' as reports;
// import 'package:firstproj/Pages/Billing.dart' as billing;
// import 'package:firstproj/Pages/Notifications.dart' as notifications;
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import '../firebase_options.dart';
// final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
//     GlobalKey<ScaffoldMessengerState>();

// final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   // Firebase has already been initialized by main() so we do not need to initialize it again here
//   print("Handling a background message: ${message.messageId}");
// }

// void _showForegroundDialog(BuildContext context, RemoteMessage message) {
//   showDialog(
//     context: context,
//     builder: (context) => AlertDialog(
//       title: Text(message.notification?.title ?? ''),
//       content: Text(message.notification?.body ?? ''),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Close'),
//         ),
//       ],
//     ),
//   );
// }

// // This is where all messages are going to be handled
// Future<void> _firebaseMessagingForegroundHandler(RemoteMessage message) async {
//     if(_navigatorKey.currentState?.context != null){
//         _showForegroundDialog(_navigatorKey.currentContext!, message);
//     }
//     // If not we are going to put the event in a queue, so it can be executed
//     // when a context is available.
//     else{
//       _messageQueue.add(message);
//     }
// }

// // Here is the queue for messages that arrive before a BuildContext is available.
// final _messageQueue = <RemoteMessage>[];

// void main() async {
//   await Hive.initFlutter(); // Initialize Hive

//   runApp(const LawApp());
// }

// class LawApp extends StatelessWidget {
//   const LawApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       builder: (context, child) {
//         ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
//           return Scaffold(
//               body: Center(
//                   child: Text('An error occurred: ${errorDetails.exception}')));
//         };
//         return child!;
//       },
//       title: 'Lawyer App',
//       theme: ThemeData(
//         primarySwatch: Colors.indigo,
//       ),
//       scaffoldMessengerKey: scaffoldMessengerKey, // Assign the key here
//       initialRoute: '/', // Set initial route to the login page
//       routes: {
//         '/': (context) =>
//             const loginPage.AnimatedLoginPage(), // Use alias for LoginPage
//         '/insert_record': (context) =>
//             const SignUpPage(), // Define route for sign-up page
//         '/dashboard': (context) =>
//             const dashboardPage.DashboardPage(), // Use alias for DashboardPage
//         '/AdminDashboardPage': (context) =>
//             const adminDashboardPage.AdminDashboardPage(),
//         '/ManageClients': (context) => manageClients.ManageClients(),
//         '/ManageCases': (context) => manageCases.ManageCases(),

//         '/Notifications': (context) => notifications.NotificationPage(),
//         '/Billing': (context) => const billing.BillingPage(),
//         '/Reports': (context) => const reports.ReportsPage(),
//       },
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:firstproj/Pages/LoginPage.dart' as loginPage;
// import 'Pages/SignUpPage.dart';
// import 'package:firstproj/Pages/DashboardPage.dart' as dashboardPage;
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:firstproj/Pages/AdminDashboardPage.dart' as adminDashboardPage;
// import 'package:firstproj/Pages/ManageClients.dart' as manageClients;
// import 'package:firstproj/Pages/ManageCases.dart' as manageCases;
// import 'package:firstproj/Pages/Reports.dart' as reports;
// import 'package:firstproj/Pages/Billing.dart' as billing;
// import 'package:firstproj/Pages/Notifications.dart' as notifications;
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import '../firebase_options.dart';

// final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
//     GlobalKey<ScaffoldMessengerState>();

// final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   print("Handling a background message: ${message.messageId}");
// }

// void _showForegroundDialog(BuildContext context, RemoteMessage message) {
//   showDialog(
//     context: context,
//     builder: (context) => AlertDialog(
//       title: Text(message.notification?.title ?? ''),
//       content: Text(message.notification?.body ?? ''),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Close'),
//         ),
//       ],
//     ),
//   );
// }

// // This is where all messages are going to be handled
// Future<void> _firebaseMessagingForegroundHandler(RemoteMessage message) async {
//   if (_navigatorKey.currentState?.context != null) {
//     _showForegroundDialog(_navigatorKey.currentContext!, message);
//   }
//   else {
//     _messageQueue.add(message);
//   }
// }

// // Here is the queue for messages that arrive before a BuildContext is available.
// final _messageQueue = <RemoteMessage>[];

// Future<void> _sendTokenToServer(String token) async {
//   // TODO: Send to your server.
// }

// Future<void> _getFCMToken() async {
//   print('getFCMToken\n');
//   try {
//     FirebaseMessaging messaging = FirebaseMessaging.instance;
//     NotificationSettings settings = await messaging.requestPermission(
//       alert: true,
//       announcement: false,
//       badge: true,
//       carPlay: false,
//       criticalAlert: false,
//       provisional: false,
//       sound: true,
//     );
//     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//       final token = await messaging.getToken();
//       if (token != null) {
//         await _sendTokenToServer(token);
//       }
//     }
//     messaging.onTokenRefresh.listen((fcmToken) async {
//       await _sendTokenToServer(fcmToken);
//     });
//   } on FirebaseException catch (e) {
//     print('Firebase Exception getting permission : $e');
//     print('Firebase Exception: Code = ${e.code} Message = ${e.message}');
//   } catch (e) {
//     print('Error calling _getFCMToken method $e');
//   }
// }

// void _showNotification(BuildContext context, String title, String body) async {
//   // Create a dummy message to use for dialog
//   RemoteMessage dummyMessage =
//       RemoteMessage(notification: RemoteNotification(title: title, body: body));

//   _showForegroundDialog(context, dummyMessage);
// }

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );

//   // Start listening for background messages BEFORE runApp() is called
//   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//   // Handle foreground messages after Flutter is fully initialized
//   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//     _firebaseMessagingForegroundHandler(message);
//   });

//   await Hive.initFlutter(); // Initialize Hive

//   runApp(const LawApp());

//   // After the app has started we need to check if there are any queued up messages
//   while (_messageQueue.isNotEmpty) {
//     // If the context is available, then show the messages.
//     if (_navigatorKey.currentContext != null) {
//       final message = _messageQueue.removeAt(0);
//       _showForegroundDialog(_navigatorKey.currentContext!, message);
//     }
//     // If not wait one second and try again.
//     else {
//       await Future.delayed(const Duration(seconds: 1));
//     }
//   }
//   await _getFCMToken();
// }

// class LawApp extends StatelessWidget {
//   const LawApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       builder: (context, child) {
//         ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
//           return Scaffold(
//               body: Center(
//                   child: Text('An error occurred: ${errorDetails.exception}')));
//         };
//         return child!;
//       },
//       title: 'Lawyer App',
//       theme: ThemeData(
//         primarySwatch: Colors.indigo,
//       ),
//       scaffoldMessengerKey: scaffoldMessengerKey, // Assign the key here
//       navigatorKey: _navigatorKey, //Assign the key here
//       initialRoute: '/', // Set initial route to the login page
//       routes: {
//         '/': (context) =>
//             const loginPage.AnimatedLoginPage(), // Use alias for LoginPage
//         '/insert_record': (context) =>
//             const SignUpPage(), // Define route for sign-up page
//         '/dashboard': (context) =>
//             const dashboardPage.DashboardPage(), // Use alias for DashboardPage
//         '/AdminDashboardPage': (context) =>
//             const adminDashboardPage.AdminDashboardPage(),
//         '/ManageClients': (context) => manageClients.ManageClients(),
//         '/ManageCases': (context) => manageCases.ManageCases(),

//         '/Notifications': (context) => notifications.NotificationPage(),
//         '/Billing': (context) => const billing.BillingPage(),
//         '/Reports': (context) => const reports.ReportsPage(),
//       },
//     );
//   }
// }

import 'package:firstproj/Pages/TokenUtils.dart';
import 'package:flutter/material.dart';
import 'package:firstproj/Pages/LoginPage.dart' as loginPage;
import 'Pages/SignUpPage.dart';
import 'package:firstproj/Pages/DashboardPage.dart' as dashboardPage;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firstproj/Pages/AdminDashboardPage.dart' as adminDashboardPage;
import 'package:firstproj/Pages/ManageClients.dart' as manageClients;
import 'package:firstproj/Pages/ManageCases.dart' as manageCases;
import 'package:firstproj/Pages/Reports.dart' as reports;
import 'package:firstproj/Pages/Billing.dart' as billing;
import 'package:firstproj/Pages/Notifications.dart' as notifications;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../firebase_options.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

void _showForegroundDialog(BuildContext context, RemoteMessage message) {
  // showDialog(
  //   context: context,
  //   builder: (context) => AlertDialog(
  //     title: Text(message.notification?.title ?? ''),
  //     content: Text(message.notification?.body ?? ''),
  //     actions: [
  //       TextButton(
  //         onPressed: () => Navigator.pop(context),
  //         child: const Text('Close'),
  //       ),
  //     ],
  //   ),
  // );
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
                        child: const Text(
                          "On",
                          style: TextStyle(color: Colors.white, fontSize: 14.0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "ONSHAPE",
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15.0,
                            color: Colors.black87),
                      ),
                    ],
                  ),
                  Text(
                    '${DateTime.now().hour}:${DateTime.now().minute} ',
                    style:
                        const TextStyle(fontSize: 13.0, color: Colors.black87),
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

// This is where all messages are going to be handled
Future<void> _firebaseMessagingForegroundHandler(RemoteMessage message) async {
  if (_navigatorKey.currentState?.context != null) {
    _showForegroundDialog(_navigatorKey.currentContext!, message);
  } else {
    _messageQueue.add(message);
  }
}

// Here is the queue for messages that arrive before a BuildContext is available.
final _messageQueue = <RemoteMessage>[];

IO.Socket? socket;

Future<void> _registerUserWithSocket() async {
  if (socket == null || !socket!.connected) {
    // Initialize the socket connection
    socket = IO.io('connect', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket?.onConnect((_) {
      print('Connected to Socket.io server');
    });

    socket?.onDisconnect((_) {
      print('Disconnected from socket.io server');
    });
    socket?.onError((error) => {print('Socket error: $error')});
  }
  try {
    socket?.emit('register_user', TokenUtils());
    print('Emitted register_user event with JWT token.');
    socket?.on('user_registered', (data) {
      print('User registration successful: $data');
    });
  } catch (e) {
    print('Error sending register_user event: $e');
  }
}

Future<void> _getFCMToken() async {
  print('getFCMToken\n');
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    messaging.onTokenRefresh.listen((fcmToken) async {});
  } on FirebaseException catch (e) {
    print('Firebase Exception getting permission : $e');
    print('Firebase Exception: Code = ${e.code} Message = ${e.message}');
  } catch (e) {
    print('Error calling _getFCMToken method $e');
  }
}

void _showNotification(BuildContext context, String title, String body) async {
  RemoteMessage dummyMessage =
      RemoteMessage(notification: RemoteNotification(title: title, body: body));

  _showForegroundDialog(context, dummyMessage);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _firebaseMessagingForegroundHandler(message);
  });

  await Hive.initFlutter(); // Initialize Hive

  runApp(const LawApp());

  // After the app has started we need to check if there are any queued up messages
  while (_messageQueue.isNotEmpty) {
    // If the context is available, then show the messages.
    if (_navigatorKey.currentContext != null) {
      final message = _messageQueue.removeAt(0);
      _showForegroundDialog(_navigatorKey.currentContext!, message);
    }
    // If not wait one second and try again.
    else {
      await Future.delayed(const Duration(seconds: 1));
    }
  }
  await _getFCMToken();
}

class LawApp extends StatelessWidget {
  const LawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return Scaffold(
              body: Center(
                  child: Text('An error occurred: ${errorDetails.exception}')));
        };
        return child!;
      },
      title: 'JustiPro',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      scaffoldMessengerKey: scaffoldMessengerKey, // Assign the key here
      navigatorKey: _navigatorKey, //Assign the key here
      initialRoute: '/', // Set initial route to the login page
      routes: {
        '/': (context) =>
            const loginPage.AnimatedLoginPage(), // Use alias for LoginPage
        '/insert_record': (context) =>
            const SignUpPage(), // Define route for sign-up page
        '/dashboard': (context) =>
            const dashboardPage.DashboardPage(), // Use alias for DashboardPage
        '/AdminDashboardPage': (context) =>
            const adminDashboardPage.AdminDashboardPage(),
        '/ManageClients': (context) => manageClients.ManageClients(),
        '/ManageCases': (context) => manageCases.ManageCases(),
        '/Notifications': (context) => notifications.NotificationPage(),
        '/Billing': (context) => const billing.BillingPage(),
        '/Reports': (context) => const reports.ReportsPage(),
      },
    );
  }
}

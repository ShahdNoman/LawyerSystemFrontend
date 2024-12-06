// import 'package:flutter/material.dart';
// import 'package:firstproj/Pages/LoginPage.dart' as loginPage;
// import 'Pages/SignUpPage.dart';
// import 'package:firstproj/Pages/DashboardPage.dart' as dashboardPage;
// import 'package:hive_flutter/hive_flutter.dart';

// void main() async {
//   await Hive.initFlutter(); // Initialize Hive
//   runApp(const LawApp());
// }

// class LawApp extends StatelessWidget {
//   const LawApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Lawyer App',
//       theme: ThemeData(
//         primarySwatch: Colors.indigo,
//       ),
//       initialRoute: '/', // Set initial route to the login page
//       routes: {
//         '/': (context) =>
//             const loginPage.AnimatedLoginPage(), // Use alias for LoginPage
//         '/insert_record': (context) =>
//             const SignUpPage(), // Define route for sign-up page
//         '/dashboard': (context) =>
//             const dashboardPage.DashboardPage(), // Use alias for DashboardPage
//       },
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:firstproj/Pages/LoginPage.dart' as loginPage;
import 'Pages/SignUpPage.dart';
import 'package:firstproj/Pages/DashboardPage.dart' as dashboardPage;
import 'package:hive_flutter/hive_flutter.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  await Hive.initFlutter(); // Initialize Hive
  runApp(const LawApp());
}

class LawApp extends StatelessWidget {
  const LawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lawyer App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      scaffoldMessengerKey: scaffoldMessengerKey, // Assign the key here
      initialRoute: '/', // Set initial route to the login page
      routes: {
        '/': (context) => const loginPage.AnimatedLoginPage(), // Use alias for LoginPage
        '/insert_record': (context) => const SignUpPage(), // Define route for sign-up page
        '/dashboard': (context) => const dashboardPage.DashboardPage(), // Use alias for DashboardPage
      },
    );
  }
}



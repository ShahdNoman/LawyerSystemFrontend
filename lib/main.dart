import 'package:flutter/material.dart';
import 'Pages/LoginPage.dart'; 
import 'Pages/SignUpPage.dart';
import 'Pages/DashboardPage.dart' as dashboardPage; 

void main() {
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
      initialRoute: '/', // Set initial route to the login page
      routes: {
        '/': (context) =>
            const AnimatedLoginPage(), // Define route for login page
        '/insert_record': (context) =>
            const SignUpPage(), // Define route for sign-up page
        '/dashboard': (context) => const dashboardPage
            .DashboardPage(), // Define route for dashboard page
      },
    );
  }
}

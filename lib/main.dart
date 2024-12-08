import 'package:flutter/material.dart';
import 'package:firstproj/Pages/LoginPage.dart' as loginPage;
import 'Pages/SignUpPage.dart';
import 'package:firstproj/Pages/DashboardPage.dart' as dashboardPage;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firstproj/Pages/AdminDashboardPage.dart' as adminDashboardPage;
import 'package:firstproj/Pages/ManageClients.dart' as manageClients;
import 'package:firstproj/Pages/ManageCases.dart' as manageCases;
import 'package:firstproj/Pages/LegalDocuments.dart' as legalDocuments;
import 'package:firstproj/Pages/Reports.dart' as reports;
import 'package:firstproj/Pages/Billing.dart' as billing;
import 'package:firstproj/Pages/Notifications.dart' as notifications;
import 'package:firstproj/Pages/ManageComplaints.dart' as manageComplaints;


final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

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
        '/': (context) =>
            const loginPage.AnimatedLoginPage(), // Use alias for LoginPage
        '/insert_record': (context) =>
            const SignUpPage(), // Define route for sign-up page
        '/dashboard': (context) =>
            const dashboardPage.DashboardPage(), // Use alias for DashboardPage
        '/AdminDashboardPage': (context) =>
            const adminDashboardPage.AdminDashboardPage(),
              '/ManageClients': (context) =>
             manageClients.ManageClients(),
             '/ManageCases': (context) =>
             manageCases.ManageCases(),
   '/LegalDocuments': (context) =>
            const legalDocuments.LegalDocuments(),
       '/Notifications': (context) =>
            const notifications.NotificationsPage(),
            '/Billing': (context) =>
            const billing.BillingPage(),
            '/Reports': (context) =>
            const reports.ReportsPage(),   
             '/ManageComplaints': (context) =>
             manageComplaints.ManageComplaints(),   
            
      },
    );
  }
}

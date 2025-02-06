// // import 'package:flutter/material.dart';
// // import 'Pages/LoginPage.dart' as loginPage;
// // import 'Pages/SignUpPage.dart';
// // import 'Pages/DashboardPage.dart' as dashboardPage;
// // import 'package:hive_flutter/hive_flutter.dart';
// // import 'Pages/AdminDashboardPage.dart' as adminDashboardPage;
// // import 'Pages/ManageClients.dart' as manageClients;
// // import 'Pages/ManageCases.dart' as manageCases;
// // import 'Pages/LegalDocuments.dart' as legalDocuments;
// // import 'Pages/Reports.dart' as reports;
// // import 'Pages/Billing.dart' as billing;
// // import 'Pages/Notifications.dart' as notifications;
// // import 'Pages/ManageComplaints.dart' as manageComplaints;
// // final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
// //     GlobalKey<ScaffoldMessengerState>();
// // void main() async {
// //   await Hive.initFlutter(); // Initialize Hive
// //   runApp(const LawApp());
// // }

// import 'package:flutter/material.dart';
// import 'Pages/DashboardPage.dart';
// import 'Pages/LoginPage.dart' as loginPage;
// import 'Pages/SignUpPage.dart';
// import 'Pages/DashboardPage.dart' as dashboardPage;
// import 'package:hive_flutter/hive_flutter.dart';
// import 'Pages/AdminDashboardPage.dart' as adminDashboardPage;
// import 'Pages/ManageClients.dart' as manageClients;
// import 'Pages/ManageCases.dart' as manageCases;
// import 'Pages/LegalDocuments.dart' as legalDocuments;
// import 'Pages/Reports.dart' as reports;
// import 'Pages/Billing.dart' as billing;
// import 'Pages/Notifications1.dart' as notifications;
// import 'Pages/ManageComplaints.dart' as manageComplaints;
//  import 'package:flutter_stripe/flutter_stripe.dart'; // استيراد حزمة Stripe
// final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
//     GlobalKey<ScaffoldMessengerState>();
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Hive.initFlutter(); // Initialize Hive
//   Stripe.publishableKey = 'pk_test_51QlULHGgPcncAP5JnEayNzR6Hs4rdogMrpPJZdgFqZ4tMAEUUb3y7Oeejj82n7JKrjjKswnKXNaN4r7DmGSVdTcY00aesEhYrQ'; // قم باستبدال مفتاح الـ Publishable Key الخاص بك
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
//       scaffoldMessengerKey: scaffoldMessengerKey, // Assign the key here
//       initialRoute: '/', // Set initial route to the login page
//       routes: {
//         '/D':(context)=>
//             DashboardPage(),
//         '/': (context) =>
//             const loginPage.AnimatedLoginPage(), // Use alias for LoginPage
//         '/insert_record': (context) =>
//             const SignUpPage(), // Define route for sign-up page
//         '/dashboard': (context) =>
//             const dashboardPage.DashboardPage(), // Use alias for DashboardPage
//         '/AdminDashboardPage': (context) =>
//         const adminDashboardPage.AdminDashboardPage(),
//         '/ManageClients': (context) => manageClients.ManageClients(),
//         '/ManageCases': (context) => manageCases.ManageCases(),
//         '/LegalDocuments': (context) => const legalDocuments.LegalDocuments(),
//         '/Notifications': (context) =>  notifications.NotificationPage(),
//         '/Billing': (context) => const billing.BillingPage(),
//         '/Reports': (context) => const reports.ReportsPage(),
//         '/ManageComplaints': (context) => manageComplaints.ManageComplaints(),
//       },
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'Pages/DashboardPage.dart';
import 'Pages/LoginPage.dart' as loginPage;
import 'Pages/SignUpPage.dart';
import 'Pages/DashboardPage.dart' as dashboardPage;
import 'package:hive_flutter/hive_flutter.dart';
import 'Pages/AdminDashboardPage.dart' as adminDashboardPage;
import 'Pages/ManageClients.dart' as manageClients;
import 'Pages/ManageCases.dart' as manageCases;
import 'Pages/LegalDocuments.dart' as legalDocuments;
import 'Pages/Reports.dart' as reports;
import 'Pages/Billing.dart' as billing;
import 'Pages/Notifications1.dart' as notifications;
import 'Pages/ManageComplaints.dart' as manageComplaints;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/foundation.dart'; // Import kIsWeb

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Condition to initialize Stripe only on web

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
      scaffoldMessengerKey: scaffoldMessengerKey,
      initialRoute: '/',
      routes: {
        '/D':(context)=> DashboardPage(), // dashboard check
        '/': (context) =>
            const loginPage.AnimatedLoginPage(),
        '/insert_record': (context) => const SignUpPage(),
        '/dashboard': (context) => const dashboardPage.DashboardPage(),
        '/AdminDashboardPage': (context) =>
            const adminDashboardPage.AdminDashboardPage(),
        '/ManageClients': (context) => manageClients.ManageClients(),
        '/ManageCases': (context) => manageCases.ManageCases(),
        '/LegalDocuments': (context) => const legalDocuments.LegalDocuments(),
        '/Notifications': (context) => notifications.NotificationPage(),
        '/Billing': (context) => const billing.BillingPage(),
        '/Reports': (context) => const reports.ReportsPage(),
        '/ManageComplaints': (context) => manageComplaints.ManageComplaints(),
      },
    );
  }
}
// import 'package:LAWYERSYSTEMFRONTEND/Pages/payment_page.dart';
// import 'Notifications.dart';
// import 'Sessions_Screen.dart';
// import 'TokenUtils.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'dart:async';
// import 'Home11Screen.dart';
// import 'SearchUserScreen.dart';
// import 'calender.dart';
// import 'Userinformation.dart';
// import 'cases.dart';
// import 'LoginPage.dart';
// import 'payment_page.dart';

// Map<String, dynamic>? userInfo;

// class DashboardPage extends StatefulWidget {
//   const DashboardPage({super.key});

//   @override
//   _DashboardPageState createState() => _DashboardPageState();
// }

// class _DashboardPageState extends State<DashboardPage> {
//   bool isLoading = true;
//   String fetchedData = "";
//   late Timer _timer;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       TokenUtils.checkTokenExpiration(context);
//     });
//     _userhData();
//     _fetchData();
//     _timer = Timer.periodic(Duration(seconds: 30), (timer) {
//       TokenUtils.checkTokenExpiration(context);
//     });
//   }

//   @override
//   void dispose() {
//     _timer.cancel();
//     super.dispose();
//   }

//   Future<void> _userhData() async {
//     try {
//       var box = await Hive.openBox('userBox');
//       final token = box.get('token');
//       // If token is absent, redirect to login page
//       if (token == null || token.isEmpty) {
//         Navigator.pushReplacementNamed(context, '/');
//         return;
//       }

//       final response = await http.get(
//         Uri.parse('http://10.0.2.2:4000/home/get-my-info'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );

//       if (response.statusCode == 200) {
//         final result = jsonDecode(response.body);
//         setState(() {
//           userInfo = result['user'];
//           isLoading = false;
//         });
//       } else if (response.statusCode == 401 || response.statusCode == 403) {
//         // Token expired or invalid, show error and redirect to login
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (ScaffoldMessenger.maybeOf(context) != null) {
//             if (mounted) {
//               Navigator.pushReplacementNamed(context, '/');
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                     content:
//                         Text('Invalid or expired token. Please log in again.')),
//               );
//             }
//           }
//         });
//       } else {
//         // General error fetching data
//         setState(() {
//           isLoading = false;
//           fetchedData =
//               'Failed to fetch data. Status Code: ${response.statusCode}';
//         });
//       }
//     } catch (e) {
//       // Handle network errors or other exceptions
//       setState(() {
//         isLoading = false;
//         fetchedData = 'Error during request: $e';
//       });
//     }
//   }

//   Future<void> _fetchData() async {
//     try {
//       var box = await Hive.openBox('userBox');
//       print('Box opened successfully.');
//       final token = box.get('token');
//       print('Token retrieved: $token');

//       // If token is absent, redirect to login page
//       if (token == null || token.isEmpty) {
//         Navigator.pushReplacementNamed(context, '/');
//         return;
//       }

//       final response = await http.get(
//         Uri.parse('http://10.0.2.2:4000/protected-endpoint'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );

//       if (response.statusCode == 200) {
//         final result = jsonDecode(response.body);
//         setState(() {
//           fetchedData = result['data'];
//           isLoading = false;
//         });
//       } else if (response.statusCode == 401 || response.statusCode == 403) {
//         // Token expired or invalid, show error and redirect to login
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (ScaffoldMessenger.maybeOf(context) != null) {
//             if (mounted) {
//               Navigator.pushReplacementNamed(context, '/');
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                     content:
//                         Text('Invalid or expired token. Please log in again.')),
//               );
//             }
//           }
//         });
//       } else {
//         // General error fetching data
//         setState(() {
//           isLoading = false;
//           fetchedData =
//               'Failed to fetch data. Status Code: ${response.statusCode}';
//         });
//       }
//     } catch (e) {
//       // Handle network errors or other exceptions
//       setState(() {
//         isLoading = false;
//         fetchedData = 'Error during request: $e';
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Dashboard',
//       theme: ThemeData(
//         scaffoldBackgroundColor: const Color(0xFFF2F2F2), // الرمادي الفاتح
//         appBarTheme: const AppBarTheme(
//           backgroundColor: Color(0xFF003366),
//           titleTextStyle: TextStyle(
//             color: Colors.white,
//             fontSize: 20,
//           ),
//         ),
//         bottomNavigationBarTheme: const BottomNavigationBarThemeData(
//           selectedItemColor:
//               Color(0xFF003366), // الأزرق الداكن للأيقونة المحددة
//           unselectedItemColor: Colors.white, // الأبيض للأيقونات غير المحددة
//           backgroundColor:
//               Color(0xFF003366), // الأزرق الداكن خلفية الشريط السفلي
//         ),
//         drawerTheme: const DrawerThemeData(
//           backgroundColor: Color(0xFF003366), // الأزرق الداكن
//         ),
//       ),
//       home: const HomeScreen(),
//     );
//   }
// }

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int _currentIndex = 0; // لتتبع الشاشة الحالية
//   final PageController _pageController = PageController();

//   // قائمة الصفحات التي سيتم التنقل بينها
//   final List<Widget> _pages = [
//     Home11screen(),
//     SearchUserScreen(),
//     CalendarPage(),
//     const Center(child: Text("شاشة المحادثات", style: TextStyle(fontSize: 24))),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         foregroundColor: Colors.white,
//         backgroundColor: const Color(0xFF003366),
//         title: const Text("Dashboard"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications_none_outlined),
//             color: Colors.white,
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => NotificationPage(),
//                 ),
//               );
//             },
//           ),
//           IconButton(
//             icon: CircleAvatar(
//               backgroundImage: userInfo != null &&
//                       userInfo!['profilePic'] != null &&
//                       userInfo!['profilePic'].trim().isNotEmpty
//                   ? NetworkImage(
//                       userInfo!['profilePic'].trim()) // صورة من الإنترنت
//                   : null, // لا توجد صورة
//               backgroundColor: Colors.white, // خلفية بيضاء
//             ),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => Userinformation(),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       drawer: Drawer(
//         backgroundColor: const Color(0xFF003366),
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             const DrawerHeader(
//               decoration: BoxDecoration(
//                 color: Color(0xFF003366), // الأزرق الداكن
//               ),
//               child: UserProfile(),
//             ),
//             ListTile(
//               leading: Image.asset(
//                 color: Colors.white,
//                 'web/icons/case.png', // صورة القضايا
//                 width: 30,
//                 height: 30,
//               ),
//               title: const Text(
//                 'Cases',
//                 style: TextStyle(color: Colors.white),
//               ),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => const CasesScreen()),
//                 );
//               },
//             ),
//             ListTile(
//               leading: Image.asset(
//                 color: Colors.white,
//                 'web/icons/session.png', // صورة الجلسات
//                 width: 30,
//                 height: 30,
//               ),
//               title: const Text(
//                 'Sessions',
//                 style: TextStyle(color: Colors.white),
//               ),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                       builder: (context) => const Sessions_Screen()),
//                 );
//               },
//             ),
//             ListTile(
//               leading: Image.asset(
//                 color: Colors.white,
//                 'web/icons/money.png', // صورة الدفعات التنفيذية
//                 width: 30,
//                 height: 30,
//               ),
//               title: const Text(
//                 'Executive payments',
//                 style: TextStyle(color: Colors.white),
//               ),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                       builder: (context) => const PaymentsScreen()),
//                 );
//               },
//             ),
//             ListTile(
//               leading: Image.asset(
//                 color: Colors.white,
//                 'web/icons/log.png', // صورة القضايا
//                 width: 30,
//                 height: 30,
//               ),
//               title: const Text(
//                 'Logout',
//                 style: TextStyle(color: Colors.white),
//               ),
//               onTap: () async {
//                 var box = await Hive.openBox('userBox');
//                 await box.delete('token');
//                 await box.delete('token_expiration');
//                 if (ScaffoldMessenger.of(context).mounted) {
//                   WidgetsBinding.instance.addPostFrameCallback((_) {
//                     Future.delayed(const Duration(seconds: 0), () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => const AnimatedLoginPage()),
//                       );
//                     });
//                   });
//                 }
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                       builder: (context) => const AnimatedLoginPage()),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//       body: PageView(
//         controller: _pageController,
//         onPageChanged: (index) {
//           setState(() {
//             _currentIndex = index;
//           });
//         },
//         children: _pages,
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentIndex,
//         backgroundColor: const Color(0xFF003366),
//         onTap: (index) {
//           setState(() {
//             _currentIndex = index;
//           });
//           _pageController.jumpToPage(index);
//         },
//         items: [
//           BottomNavigationBarItem(
//             icon: _buildIcon(Icons.home, 0, 'Home'),
//             backgroundColor: const Color(0xFF003366),
//             label: '',
//           ),
//           BottomNavigationBarItem(
//             backgroundColor: const Color(0xFF003366),
//             icon: _buildIcon(Icons.search, 1, 'Search'),
//             label: '',
//           ),
//           BottomNavigationBarItem(
//             backgroundColor: const Color(0xFF003366),
//             icon: _buildIcon(Icons.calendar_today, 2, 'Calender'),
//             label: '',
//           ),
//           BottomNavigationBarItem(
//             backgroundColor: const Color(0xFF003366),
//             icon: _buildIcon(Icons.chat, 3, 'Chats'),
//             label: '',
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildIcon(IconData icon, int index, String label) {
//     return Container(
//       width: 80,
//       height: 50,
//       decoration: BoxDecoration(
//         borderRadius: const BorderRadius.all(Radius.circular(20)),
//         color: _currentIndex == index
//             ? Colors.white
//             : Colors.transparent, // دائرة بيضاء حول الأيقونة المحددة
//       ),
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           Icon(
//             icon,
//             color: _currentIndex == index
//                 ? const Color(0xFF003366)
//                 : Colors.white, // اللون الأزرق للأيقونة المحددة
//           ),
//           if (_currentIndex ==
//               index) // إذا كانت الأيقونة محددة، نعرض النص داخل الدائرة
//             Positioned(
//               bottom: 2,
//               child: Text(
//                 label, // النص الذي تود إظهاره داخل الدائرة
//                 style: const TextStyle(
//                   color: Color(0xFF003366),
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }
// }

// class UserProfile extends StatelessWidget {
//   const UserProfile({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         CircleAvatar(
//           radius: 30,
//           backgroundImage: NetworkImage(
//             userInfo!['profilePic']?.trim() ?? '',
//           ), // مسار صورة الملف الشخصي
//         ),
//         const SizedBox(width: 10), // This can remain const
//         Text(
//           userInfo!['username'] ?? 'Unknown Name', // اسم المستخدم
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 20,
//           ),
//         ),
//       ],
//     );
//   }
// }
import 'package:LAWYERSYSTEMFRONTEND/Pages/payment_page.dart';
import 'Notifications.dart';
import 'Sessions_Screen.dart';
import 'TokenUtils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'Home11Screen.dart';
import 'SearchUserScreen.dart';
import 'calender.dart';
import 'Userinformation.dart';
import 'cases.dart';
import 'LoginPage.dart';
import 'payment_page.dart';

Map<String, dynamic>? userInfo;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool isLoading = true;
  String fetchedData = "";
  late Timer _timer;
  int unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TokenUtils.checkTokenExpiration(context);
    });
    _userhData();
    _fetchData();
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      TokenUtils.checkTokenExpiration(context);
      _updateUnreadNotificationCount(); // Update count on timer
    });
        _updateUnreadNotificationCount(); // Update count on init

  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _userhData() async {
    try {
      var box = await Hive.openBox('userBox');
      final token = box.get('token');
      // If token is absent, redirect to login page
      if (token == null || token.isEmpty) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }
      final response = await http.get(
        Uri.parse('http://10.0.2.2:4000/home/get-my-info'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          userInfo = result['user'];
          isLoading = false;
        });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Token expired or invalid, show error and redirect to login
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (ScaffoldMessenger.maybeOf(context) != null) {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Invalid or expired token. Please log in again.')),
              );
            }
          }
        });
      } else {
        // General error fetching data
        setState(() {
          isLoading = false;
          fetchedData =
              'Failed to fetch data. Status Code: ${response.statusCode}';
        });
      }
    } catch (e) {
      // Handle network errors or other exceptions
      setState(() {
        isLoading = false;
        fetchedData = 'Error during request: $e';
      });
    }
  }
  Future<void> _fetchData() async {
    try {
      var box = await Hive.openBox('userBox');
      print('Box opened successfully.');
      final token = box.get('token');
      print('Token retrieved: $token');

      // If token is absent, redirect to login page
      if (token == null || token.isEmpty) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:4000/protected-endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          fetchedData = result['data'];
          isLoading = false;
        });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Token expired or invalid, show error and redirect to login
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (ScaffoldMessenger.maybeOf(context) != null) {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Invalid or expired token. Please log in again.')),
              );
            }
          }
        });
      } else {
        // General error fetching data
        setState(() {
          isLoading = false;
          fetchedData =
              'Failed to fetch data. Status Code: ${response.statusCode}';
        });
      }
    } catch (e) {
      // Handle network errors or other exceptions
      setState(() {
        isLoading = false;
        fetchedData = 'Error during request: $e';
      });
    }
  }
  Future<void> _updateUnreadNotificationCount() async {
    try {
      var box = await Hive.openBox('userBox');
      final token = box.get('token');

      if (token == null || token.isEmpty) {
        return;
      }
      
      final response = await http.get(
         Uri.parse('http://10.0.2.2:4000/adminRoutes/viewAll-notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> notifications = jsonDecode(response.body);
         final unreadCount = notifications.where((notification) => notification['is_read'] == 0).length;
           setState(() {
              unreadNotificationCount = unreadCount;
            });

      } else {
        print('Failed to update notification count: ${response.statusCode}');
      }
    } catch (e) {
       print('Error updating notification count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashboard',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF003366),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor:
              Color(0xFF003366), // الأزرق الداكن للأيقونة المحددة
          unselectedItemColor: Colors.white, // الأبيض للأيقونات غير المحددة
          backgroundColor:
              Color(0xFF003366), // الأزرق الداكن خلفية الشريط السفلي
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Color(0xFF003366), // الأزرق الداكن
        ),
      ),
      home: HomeScreen(unreadNotificationCount: unreadNotificationCount,updateUnreadNotificationCount: _updateUnreadNotificationCount,),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final int unreadNotificationCount;
   final VoidCallback updateUnreadNotificationCount;
  const HomeScreen({super.key, required this.unreadNotificationCount,required this.updateUnreadNotificationCount,});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();


  final List<Widget> _pages = [
    Home11screen(),
    SearchUserScreen(),
    CalendarPage(),
    const Center(child: Text("شاشة المحادثات", style: TextStyle(fontSize: 24))),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF003366),
        title: const Text("Dashboard"),
        actions: [
          Stack(
            children: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined,color: Colors.white,),
            onPressed: () {
              showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) {
                    return NotificationPage(updateCount: widget.updateUnreadNotificationCount);
                  });
            },
          ),
              if (widget.unreadNotificationCount > 0)
                Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10)),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          widget.unreadNotificationCount.toString(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                ),
            ],
          ),
          IconButton(
            icon: CircleAvatar(
              backgroundImage: userInfo != null &&
                      userInfo!['profilePic'] != null &&
                      userInfo!['profilePic'].trim().isNotEmpty
                  ? NetworkImage(
                      userInfo!['profilePic'].trim()) // صورة من الإنترنت
                  : null, // لا توجد صورة
              backgroundColor: Colors.white, // خلفية بيضاء
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Userinformation(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF003366),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF003366), // الأزرق الداكن
              ),
              child: UserProfile(),
            ),
            ListTile(
              leading: Image.asset(
                color: Colors.white,
                'web/icons/case.png', // صورة القضايا
                width: 30,
                height: 30,
              ),
              title: const Text(
                'Cases',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CasesScreen()),
                );
              },
            ),
            ListTile(
              leading: Image.asset(
                color: Colors.white,
                'web/icons/session.png', // صورة الجلسات
                width: 30,
                height: 30,
              ),
              title: const Text(
                'Sessions',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const Sessions_Screen()),
                );
              },
            ),
            ListTile(
              leading: Image.asset(
                color: Colors.white,
                'web/icons/money.png', // صورة الدفعات التنفيذية
                width: 30,
                height: 30,
              ),
              title: const Text(
                'Executive payments',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PaymentsScreen()),
                );
              },
            ),
            ListTile(
              leading: Image.asset(
                color: Colors.white,
                'web/icons/log.png', // صورة القضايا
                width: 30,
                height: 30,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                var box = await Hive.openBox('userBox');
                await box.delete('token');
                await box.delete('token_expiration');
                 if (ScaffoldMessenger.of(context).mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Future.delayed(const Duration(seconds: 0), () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AnimatedLoginPage()));
                });
              });
            }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AnimatedLoginPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF003366),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.jumpToPage(index);
        },
        items: [
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.home, 0, 'Home'),
            backgroundColor: const Color(0xFF003366),
            label: '',
          ),
          BottomNavigationBarItem(
            backgroundColor: const Color(0xFF003366),
            icon: _buildIcon(Icons.search, 1, 'Search'),
            label: '',
          ),
          BottomNavigationBarItem(
            backgroundColor: const Color(0xFF003366),
            icon: _buildIcon(Icons.calendar_today, 2, 'Calender'),
            label: '',
          ),
          BottomNavigationBarItem(
            backgroundColor: const Color(0xFF003366),
            icon: _buildIcon(Icons.chat, 3, 'Chats'),
            label: '',
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(IconData icon, int index, String label) {
    return Container(
      width: 80,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        color: _currentIndex == index
            ? Colors.white
            : Colors.transparent, // دائرة بيضاء حول الأيقونة المحددة
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            icon,
            color: _currentIndex == index
                ? const Color(0xFF003366)
                : Colors.white, // اللون الأزرق للأيقونة المحددة
          ),
          if (_currentIndex ==
              index) // إذا كانت الأيقونة محددة، نعرض النص داخل الدائرة
            Positioned(
              bottom: 2,
              child: Text(
                label, // النص الذي تود إظهاره داخل الدائرة
                style: const TextStyle(
                  color: Color(0xFF003366),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class UserProfile extends StatelessWidget {
  const UserProfile({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage(
            userInfo!['profilePic']?.trim() ?? '',
          ), // مسار صورة الملف الشخصي
        ),
        const SizedBox(width: 10), // This can remain const
        Text(
          userInfo!['username'] ?? 'Unknown Name', // اسم المستخدم
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ],
    );
  }
}
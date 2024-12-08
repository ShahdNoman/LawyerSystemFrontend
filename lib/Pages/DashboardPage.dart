import 'package:firstproj/Pages/TokenUtils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool isLoading = true;
  String fetchedData = "";
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TokenUtils.checkTokenExpiration(context);
    });

    _fetchData();
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      TokenUtils.checkTokenExpiration(context);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashboard',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF2F2F2), // الرمادي الفاتح
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
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // لتتبع الشاشة الحالية
  final PageController _pageController = PageController();

  // قائمة الصفحات التي سيتم التنقل بينها
  final List<Widget> _pages = [
    const Center(
        child: Text("الشاشة الرئيسية", style: TextStyle(fontSize: 24))),
    const Center(child: Text("شاشة البحث", style: TextStyle(fontSize: 24))),
    const Center(child: Text("شاشة التقويم", style: TextStyle(fontSize: 24))),
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
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            color: Colors.white,
            onPressed: () {},
          ),
          IconButton(
            icon: const CircleAvatar(
              backgroundImage: AssetImage('web/icons/case.png'),
            ),
            onPressed: () {},
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
                'القضايا',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context); // غلق القائمة عند الضغط
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
                'الجلسات',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
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
                'الدفعات التنفيذية',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
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
                'تسجيل خروج',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context); // غلق القائمة عند الضغط
              },
            ),
            // ListTile(
            //   leading: const Icon(Icons.exit_to_app, color: Colors.white),
            //   title: const Text(
            //     'تسجيل الخروج',
            //     style: TextStyle(color: Colors.white),
            //   ),
            //   onTap: () {
            //     Navigator.pop(context);
            //   },
            // ),
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
            icon: _buildIcon(Icons.home, 0, 'الرئيسية'),
            backgroundColor: const Color(0xFF003366),
            label: '',
          ),
          BottomNavigationBarItem(
            backgroundColor: const Color(0xFF003366),
            icon: _buildIcon(Icons.search, 1, 'البحث'),
            label: '',
          ),
          BottomNavigationBarItem(
            backgroundColor: const Color(0xFF003366),
            icon: _buildIcon(Icons.calendar_today, 2, 'التقويم'),
            label: '',
          ),
          BottomNavigationBarItem(
            backgroundColor: const Color(0xFF003366),
            icon: _buildIcon(Icons.chat, 3, 'المحادثات'),
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

// Widget لعرض صورة الملف الشخصي مع الاسم في الـ Drawer
class UserProfile extends StatelessWidget {
  const UserProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage:
              AssetImage('web/icons/case.png'), // مسار صورة الملف الشخصي
        ),
        SizedBox(width: 10),
        Text(
          'اسم المستخدم', // اسم المستخدم
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ],
    );
  }
}

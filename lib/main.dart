import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JustiPro',
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
        title: const Text("JustiPro"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            color: Colors.white,
            onPressed: () {},
          ),
          IconButton(
            icon: const CircleAvatar(
              backgroundImage: AssetImage('assets/profile.jpg'),
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
              AssetImage('assets/profile.jpg'), // مسار صورة الملف الشخصي
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

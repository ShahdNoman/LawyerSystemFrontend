// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:async';

// void main() {
//   runApp(SearchUserApp());
// }

// class SearchUserApp extends StatelessWidget {
//   const SearchUserApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: SearchUserScreen(),
//     );
//   }
// }
// class SearchUserScreen extends StatefulWidget {
//   const SearchUserScreen({super.key});

//   @override
//   _SearchUserScreenState createState() => _SearchUserScreenState();
// }

// class _SearchUserScreenState extends State<SearchUserScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   bool _isLoading = false;
//   List<Map<String, dynamic>> _users = [];
//   bool _hasSearched = false; // متغير جديد لمعرفة إذا تم البحث
//   Timer? _debounce;

//   Future<void> _searchUser() async {
//     setState(() {
//       _isLoading = true;
//       _hasSearched = true; // تم تفعيل البحث الآن
//     });
//     String username = _searchController.text.trim();

//     if (username.isEmpty) {
//       setState(() {
//         _users = [];
//         _isLoading = false;
//       });
//       return;
//     }
//     try {
//       final response = await http.get(
//         Uri.parse('http://10.0.2.2:4000/search/search/$username'),
//         headers: {'Content-Type': 'application/json'},
//       );
//       if (response.statusCode == 200) {
//         setState(() {
//           _users = List<Map<String, dynamic>>.from(
//               jsonDecode(response.body)['users']);
//           for (var user in _users) {
//             user['profile_picture'] = user['profile_picture']?.trim();
//           }
//         });
//       } else {
//         setState(() {
//           _users = [];
//         });
//       }
//     } catch (e) {
//       print('Error: $e');
//       setState(() {
//         _users = [];
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(30.0),
//                 border: Border.all(color: Colors.grey, width: 1),
//               ),
//               child: TextField(
//                 controller: _searchController,
//                 decoration: InputDecoration(
//                   hintText: 'Search',
//                   prefixIcon: Icon(Icons.search, color: Colors.grey),
//                   border: InputBorder.none,
//                   contentPadding:
//                       EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
//                 ),
//                 onChanged: (text) {
//                   if (_debounce?.isActive ?? false) _debounce!.cancel();
//                   _debounce = Timer(const Duration(milliseconds: 500), () {
//                     _searchUser();
//                   });
//                 },
//               ),
//             ),
//             SizedBox(height: 10),
//             _isLoading
//                 ? Center(child: CircularProgressIndicator())
//                 : _hasSearched && _users.isEmpty // فقط بعد البحث وعند عدم وجود نتائج
//                     ? Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Image.network(
//                               'https://img.freepik.com/premium-vector/no-result-found-empty-results-popup-design_586724-96.jpg',
//                               height: 400, // يمكنك تعديل الحجم حسب الحاجة
//                               width: 400,  // يمكنك تعديل الحجم حسب الحاجة
//                             ),
//                             SizedBox(height: 10),
                            
//                           ],
//                         ),
//                       )
//                     : _users.isNotEmpty
//                         ? Expanded(
//                             child: ListView.builder(
//                               itemCount: _users.length,
//                               itemBuilder: (context, index) {
//                                 return ListTile(
//                                   title: Text(_users[index]['full_name']),
//                                   subtitle: Text(_users[index]['username']),
//                                   leading: Stack(
//                                     alignment: Alignment.bottomRight,
//                                     children: [
//                                       CircleAvatar(
//                                         radius: 25.0,
//                                         backgroundImage: NetworkImage(
//                                           _users[index]['profile_picture'] ?? '',
//                                         ),
//                                       ),
//                                       CircleAvatar(
//                                         radius: 6.0,
//                                         backgroundColor: _users[index]['status'] == 'Active'
//                                             ? Colors.green
//                                             : Colors.grey[300],
//                                       ),
//                                     ],
//                                   ),
//                                   onTap: () {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) =>
//                                             ProfileScreen(user: _users[index]),
//                                       ),
//                                     );
//                                   },
//                                 );
//                               },
//                             ),
//                           )
//                         : SizedBox.shrink(), // لا شيء يعرض إذا لم يكن هناك نتائج بعد البحث
//           ],
//         ),
//       ),
//     );
//   }
// }
// class ProfileScreen extends StatelessWidget {
//   final Map<String, dynamic> user;

//   const ProfileScreen({super.key, required this.user});

//   @override
//   Widget build(BuildContext context) {
//     bool isActive = user['status'] == 'Active';

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.share, color: Colors.black),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: Icon(Icons.favorite_border, color: Colors.black),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             Stack(
//               clipBehavior: Clip.none,
//               children: [
//                 Container(
//                   height: 220,
//                   decoration: BoxDecoration(
//                     color: Color(0xFF003366),
//                     borderRadius: BorderRadius.only(
//                       bottomLeft: Radius.elliptical(400, 150),
//                       bottomRight: Radius.elliptical(400, 150),
//                     ),
//                   ),
//                 ),
//                 Positioned(
//                   top: 140,
//                   left: 0,
//                   right: 0,
//                   child: Column(
//                     children: [
//                       Container(
//                         padding: EdgeInsets.all(5),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           shape: BoxShape.circle,
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.1),
//                               blurRadius: 10,
//                               spreadRadius: 2,
//                             ),
//                           ],
//                         ),
//                         child: Stack(
//                           clipBehavior: Clip.none,
//                           children: [
//                             CircleAvatar(
//                               radius: 65,
//                               backgroundImage: NetworkImage(
//                                 user['profile_picture'] ?? '',
//                               ),
//                             ),
//                             Positioned(
//                               bottom: 5,
//                               right: 5,
//                               child: Transform.rotate(
//                                 angle: -10 * (3.14159 / 180),
//                                 child: CircleAvatar(
//                                   radius: 10.0,
//                                   backgroundColor: Colors.white,
//                                   child: CircleAvatar(
//                                     radius: 6.0,
//                                     backgroundColor: isActive
//                                         ? Colors.green
//                                         : Colors.grey[300],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 80),
//             Center(
//               child: Text(
//                 user['full_name'] ?? '',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//             Center(
//               child: Text(
//                 user['bio'] ?? '',
//                 style: TextStyle(
//                   fontSize: 20,
//                 ),
//               ),
//             ),
//             SizedBox(height: 16),
// Padding(
//   padding: const EdgeInsets.symmetric(horizontal: 60.0), // المسافة بين الأزرار وحافة الشاشة
//   child: Row(
//     mainAxisAlignment: MainAxisAlignment.spaceBetween, // لضبط المسافة بين الأزرار بشكل متساوٍ
//     children: [
//       ElevatedButton.icon(
//         onPressed: () {},
//         icon: Icon(Icons.phone),
//         label: Text(
//           user['phone_number'] ?? '',
//           style: TextStyle(
//             color: Colors.white, // لون النص
//           ),
//         ),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Color(0xFF003366), // اللون الأساسي
//           foregroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12), // الزر بتصميم دائري
//           ),
//           padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16), // المسافة الداخلية للزر
//         ),
//       ),
//       SizedBox(width: 10), // المسافة بين الأزرار
//       ElevatedButton.icon(
//         onPressed: () {},
//         icon: Icon(Icons.message_outlined),
//         label: Text('Message'),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Color(0xFF003366), // اللون الأساسي
//           foregroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12), // الزر بتصميم دائري
//           ),
//           padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16), // المسافة الداخلية للزر
//         ),
//       ),
//     ],
//   ),
// ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(SearchUserApp());
}

class SearchUserApp extends StatelessWidget {
  const SearchUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SearchUserScreen(),
    );
  }
}

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({super.key});

  @override
  _SearchUserScreenState createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _users = [];
  bool _hasSearched = false;
  Timer? _debounce;

  Future<void> _searchUser() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    String username = _searchController.text.trim();

    if (username.isEmpty) {
      setState(() {
        _users = [];
        _isLoading = false;
      });
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:4000/search/search/$username'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(
              jsonDecode(response.body)['users']);
          for (var user in _users) {
            user['profile_picture'] = user['profile_picture']?.trim();
          }
        });
      } else {
        setState(() {
          _users = [];
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _users = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView( // Wrap your main column with SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.0),
                  border: Border.all(color: Colors.grey, width: 1),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                  ),
                  onChanged: (text) {
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 500), () {
                      _searchUser();
                    });
                  },
                ),
              ),
              SizedBox(height: 10),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _hasSearched && _users.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'https://img.freepik.com/premium-vector/no-result-found-empty-results-popup-design_586724-96.jpg',
                                height: 400, // Adjust the height as needed
                                width: 400,  // Adjust the width as needed
                              ),
                              SizedBox(height: 10),
                            ],
                          ),
                        )
                      : _users.isNotEmpty
                          ? ListView.builder(
                              shrinkWrap: true, // Important for working inside Column and SingleChildScrollView
                              physics: NeverScrollableScrollPhysics(), // Disable internal list scrolling to use the main scroll
                              itemCount: _users.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(_users[index]['full_name']),
                                  subtitle: Text(_users[index]['username']),
                                  leading: Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      CircleAvatar(
                                        radius: 25.0,
                                        backgroundImage: NetworkImage(
                                          _users[index]['profile_picture'] ?? '',
                                        ),
                                      ),
                                      CircleAvatar(
                                        radius: 6.0,
                                        backgroundColor: _users[index]['status'] == 'Active'
                                            ? Colors.green
                                            : Colors.grey[300],
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProfileScreen(user: _users[index]),
                                      ),
                                    );
                                  },
                                );
                              },
                            )
                          : SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    bool isActive = user['status'] == 'Active';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.favorite_border, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Color(0xFF003366),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.elliptical(400, 150),
                      bottomRight: Radius.elliptical(400, 150),
                    ),
                  ),
                ),
                Positioned(
                  top: 140,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 65,
                              backgroundImage: NetworkImage(
                                user['profile_picture'] ?? '',
                              ),
                            ),
                            Positioned(
                              bottom: 5,
                              right: 5,
                              child: Transform.rotate(
                                angle: -10 * (3.14159 / 180),
                                child: CircleAvatar(
                                  radius: 10.0,
                                  backgroundColor: Colors.white,
                                  child: CircleAvatar(
                                    radius: 6.0,
                                    backgroundColor: isActive
                                        ? Colors.green
                                        : Colors.grey[300],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 80),
            Center(
              child: Text(
                user['full_name'] ?? '',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Center(
              child: Text(
                user['bio'] ?? '',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.phone),
                    label: Text(
                      user['phone_number'] ?? '',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF003366),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.message_outlined),
                    label: Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF003366),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
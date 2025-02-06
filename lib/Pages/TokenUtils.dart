import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';

import 'LoginPage.dart';
// Import the main.dart file

class TokenUtils {
  static Future<void> checkTokenExpiration(BuildContext context) async {
    try {
      var box = await Hive.openBox('userBox');
      String? tokenExpiration = await box.get('token_expiration');
      if (tokenExpiration != null) {
        DateTime expirationDate = DateTime.parse(tokenExpiration);
        if (DateTime.now().isAfter(expirationDate)) {
          await box.delete('token');
          await box.delete('token_expiration');

          if (ScaffoldMessenger.of(context).mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Future.delayed(const Duration(seconds: 2), () {
                Navigator.pushReplacementNamed(context, '/');
              });
            });
          }
        }
      }
    } catch (e) {
      print("Error checking token expiration: $e");
    }
  }

  static Future<void> _clearToken(Box box,BuildContext context) async{
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

    }
  
  // static Future<void> clearToken(BuildContext context) async {
  //   var box = await Hive.openBox('userBox');
  //   await box.delete('token');
  //   await box.delete('tokenExpiration');
  //     Navigator.pushReplacement(
      
  //               MaterialPageRoute(
  //                   builder: (context) =>
  //                       const ProfilePage()), // Replace with your User Dashboard page
  //             );
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Logged out successfully.')),
  //     );

     
  // }
}

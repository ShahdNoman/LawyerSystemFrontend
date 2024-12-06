import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:firstproj/main.dart'; // Import the main.dart file

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
}

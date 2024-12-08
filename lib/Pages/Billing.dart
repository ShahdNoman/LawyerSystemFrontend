import 'package:firstproj/Pages/TokenUtils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';

const Color backgroundColor = Colors.white;
const Color lightBlueColor = Color(0xFFADD8E6);
const Color blueColor = Color(0xFF0F3460);
const Color cardColor = Color(0xFFB0E0E6);

class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  _BillingPageState createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  late Timer _timer;
  bool isLoading = true;
  List<dynamic> billingData = [];

  @override
  void initState() {
    super.initState();
    // Token expiration check
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      TokenUtils.checkTokenExpiration(context); // Add your token check logic
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Function to fetch billing data from the backend
  Future<List<dynamic>> fetchBillingData(String token) async {
    final response = await http.get(
      Uri.parse('https://your-backend-api.com/billing'), // Replace with your backend API URL
      headers: {
        'Authorization': 'Bearer $token', // Use the token for authentication
      },
    );

    if (response.statusCode == 200) {
      // Parse the JSON response and return the billing data
      return json.decode(response.body)['billingDetails'];
    } else {
      throw Exception('Failed to load billing data');
    }
  }

  // Fetching billing data example
  Future<void> _fetchBillingData() async {
    try {
      var box = await Hive.openBox('userBox');
      final token = box.get('token');
      print('Token retrieved: $token');

      if (token == null || token.isEmpty) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      final data = await fetchBillingData(token);
      setState(() {
        isLoading = false;
        billingData = data;
      });

    } catch (e) {
      setState(() {
        isLoading = false;
        billingData = [];
      });
      print('Error during request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Billing',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF0F3460),
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : ListView.builder(
                itemCount: billingData.length,
                itemBuilder: (context, index) {
                  final item = billingData[index];
                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      title: Text('Invoice #${item['invoiceNumber']}'),
                      subtitle: Text('Amount: \$${item['amount']}'),
                      trailing: Text('Date: ${item['date']}'),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchBillingData,
        backgroundColor: blueColor,
        child: Icon(Icons.refresh),
      ),
    );
  }
}

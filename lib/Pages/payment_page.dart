
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  _PaymentsScreenState createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<Map<String, dynamic>> _allPayments = [];
  List<Map<String, dynamic>> payments = [];
  bool isLoading = true;
  String _selectedPaymentStatus = 'All';
  int? _currentUserId;
  Map<int, bool> _isDisbursedUpdating = {};
  Map<int, dynamic> _caseDetailsCache = {};
  final String _publishableKey = "pk_test_51QlULHGgPcncAP5JnEayNzR6Hs4rdogMrpPJZdgFqZ4tMAEUUb3y7Oeejj82n7JKrjjKswnKXNaN4r7DmGSVdTcY00aesEhYrQ"; // Replace with your publishable key
  int? _fetchedCaseId;
  // Removed controllers
  //final _caseNumberController = TextEditingController();
 // final _paymentDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
      stripe.Stripe.publishableKey = _publishableKey;
    _fetchPayments();
  }

  Future<void> _fetchPayments({
    String paymentStatus = '',
    // Removed parameters
    // String caseNumber = '',
    //  String paymentDate = '',
  }) async {
    setState(() {
      isLoading = true;
      payments = [];
      _currentUserId = null;
    });
    try {
      var box = await Hive.openBox('userBox');
      final token = box.get('token');

      if (token == null || token.isEmpty) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

        String url = 'http://10.0.2.2:4000/payment/payment';
      bool hasParams = false;
      if (paymentStatus.isNotEmpty && paymentStatus != 'All') {
        url += '?payment_status=$paymentStatus';
          hasParams = true;
        }
        

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          _currentUserId = result['userId'];
          _allPayments = List<Map<String, dynamic>>.from(result['payments']);
            await _fetchCaseDetailsForPayments(); // Fetch case details before filtering
             _filterPayments(paymentStatus: paymentStatus);
        } else {
          setState(() {
            isLoading = false;
            payments = [];
            _allPayments = [];
             _currentUserId = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('There is no payments with this filter .')),
          );
        }
      } else {
        setState(() {
          isLoading = false;
           _currentUserId = null;
        });
        throw Exception('Failed to load payments');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
         _currentUserId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to connect to the server: ${e.toString()}')),
      );
    }
  }

  Future<void> _fetchCaseDetailsForPayments() async {
      var box = await Hive.openBox('userBox');
      final token = box.get('token');
        if (token == null || token.isEmpty) {
         Navigator.pushReplacementNamed(context, '/');
          return;
        }
    try {
        List<int> caseIds = _allPayments.map((payment) => payment['case_id'] as int).toSet().toList();

        List<Future<dynamic>> fetchFutures = caseIds.map((caseId) async {
          if (!_caseDetailsCache.containsKey(caseId)) {
            final url = 'http://10.0.2.2:4000/payment/case/$caseId';
            final response = await http.get(
                Uri.parse(url),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
            );
            if (response.statusCode == 200) {
                final result = jsonDecode(response.body);
              if(result['success'] == true){
                  _caseDetailsCache[caseId] = result['case'];
              } else {
                  throw Exception('Failed to load case details for caseId: $caseId');
              }
            } else {
                   throw Exception('Failed to load case details for caseId: $caseId');
            }
          }
        }).toList();

        await Future.wait(fetchFutures);
      } catch(e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to fetch case details: ${e.toString()}')),
          );
      }
  }

  void _filterPayments({required String paymentStatus}) {
    List<Map<String, dynamic>> filteredPayments = _allPayments;
    if (paymentStatus != 'All' && paymentStatus.isNotEmpty) {
      filteredPayments = filteredPayments
          .where((paymentData) => paymentData['payment_status'] == paymentStatus)
          .toList();
    }
    setState(() {
      payments = filteredPayments;
      isLoading = false;
      _selectedPaymentStatus = paymentStatus;
    });
    if (payments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There is no payments with this filter .')),
      );
    }
  }

  Future<dynamic> fetchCaseDetails(int caseId) async {
    var box = await Hive.openBox('userBox');
    final token = box.get('token');

    final url = 'http://10.0.2.2:4000/payment/case/$caseId';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['success'] == true) {
        return result['case'];
      } else {
        throw Exception('Failed to load case details');
      }
    } else {
      throw Exception('Failed to connect to the server');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments List', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
      ),
          floatingActionButton: FloatingActionButton(
        onPressed: () {
         _showNewPaymentDialog(_currentUserId);
      },
        child: const Icon(Icons.add, color: Colors.white),
         backgroundColor: const Color(0xFF003366),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
               
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _filterPayments(paymentStatus: 'All');
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedPaymentStatus == 'All'
                                  ? const Color(0xFF003366)
                                  : Colors.white,
                              side: BorderSide(
                                color: _selectedPaymentStatus != 'All'
                                    ? const Color(0xFF003366)
                                    : Colors.transparent,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              foregroundColor: _selectedPaymentStatus == 'All'
                                  ? Colors.white
                                  : const Color(0xFF003366)),
                          child: Text(
                            'All',
                            style: TextStyle(fontFamily: 'Almarai'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _filterPayments(paymentStatus: 'Completed');
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _selectedPaymentStatus == 'Completed'
                                      ? const Color(0xFF003366)
                                      : Colors.white,
                              side: BorderSide(
                                color: _selectedPaymentStatus != 'Completed'
                                    ? const Color(0xFF003366)
                                    : Colors.transparent,
                              ),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0)),
                              foregroundColor:
                                  _selectedPaymentStatus == 'Completed'
                                      ? Colors.white
                                      : const Color(0xFF003366)),
                          child: Text(
                            'Completed',
                            style: TextStyle(fontFamily: 'Almarai'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _filterPayments(paymentStatus: 'Pending');
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _selectedPaymentStatus == 'Pending'
                                      ? const Color(0xFF003366)
                                      : Colors.white,
                              side: BorderSide(
                                color: _selectedPaymentStatus != 'Pending'
                                    ? const Color(0xFF003366)
                                    : Colors.transparent,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              foregroundColor:
                                  _selectedPaymentStatus == 'Pending'
                                      ? Colors.white
                                      : const Color(0xFF003366)),
                          child: Text(
                            'Pending',
                            style: TextStyle(fontFamily: 'Almarai'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: payments.isEmpty
                      ? const Center(
                          child: Text('No Payments'),
                        )
                      : ListView.separated(
                          itemCount: payments.length,
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          separatorBuilder: (context, index) => const Divider(
                            color: Colors.grey,
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final payment = payments[index];
                            return _buildPaymentCard(payment);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final bool isDisbursed = payment['is_disbursed'] == 1;
    final int paymentId = payment['id'];
    final int caseId = payment['case_id'];

    Future<bool> isUserAuthorized(int caseId) async {
      print('Checking authorization for caseId: $caseId');
      if (_caseDetailsCache.containsKey(caseId)) {
        print('Case details found in cache for caseId: $caseId');
        final caseDetails = _caseDetailsCache[caseId];
         print('Case details: $caseDetails');

        final int? plaintiffId = caseDetails['plaintiff']?['id'];
         print('Plaintiff ID from caseDetails: $plaintiffId');
        final int? plaintiffLawyerId = caseDetails['plaintiffLawyer']?['id'];
           print('Plaintiff lawyer ID from caseDetails: $plaintiffLawyerId');
        print('Current user ID: $_currentUserId');

        final isPlaintiffOrLawyer =
            plaintiffId == _currentUserId || plaintiffLawyerId == _currentUserId;
         print('Is plaintiff or lawyer: $isPlaintiffOrLawyer');
        return isPlaintiffOrLawyer;
      } else {
         print('Case details not found in cache for caseId: $caseId');
        // Handle cases where caseDetails is not cached or fetched yet
        return false;
      }
    }

    Future<void> handleDisbursedChange(bool? newValue, int caseId) async {

      if (newValue == null) return;
      if (newValue && isDisbursed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The amount has been disbursed already.')),
        );
        return;
      }
      final isAuthorized = await isUserAuthorized(caseId);

      if (!isAuthorized) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are not authorized to change this payment status.')),
        );
        return;
      }
      _updateDisbursedStatus(payment, newValue == true ? 1 : 0);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: const Color(0xFF003366),
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        title: Text(
          'Case ID: ${payment['case_id'] ?? 'N/A'}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF003366),
            fontFamily: 'Almarai',
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount: ${payment['amount'] ?? 'N/A'}',
              style: const TextStyle(
                  fontSize: 14, fontFamily: 'Almarai', color: Colors.black87),
            ),
            Text(
              'Payer: ${payment['payer_name'] ?? 'N/A'}',
              style: const TextStyle(
                  fontSize: 14, fontFamily: 'Almarai', color: Colors.black87),
            ),
            Text(
              'Payment Date: ${payment['payment_date']?.toString().substring(0, 10) ?? 'N/A'}',
              style: const TextStyle(
                  fontSize: 14, fontFamily: 'Almarai', color: Colors.black87),
            ),
            Text(
              'Status: ${payment['payment_status'] ?? 'N/A'}',
              style: const TextStyle(
                  fontSize: 14, fontFamily: 'Almarai', color: Colors.black87),
            ),
            Row(
               children: [
                  const Text(
                'Disbursed: ',
                    style: TextStyle(
                    fontSize: 14, fontFamily: 'Almarai', color: Colors.black87),
              ),
                 _isDisbursedUpdating[paymentId] == true ? const CircularProgressIndicator() :
                Checkbox(
                    value: isDisbursed,
                    onChanged: isDisbursed ? null : (bool? newValue) {
                    handleDisbursedChange(newValue, payment['case_id']);
                    },
                    activeColor: const Color(0xFF003366),
                   ),
                 ],
              ),
            if (isDisbursed)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'The amount has been disbursed already.',
                  style: TextStyle(fontSize: 14, fontFamily: 'Almarai', color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNewPaymentDialog(int? userId) async {
    final _formKey = GlobalKey<FormState>();
    final _caseNumberController = TextEditingController();
    final _amountController = TextEditingController();
    final _cardDetails = CardDetails();
     int? fetchedCaseId;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (BuildContext context, setState) {
          return AlertDialog(
            title: const Text('Enter Payment Details'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     TextFormField(
                        controller: _caseNumberController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                            labelText: 'Case Number',
                            hintText: 'Enter Case Number'
                        ),
                        validator: (value) {
                            if (value == null || value.isEmpty) {
                                return 'Please enter case Number';
                            }
                             return null;
                           },
                    ),
                     if(fetchedCaseId != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                           child: Text('Case ID: $fetchedCaseId',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                         ),
                       if (fetchedCaseId == null && _caseNumberController.text.isNotEmpty)
                       const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                           child: Text('Case ID not found',
                                style: TextStyle(color: Colors.red),
                            ),
                         ),
                   TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Amount',
                          hintText: 'Enter amount'
                      ),
                       validator: (value) {
                          if (value == null || value.isEmpty) {
                             return 'Please enter amount';
                           }
                            return null;
                        },
                   ),
                    const SizedBox(height: 20),
                  TextField(
                      decoration: const InputDecoration(labelText: 'Card Number'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _cardDetails.cardNumber = value,
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Expiry Month'),
                         keyboardType: TextInputType.number,
                      onChanged: (value) => _cardDetails.expMonth = value,
                  ),
                  TextField(
                        decoration: const InputDecoration(labelText: 'Expiry Year'),
                         keyboardType: TextInputType.number,
                        onChanged: (value) => _cardDetails.expYear = value,
                      ),
                    TextField(
                       decoration: const InputDecoration(labelText: 'CVC'),
                         keyboardType: TextInputType.number,
                       onChanged: (value) => _cardDetails.cvc = value,
                     ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
               ElevatedButton(
                child: const Text('Pay Now'),
                onPressed: () async {
                 if (_formKey.currentState!.validate()) {
                  setState(() {
                    isLoading = true;
                   });
                  try {
                        final caseIdResult =  await fetchCaseId(_caseNumberController.text);
                         if (caseIdResult != null) {
                            fetchedCaseId = caseIdResult;
                          final result = await _handleNewPayment(fetchedCaseId!,int.parse(_amountController.text),_cardDetails,userId);
                           setState(() {
                            isLoading = false;
                             });
                               if (result) {
                                 Navigator.of(context).pop();
                             }
                         } else {
                            setState(() {
                            isLoading = false;
                          });
                         ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(
                                 content: Text('Failed to fetch case ID')),
                           );
                          }
                     } catch (e) {
                       setState(() {
                        isLoading = false;
                       });
                         ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text('Failed to create payment session: ${e.toString()}')),
                       );
                      }
                } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(
                         content: Text('Please fill in the form')),
                     );
                  }
                 },
               ),
            ],
          );
        });
      },
    );
  }

   Future<bool> _handleNewPayment(
      int caseId, int amount, CardDetails cardDetails, int? userId) async {
    try {
       var box = await Hive.openBox('userBox');
        final token = box.get('token');
        if (token == null || token.isEmpty) {
           Navigator.pushReplacementNamed(context, '/');
           return false;
        }
        final paymentMethod = {
          'id': 'fake_pm_' + DateTime.now().millisecondsSinceEpoch.toString(),
            // يمكنك إضافة أي بيانات وهمية أخرى هنا
         };

       final url = 'http://10.0.2.2:4000/payment/create-payment-session';
       final response = await http.post(
           Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
               'Authorization': 'Bearer $token',
             },
            body: jsonEncode({
              'caseId': caseId,
             'amount': amount,
               'paymentMethod': paymentMethod['id'],
                
             }),
        );

      if (response.statusCode == 200) {
         ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Payment added successfully!')),
          );
         return true;
        } else {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Failed to add payment!')),
           );
         throw Exception('Failed to create session');
        }
   } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create payment session: ${e.toString()}')),
       );
       return false;
     }
 }
  Future<int?> fetchCaseId(String caseNumber) async {
    var box = await Hive.openBox('userBox');
    final token = box.get('token');
    if (token == null || token.isEmpty) {
      Navigator.pushReplacementNamed(context, '/');
      return null;
    }
    try {
      final url = 'http://10.0.2.2:4000/payment/case-id/$caseNumber';
      final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          }
      );
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
          if (result['success'] == true) {
           return result['caseId'];
          } else{
             return null;
           }
      } else{
          return null;
      }
    } catch (e) {
      print(e);
      return null;
    }
  }

    Future<void> _updateDisbursedStatus(
      Map<String, dynamic> payment, int newStatus) async {
    setState(() {
        _isDisbursedUpdating[payment['id']] = true;
    });
    try {
         var box = await Hive.openBox('userBox');
          final token = box.get('token');
        if (token == null || token.isEmpty) {
          Navigator.pushReplacementNamed(context, '/');
           return;
        }
        final url = 'http://10.0.2.2:4000/payment/update-disbursed';
        final response = await http.put(
            Uri.parse(url),
            headers: {
               'Content-Type': 'application/json',
               'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'payment_id': payment['id'],
              'is_disbursed': newStatus,
           }),
        );
        if (response.statusCode == 200) {
          setState(() {
              payment['is_disbursed'] = newStatus;
            _isDisbursedUpdating[payment['id']] = false;
         });
        ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment status updated successfully.')),
          );
        } else {
          setState(() {
            _isDisbursedUpdating[payment['id']] = false;
          });
          throw Exception('Failed to update payment status');
        }
    } catch (e) {
        setState(() {
         _isDisbursedUpdating[payment['id']] = false;
        });
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Failed to update payment status: ${e.toString()}')),
        );
     }
 }
}
class CardDetails {
  String? cardNumber;
  String? expMonth;
  String? expYear;
  String? cvc;

  CardDetails({this.cardNumber, this.expMonth, this.expYear, this.cvc});
  Map<String, dynamic> toJson() {
    return {
        'cardNumber': cardNumber,
        'expMonth': expMonth,
       'expYear': expYear,
       'cvc': cvc,
     };
  }
}
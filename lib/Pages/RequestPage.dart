import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
const Color blueColor = Color(0xFF0F3460);

class RequestPage extends StatefulWidget {
  final Map<String, dynamic> caseData;

  RequestPage({Key? key, required this.caseData}) : super(key: key);

  @override
  _RequestPageState createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  bool _isEditing = false;
  late TextEditingController _caseNumberController;
  late TextEditingController _caseTypeController;
  late TextEditingController _caseStatusController;
  late TextEditingController _judgeNameController;
  late TextEditingController _judgeIdController;
  late TextEditingController _courtNameController;
  late TextEditingController _courtTypeController;
  late TextEditingController _dateOfRosesController;
  late TextEditingController _noteController;
    bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('Received caseData: ${widget.caseData}');
    _caseNumberController =
        TextEditingController(text: widget.caseData['case_number']?.toString() ?? '');
    _caseTypeController =
        TextEditingController(text: widget.caseData['case_type']?.toString() ?? '');
    _caseStatusController =
        TextEditingController(text: widget.caseData['case_status']?.toString() ?? '');
     _judgeNameController =
        TextEditingController(text: widget.caseData['judge']?['name']?.toString() ?? '');
     _judgeIdController =
        TextEditingController(text: widget.caseData['judge']?['id_number']?.toString() ?? '');
    _courtNameController =
        TextEditingController(text: widget.caseData['court_name']?.toString() ?? '');
    _courtTypeController =
        TextEditingController(text: widget.caseData['court_type']?.toString() ?? '');
      String dateOfRoses = widget.caseData['date_of_roses']?.toString() ?? '';
      if(dateOfRoses.isNotEmpty){
        DateTime parsedDate = DateTime.parse(dateOfRoses);
        String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(parsedDate);
         _dateOfRosesController =
            TextEditingController(text: formattedDate );
      } else {
        _dateOfRosesController = TextEditingController(text: '');
      }
    _noteController =
        TextEditingController(text: widget.caseData['note']?.toString() ?? '');
  }

  @override
  void dispose() {
    _caseNumberController.dispose();
    _caseTypeController.dispose();
    _caseStatusController.dispose();
    _judgeNameController.dispose();
    _judgeIdController.dispose();
    _courtNameController.dispose();
    _courtTypeController.dispose();
    _dateOfRosesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _rejectCase(BuildContext context) async {
    try {
      var box = await Hive.openBox('userBox');
      final token = box.get('token');

      if (token == null || token.isEmpty) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }
      final String caseId = widget.caseData['id'].toString();
      print('the case id that i want to delet is  $caseId');
      final response = await http.delete(
        Uri.parse(
            'http://10.0.2.2:4000/adminRoutes/delete-case/$caseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        _showSuccessDialog(context, 'Case Deleted Successfully');
        print('Case deleted successfully');
      } else {
        _showErrorDialog(context, 'Failed to Delete Case');
        print('Failed to delete case. Status code: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog(context, 'An error occurred: $e');
      print('Error during delete request: $e');
    }
  }

  Future<void> _acceptCase(BuildContext context) async {
      setState(() {
      _isEditing = true;
       });
  }
  Future<void> _saveChanges(BuildContext context) async {
      setState(() {
          _isLoading = true;
      });
    try {
       var box = await Hive.openBox('userBox');
        final token = box.get('token');

      if (token == null || token.isEmpty) {
        Navigator.pushReplacementNamed(context, '/');
         return;
       }
        final String caseId = widget.caseData['id'].toString();
        String formattedDate = '';
         if(_dateOfRosesController.text.isNotEmpty){
             DateTime parsedDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(_dateOfRosesController.text);
               formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(parsedDate);
         }
      final response = await http.put(
        Uri.parse('http://10.0.2.2:4000/cases/update-case/$caseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'case_number': _caseNumberController.text,
          'case_type': _caseTypeController.text,
          'case_status': _caseStatusController.text,
           'judge_id_number': _judgeIdController.text,
           'judge_name': _judgeNameController.text,
          'court_name': _courtNameController.text,
          'court_type': _courtTypeController.text,
          'date_of_roses': formattedDate,
          'note': _noteController.text,
        }),
      );

       if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
        if (result['success'] == true) {
              _showSuccessDialog(context, 'Case Updated Successfully');
               print('Case updated successfully');
          } else {
             _showErrorDialog(context, 'Failed to update case: ${result['message']}');
           print('Failed to update case. Status code: ${response.statusCode}');
         }
       } else {
        _showErrorDialog(context, 'Failed to connect to the server.');
        print('Failed to connect to the server. Status code: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog(context, 'An error occurred: $e');
      print('Error during update request: $e');
    } finally {
          setState(() {
          _isEditing = false; // Set editing state to false
              _isLoading = false; // Set loading state to false
            });
    }
  }
  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context:context,
      builder:(BuildContext context) {
        return AlertDialog(
          title: Text('Success',
              style: TextStyle(
                fontFamily: 'Almarai',
              )),
          content: Text(message,
              style: TextStyle(
                fontFamily: 'Almarai',
              )),
          actions: <Widget>[
            TextButton(
              child: Text('OK',
                  style: TextStyle(
                    fontFamily: 'Almarai',
                  )),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                 Navigator.of(context).pop(); // Go back to previous page
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error',
              style: TextStyle(
                fontFamily: 'Almarai',
              )),
          content: Text(message,
              style: TextStyle(
                fontFamily: 'Almarai',
              )),
          actions: <Widget>[
            TextButton(
              child: Text('OK',
                  style: TextStyle(
                    fontFamily: 'Almarai',
                  )),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
  Widget _buildDateField(String label, TextEditingController controller, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: blueColor,
              fontSize: 16,
              fontFamily: 'Almarai',
            ),
          ),
          InkWell(
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (pickedDate != null) {
                String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(pickedDate);
                setState(() {
                   controller.text = formattedDate;
                 });
              }
            },
            child: IgnorePointer(
              child: TextField(
                controller: controller,
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: 'Almarai',
                ),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: blueColor, width: 1.5)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                          color: blueColor,
                          width: 1.5)),
                   suffixIcon:  Icon(Icons.calendar_today, color: blueColor,),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

   Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: blueColor,
              fontSize: 16,
              fontFamily: 'Almarai',
            ),
          ),
          TextField(
            controller: controller,
            style: TextStyle(
              fontSize: 15,
              fontFamily: 'Almarai',
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: blueColor, width: 1.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(
                      color: blueColor,
                      width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
    Widget _buildEditForm(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField('Case Number', _caseNumberController),
            _buildTextField('Case Type', _caseTypeController),
            _buildTextField('Case Status', _caseStatusController),
            _buildTextField('Judge Name', _judgeNameController),
            _buildTextField('Judge Id', _judgeIdController),
            _buildTextField('Court Name', _courtNameController),
            _buildTextField('Court Type', _courtTypeController),
            _buildDateField('Date of Roses', _dateOfRosesController,context),
            _buildTextField('Note', _noteController),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _saveChanges(context),
              style: ElevatedButton.styleFrom(
                backgroundColor:  blueColor , // Customize as needed
              ),
              child:  _isLoading
                  ? const CircularProgressIndicator(color: Colors.white,)
                  :Text('Save Changes', style: TextStyle( fontFamily: 'Almarai', color: Colors.white,)),
            ),
          ],
        )
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: blueColor, size: 20),
          SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: blueColor,
                    fontSize: 16,
                    fontFamily: 'Almarai',
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'Almarai',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Requested Case Details',
            style: TextStyle(fontFamily: 'Almarai', color: Colors.white)),
        backgroundColor: const Color(0xFF003366),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isEditing ? _buildEditForm(context) : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                _buildDetailRow(Icons.account_balance, 'Case Number',
                    widget.caseData['case_number']?.toString() ?? 'N/A'),
                _buildDetailRow(Icons.assignment, 'Case Type',
                    widget.caseData['case_type']?.toString() ?? 'N/A'),
                _buildDetailRow(Icons.account_balance, 'Court Name',
                    widget.caseData['court_name']?.toString() ?? 'N/A'),
                _buildDetailRow(Icons.account_balance_outlined, 'Court Type',
                    widget.caseData['court_type']?.toString() ?? 'N/A'),
                _buildDetailRow(Icons.calendar_today, 'Date of Roses',
                    widget.caseData['date_of_roses']?.toString() ?? 'N/A'),
                _buildDetailRow(Icons.note, 'Note',
                    widget.caseData['note']?.toString() ?? 'N/A'),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () => _rejectCase(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blueColor,
                           foregroundColor: Colors.white,
                      ),
                      child: Text('Reject',
                          style: TextStyle(
                            fontFamily: 'Almarai',
                          )),
                    ),
                    ElevatedButton(
                      onPressed: () => _acceptCase(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blueColor,
                         foregroundColor: Colors.white,
                      ),
                      child: Text('Accept',
                          style: TextStyle(
                            fontFamily: 'Almarai',
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
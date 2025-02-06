import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class NewCaseScreen extends StatefulWidget {
  const NewCaseScreen({super.key});

  @override
  _NewCaseScreenState createState() => _NewCaseScreenState();
}

class _NewCaseScreenState extends State<NewCaseScreen> {
  final _formKey = GlobalKey<FormState>();

  final _caseNumberController = TextEditingController();
  String? _selectedCaseType;

  final _courtNameController = TextEditingController();
  String? _selectedCourtType;
  DateTime? _dateOfRoses;
  final _noteController = TextEditingController();

  final _plaintiffNameController = TextEditingController();
  final _plaintiffIdController = TextEditingController();
  final _defendantNameController = TextEditingController();
  final _defendantIdController = TextEditingController();
  final List<String> _caseTypeOptions = [
    'Civil',
    'Criminal',
    'Settlement',
    'Appeal',
    'Cassation',
  ];
  final List<String> _courtTypeOptions = [
    'Primary',
    'Appeal',
    'Cassation',
    'Settlement',
  ];
  bool _isLoading = false;
  Future<void> _submitNewCase() async {
    if (_formKey.currentState!.validate()) {
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
        final response = await http.post(
          Uri.parse('http://10.0.2.2:4000/cases/create-case'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'case_number': _caseNumberController.text,
            'case_type': _selectedCaseType,
            'court_name': _courtNameController.text,
            'court_type': _selectedCourtType,
            'date_of_roses': _dateOfRoses?.toIso8601String(),
            'note': _noteController.text,
            'plaintiff_name': _plaintiffNameController.text,
            'plaintiff_id_number': _plaintiffIdController.text,
            'defendant_name': _defendantNameController.text,
            'defendant_id_number': _defendantIdController.text,
          }),
        );
        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          if (result['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Case submitted successfully!')),
            );
            Navigator.of(context).pop();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to submit case: ${result['message']}')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to connect to the server.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to submit case: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _dateOfRoses ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101));
    if (picked != null && picked != _dateOfRoses) {
      setState(() {
        _dateOfRoses = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit New Case'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: const Color(0xFF003366),
      ),
      body:  Form(
        key: _formKey,
        child:  SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _caseNumberController,
                decoration: const InputDecoration(
                  labelText: 'Case Number (Optional)',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'Almarai'),
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Case Type',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCaseType,
                onChanged: (newValue){
                  setState(() {
                    _selectedCaseType = newValue;
                  });
                },
                items: _caseTypeOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontFamily: 'Almarai', color:Color(0xFF003366))), // لون الخط هنا
                  );
                }).toList(),
                  dropdownColor: Colors.white, // لون الخلفية هنا
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select case type';
                  }
                  return null;
                },
                style: const TextStyle(fontFamily: 'Almarai'),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _courtNameController,
                decoration: const InputDecoration(
                  labelText: 'Court Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the court name';
                  }
                  return null;
                },
                style: const TextStyle(fontFamily: 'Almarai'),
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Court Type',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCourtType,
                onChanged: (newValue) {
                  setState(() {
                    _selectedCourtType = newValue;
                  });
                },
                items: _courtTypeOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontFamily: 'Almarai', color:Color(0xFF003366)),), // لون الخط هنا
                  );
                }).toList(),
                  dropdownColor: Colors.white, // لون الخلفية هنا
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select court type';
                  }
                  return null;
                },
                style: const TextStyle(fontFamily: 'Almarai'),
              ),
              const SizedBox(height: 16.0),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Roses',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(_dateOfRoses == null
                          ? 'Select Date'
                          : DateFormat('yyyy-MM-dd').format(_dateOfRoses!),
                        style: const TextStyle(fontFamily: 'Almarai'),
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16.0),

              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Case Note',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'Almarai'),
              ),

              const SizedBox(height: 24.0),
              TextFormField(
                controller: _plaintiffNameController,
                decoration: const InputDecoration(
                  labelText: 'Plaintiff Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter plaintiff name';
                  }
                  return null;
                },
                style: const TextStyle(fontFamily: 'Almarai'),
              ),
              const SizedBox(height: 16.0),

              TextFormField(
                controller: _plaintiffIdController,
                decoration: const InputDecoration(
                  labelText: 'Plaintiff ID Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter plaintiff ID';
                  }
                  return null;
                },
                style: const TextStyle(fontFamily: 'Almarai'),
              ),
              const SizedBox(height: 16.0),

              TextFormField(
                controller: _defendantNameController,
                decoration: const InputDecoration(
                  labelText: 'Defendant Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter defendant name';
                  }
                  return null;
                },
                style: const TextStyle(fontFamily: 'Almarai'),
              ),

              const SizedBox(height: 16.0),

              TextFormField(
                controller: _defendantIdController,
                decoration: const InputDecoration(
                  labelText: 'Defendant ID Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter defendant ID';
                  }
                  return null;
                },
                style: const TextStyle(fontFamily: 'Almarai'),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitNewCase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white,)
                    : const Text('Submit Case',style: TextStyle(fontFamily: 'Almarai',color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart'
    show CalendarCarousel;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Sessions_Screen extends StatefulWidget {
  const Sessions_Screen({super.key});

  @override
  _SessionsScreenState createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<Sessions_Screen> {
  String _selectedTab = 'today';
  DateTime? _selectedDate;
  final _courtNameController = TextEditingController();
  final _recordTypeController = TextEditingController();
  final _caseNumberController = TextEditingController();
  final _caseYearController = TextEditingController();
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _currentMonth = DateFormat.yMMMM().format(DateTime.now());
  DateTime _currentDate = DateTime.now();

  late CalendarCarousel _calendarCarousel;

  @override
  void initState() {
    super.initState();
    _calendarCarousel = CalendarCarousel(
      onDayPressed: (DateTime date, List<dynamic> events) {
        setState(() {
          _selectedDate = date;
          _currentMonth = DateFormat.yMMMM().format(date);
          _currentDate = date;
        });
        _fetchSessionsForDate(date);
      },
      weekendTextStyle: const TextStyle(
        color: const Color(0xFF003366),
      ),
      thisMonthDayBorderColor: const Color(0xFF003366),
      weekFormat: false,
      markedDateShowIcon: true,
      markedDateIconMaxShown: 1,
      selectedDayBorderColor: Colors.grey,
      daysHaveCircularBorder: true,
      headerTextStyle: const TextStyle(
          color: Color(0xFF003366), fontWeight: FontWeight.bold, fontFamily: 'Almarai'),
      iconColor: const Color(0xFF003366),
      todayButtonColor: const Color.fromARGB(255, 80, 82, 82),
      selectedDayButtonColor: const Color(0xFF003366),
      weekdayTextStyle:
      const TextStyle(color: Color(0xFF003366), fontFamily: 'Almarai'),
    );
  }

  @override
  void dispose() {
    _courtNameController.dispose();
    _recordTypeController.dispose();
    _caseNumberController.dispose();
    _caseYearController.dispose();
    super.dispose();
  }

  // Helper function to make http requests with token
  Future<http.Response> _makeAuthenticatedRequest(
      String url, {
        Map<String, String>? headers,
      }) async {
    var box = await Hive.openBox('userBox');
    final token = box.get('token');
    if (token == null || token.isEmpty) {
      Navigator.pushReplacementNamed(context, '/');
      throw Exception('No Token');
    }

    final defaultHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final mergedHeaders = headers != null
        ? {...defaultHeaders, ...headers}
        : defaultHeaders;
    return http.get(Uri.parse(url), headers: mergedHeaders);
  }

  Future<void> _fetchSessionsForDate(DateTime date) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _sessions = [];
    });
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final url = 'http://10.0.2.2:4000/sessions/sessions/bydate?date=$formattedDate';

    try {
      final response = await _makeAuthenticatedRequest(url);
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          final List<dynamic> sessionsData = result['sessions'];
          setState(() {
            _sessions = sessionsData.cast<Map<String, dynamic>>();
            _errorMessage = null;
          });
        } else {
          setState(() {
            _sessions = [];
            _errorMessage = 'Theres no session at this day';
          });
        }
      } else {
        setState(() {
          _sessions = [];
          _errorMessage = 'Failed to load data';
        });
        throw Exception('Failed to load cases');
      }
    } catch (e) {
      setState(() {
        _sessions = [];
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSessionsForFile() async {
    if (_courtNameController.text.isEmpty ||
        _recordTypeController.text.isEmpty ||
        _caseNumberController.text.isEmpty ||
        _caseYearController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please Filed All field';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _sessions = [];
    });

    final courtName = _courtNameController.text;
    final recordType = _recordTypeController.text;
    final caseNumber = _caseNumberController.text;
    final caseYear = _caseYearController.text;
    final url =
        'http://10.0.2.2:4000/sessions/sessions/byfile?court=$courtName&recordType=$recordType&caseNumber=$caseNumber&caseYear=$caseYear';

    try {
      final response = await _makeAuthenticatedRequest(url);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          final List<dynamic> sessionsData = result['sessions'];
          setState(() {
            _sessions = sessionsData.cast<Map<String, dynamic>>();
            _errorMessage = null;
          });
        } else {
          setState(() {
            _sessions = [];
            _errorMessage = 'No session at this File';
          });
        }
      } else {
        setState(() {
          _sessions = [];
          _errorMessage = 'Failed to load data';
        });
        throw Exception('Failed to load cases');
      }
    } catch (e) {
      setState(() {
        _sessions = [];
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Sessiones', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
      ),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTab = 'today';
                      _sessions = [];
                      _errorMessage = null;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _selectedTab == 'today'
                          ? const Color(0xFF003366)
                          : Colors.white,
                      border: Border.all(color: const Color(0xFF003366)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: Text(
                      'Sessiones at Day',
                      style: TextStyle(
                        color: _selectedTab == 'today'
                            ? Colors.white
                            : const Color(0xFF003366),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Almarai',
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTab = 'file';
                      _sessions = [];
                      _errorMessage = null;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _selectedTab == 'file'
                          ? const Color(0xFF003366)
                          : Colors.white,
                      border: Border.all(color: const Color(0xFF003366)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: Text(
                      'Sessiones to File',
                      style: TextStyle(
                        color: _selectedTab == 'file'
                            ? Colors.white
                            : const Color(0xFF003366),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Almarai',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedTab == 'today') {
      return _buildTodaySessionsContent();
    } else {
      return _buildFileSessionsContent();
    }
  }

  Widget _buildTodaySessionsContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current Month : $_currentMonth',
                  style: const TextStyle(
                      color: Color(0xFF003366),
                      fontFamily: 'Almarai',
                      fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.calendar_today,
                    color: Color(0xFF003366)),
                onPressed: () {
                  _showCalendarDialog(context);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _sessions.isNotEmpty
              ? _buildSessionsList()
              : Center(
                  child: Text(_errorMessage ?? 'Theres no Sessiones at this day',
                      style: const TextStyle(fontFamily: 'Almarai')),
                ),
        ),
      ],
    );
  }

 void _showCalendarDialog(BuildContext context) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text('Choose the Date',
                  style: const TextStyle(
                      color: Color(0xFF003366),
                      fontFamily: 'Almarai',
                      fontWeight: FontWeight.bold)),
              content: Container(
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(10),
                 ),
                  width: 400,
                  height: 350,
                  child: LayoutBuilder(builder: (context, constraints) {
                    return CalendarCarousel(
                      height: 350,
                      width: 400,
                      onDayPressed: (DateTime date, List events) {
                        setState(() {
                          _selectedDate = date;
                          _currentMonth = DateFormat.yMMMM().format(date);
                          _currentDate = date;
                        });
                        _fetchSessionsForDate(date);
                        Navigator.pop(context);
                      },
                      weekendTextStyle: const TextStyle(
                        color: Color(0xFF003366),
                      ),
                      thisMonthDayBorderColor: Colors.transparent,
                      weekFormat: false,
                      markedDateShowIcon: true,
                      markedDateIconMaxShown: 1,
                      selectedDayBorderColor:  Colors.transparent,
                      daysHaveCircularBorder: false,
                      headerTextStyle: const TextStyle(
                          color: Color(0xFF003366),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Almarai'),
                      iconColor: const Color(0xFF003366),
                      todayButtonColor: Colors.transparent,
                      selectedDayButtonColor: Colors.transparent,
                      weekdayTextStyle: const TextStyle(
                          color: Color(0xFF003366), fontFamily: 'Almarai'),
                          customDayBuilder: (   bool isSelectable,
                          int index,
                          bool isSelectedDay,
                          bool isToday,
                          bool isPrevMonthDay,
                          TextStyle textStyle,
                          bool isNextMonthDay,
                          bool isThisMonthDay,
                          DateTime day,)
                      { return Center(
                        child:  Text(
                            day.day.toString(),
                           style: TextStyle(
                             color: isSelectable ? (isToday ? Colors.black :  (isThisMonthDay ?  Color(0xFF003366) : Colors.grey)) : Colors.grey
                           )
                        ),
                      );
                      },
                    );
                  })));
        });
  }
  Widget _buildFileSessionsContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _courtNameController,
              style: const TextStyle(
                  color: Color(0xFF003366), fontFamily: 'Almarai'),
              decoration: const InputDecoration(
                labelText: 'Court Name',
                labelStyle: TextStyle(
                    color: Color(0xFF003366), fontFamily: 'Almarai'),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF003366)),
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF003366)),
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _recordTypeController,
              style: const TextStyle(
                  color: Color(0xFF003366), fontFamily: 'Almarai'),
              decoration: const InputDecoration(
                labelText: 'Case Type',
                labelStyle: TextStyle(
                    color: Color(0xFF003366), fontFamily: 'Almarai'),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF003366)),
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF003366)),
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _caseNumberController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        color: Color(0xFF003366), fontFamily: 'Almarai'),
                    decoration: const InputDecoration(
                      labelText: 'Case Nubmer',
                      labelStyle: TextStyle(
                          color: Color(0xFF003366), fontFamily: 'Almarai'),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF003366)),
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF003366)),
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: TextFormField(
                    controller: _caseYearController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        color: Color(0xFF003366), fontFamily: 'Almarai'),
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      labelStyle: TextStyle(
                          color: Color(0xFF003366), fontFamily: 'Almarai'),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF003366)),
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF003366)),
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchSessionsForFile,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 30, vertical: 10)),
              child: const Text('Bring Session',
                  style: TextStyle(color: Colors.white, fontFamily: 'Almarai')),
            ),
            const SizedBox(height: 20),
            if (_sessions.isNotEmpty) _buildSessionsList(),
            if (_errorMessage != null)
              Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(fontFamily: 'Almarai'),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _sessions.length,
      separatorBuilder: (context, index) => const Divider(color: Colors.grey),
      itemBuilder: (context, index) {
        final session = _sessions[index];
        return Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: const Color(0xFF003366),
                )),
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Session Date: ${session['session_date']}',
                    style: const TextStyle(
                        color: Color(0xFF003366),
                        fontFamily: 'Almarai',
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Court Name: ${session['court_name'] ?? 'N/A'}',
                    style: const TextStyle(
                        color: Color(0xFF003366), fontFamily: 'Almarai')),
                Text('Court Type: ${session['court_type'] ?? 'N/A'}',
                    style: const TextStyle(
                        color: Color(0xFF003366), fontFamily: 'Almarai')),
                Text('Case Type: ${session['case_type'] ?? 'N/A'}',
                    style: const TextStyle(
                        color: Color(0xFF003366), fontFamily: 'Almarai')),
                Text('Case Number: ${session['case_number'] ?? 'N/A'}',
                    style: const TextStyle(
                        color: Color(0xFF003366), fontFamily: 'Almarai')),
                Text('Details: ${session['session_details'] ?? 'N/A'}',
                    style: const TextStyle(
                        color: Color(0xFF003366), fontFamily: 'Almarai')),
                // Add other fields if needed
              ],
            ));
      },
    );
  }
}
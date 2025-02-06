import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'TokenUtils.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  bool isLoading = true;
  late Timer _timer;

  Map<DateTime, List> events = {}; // لتخزين الجلسات بناءً على التاريخ
  DateTime? selectedDay;
  List selectedEvents = [];

  @override
  void initState() {
    super.initState();
    fetchAllSessions();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      TokenUtils.checkTokenExpiration(context);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> fetchAllSessions() async {
    try {
      var box = await Hive.openBox('userBox');
      final token = box.get('token');
      print('تم استرجاع التوكن: $token');

      if (token == null || token.isEmpty) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:4000/calender/calender'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        Map<DateTime, List> tempEvents = {};

        for (var session in data) {
          final date = DateTime.parse(session['date']).toUtc();
          final normalizedDate = DateTime.utc(date.year, date.month, date.day);
          if (!tempEvents.containsKey(normalizedDate)) {
            tempEvents[normalizedDate] = [];
          }
          tempEvents[normalizedDate]!.add(session);
        }

        setState(() {
          events = tempEvents;
          isLoading = false;
        });
      } else {
        print("خطأ في جلب الجلسات: ${response.body}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("حدث خطأ أثناء جلب البيانات: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            backgroundColor: Colors.white,

      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: selectedDay ?? DateTime.now(),
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            eventLoader: (day) {
              final normalizedDay = DateTime.utc(day.year, day.month, day.day);
              return events[normalizedDay]?.isNotEmpty == true
                  ? [events[normalizedDay]!.first] // عرض علامة واحدة فقط لكل يوم
                  : [];
            },
            onDaySelected: (selectedDay, focusedDay) {
              final normalizedDay =
                  DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day);
              setState(() {
                this.selectedDay = normalizedDay;
                selectedEvents = events[normalizedDay] ?? [];
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              markersMaxCount: 1, // يسمح بعلامة واحدة فقط لكل يوم
              markersAlignment: Alignment.bottomCenter,
              selectedDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              headerMargin: const EdgeInsets.only(bottom: 8),
              titleTextStyle: const TextStyle(
                color: Color(0xFF003366),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekendStyle: TextStyle(color: Colors.redAccent),
              weekdayStyle: TextStyle(color: Colors.blue),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : selectedEvents.isEmpty
                    ? const Center(child: Text('No case at this day'))
                    : ListView.builder(
                        itemCount: selectedEvents.length,
                        itemBuilder: (context, index) {
                          final event = selectedEvents[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF003366).withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              title: Text(
                                event['details'],
                                style: const TextStyle(
                                  color: Color(0xFF003366),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                "الحالة: ${event['status']}",
                                style: const TextStyle(color: Color(0xFF003366)),
                              ),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("تفاصيل الجلسة"),
                                    content: Text(
                                      "التفاصيل: ${event['details']}\nالحالة: ${event['status']}",
                                      style: const TextStyle(
                                          color: Color(0xFF003366)),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          if (mounted) {
                                            Navigator.pop(context);
                                          }
                                        },
                                        child: const Text("إغلاق"),
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

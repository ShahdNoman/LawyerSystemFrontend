import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
class Home11screen extends StatefulWidget {
  const Home11screen({super.key});
  @override
  _Home11screenState createState() => _Home11screenState();
}
class _Home11screenState extends State<Home11screen> {
  bool isLoading = true;
  Map<String, dynamic> stats = {};
  Map<String, dynamic> caseChart = {};
  List<Map<String, dynamic>> recentCases = [];
  late Timer _timer;
  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      // التحقق من صلاحية التوكن كل 30 ثانية
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
  Future<void> _fetchData() async {
  try {
    var box = await Hive.openBox('userBox');
    final token = box.get('token');

    if (token == null || token.isEmpty) {
      Navigator.pushReplacementNamed(context, '/');
      return;
    }

    final response = await http.get(
      Uri.parse('http://10.0.2.2:4000/home/home'), // API من Express
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // التأكد من إرسال التوكن
      },
    );
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      setState(() {
        stats = result['stats'];
        caseChart = result['caseChart'];
        recentCases = List<Map<String, dynamic>>.from(result['recentCases']);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
        throw Exception('Failed to load data');
      });
    }
  } catch (e) {
    setState(() {
      isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    List<BarChartGroupData> barChartGroups = [];
    caseChart.forEach((key, value) {
      barChartGroups.add(
        BarChartGroupData(
          x: barChartGroups.length,
          barRods: [
            BarChartRodData(
              y: value.toDouble(),
              colors: [_getColorForCaseType(key)],
              width: 15,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ],
        ),
      );
    });

    return Scaffold(
            backgroundColor: Colors.white,

      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 150,
                                    child: PieChart(
                                      PieChartData(
                                        centerSpaceRadius: 40,
                                        sections: [
                                          PieChartSectionData(
                                            value: stats['openCases']
                                                    ?.toDouble() ??
                                                0,
                                            color: Colors.blue,
                                            title: 'Open',
                                            radius: 20,
                                          ),
                                          PieChartSectionData(
                                            value: stats['closedCases']
                                                    ?.toDouble() ??
                                                0,
                                            color: Colors.green,
                                            title: 'Closed',
                                            radius: 20,
                                          ),
                                          PieChartSectionData(
                                            value: stats['executionCases']
                                                    ?.toDouble() ??
                                                0,
                                            color: Colors.red,
                                            title: 'Execution',
                                            radius: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Case Status',
                                    style: TextStyle(
                                        fontSize: 16,
                                     color:const Color(0xFF003366),                                             fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 150,
                                    child: BarChart(
                                      BarChartData(
                                        titlesData: FlTitlesData(
                                          leftTitles: SideTitles(
                                            showTitles: true,
                                            getTitles: (value) {
                                              return value % 1 == 0
                                                  ? '${value.toInt()}'
                                                  : '';
                                            },
                                            reservedSize: 28,
                                            margin: 12,
                                            getTextStyles: (context, value) =>
                                                const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black),
                                          ),
                                          rightTitles:
                                              SideTitles(showTitles: false),
                                          bottomTitles: SideTitles(
                                            showTitles: true,
                                            getTitles: (double value) {
                                              return caseChart.keys
                                                  .elementAt(value.toInt());
                                            },
                                            margin: 12,
                                            getTextStyles: (context, value) =>
                                                const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black),
                                          ),
                                        ),
                                        gridData: FlGridData(show: false),
                                        borderData: FlBorderData(
                                            show: true,
                                            border: Border.all(
                                                color: Colors.grey)),
                                        barGroups: barChartGroups,
                                        barTouchData: BarTouchData(
                                          touchTooltipData:
                                              BarTouchTooltipData(
                                            tooltipBgColor: Colors.blueAccent,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Case Distribution ',
                                    style: TextStyle(
                                      color: const Color(0xFF003366),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold
                                        ),
                                  ),
                                ],//                                                                        fontWeight: FontWeight.bold),

                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Latest Cases:",
                       style: TextStyle(
                                      color: const Color(0xFF003366),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold
                                        ),
                      
                      
                    ),
                    const SizedBox(height: 10),
                    recentCases.isEmpty
                        ? Center(
                            child: Text(
                              "No recent cases available.",
                              style: TextStyle(
                              color: const Color(0xFF003366),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: recentCases.length,
                            itemBuilder: (context, index) {
                              var caseData = recentCases[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 8),
                                child: ListTile(
                                  title: Text(
                                    "Case #${caseData['case_number']}",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF003366)),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      RichText(
  text: TextSpan(
    style: TextStyle(fontSize: 16.0), // يمكن تعديل حجم النص حسب الحاجة
    children: [
      TextSpan(
        text: "Type: ",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF003366), // اللون الأزرق
        ),
      ),
      TextSpan(
        text: "${caseData['case_type']}\n",
        style: TextStyle(
          color: Color.fromARGB(255, 78, 72, 72), // اللون الأزرق
        ),
      ),
      TextSpan(
        text: "Status: ",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF003366), // اللون الأزرق
        ),
      ),
      TextSpan(
        text: "${caseData['case_status']}\n",
        style: TextStyle(
          color: Color.fromARGB(255, 78, 72, 72), // اللون الأزرق
        ),
      ),
      TextSpan(
        text: "Court: ",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF003366), // اللون الأزرق
        ),
      ),
      TextSpan(
        text: "${caseData['court_name']}",
        style: TextStyle(
          color: Color.fromARGB(255, 78, 72, 72), // اللون الأزرق
        ),
      ),
    ],
  ),
),

                                      
                                    ],
                                  ),
                                  trailing: Icon(Icons.arrow_forward),iconColor: Color(0xFF003366),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Color _getColorForCaseType(String caseType) {
    switch (caseType) {
      case 'Civil':
        return Colors.purple;
      case 'Criminal':
        return Colors.orange;
      case 'Execution':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}


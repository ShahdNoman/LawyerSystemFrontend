import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pdfx/pdfx.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'NewCaseScreen.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});

  @override
  _CasesScreenState createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  List<Map<String, dynamic>> _allCases = [];
  List<Map<String, dynamic>> cases = [];
  bool isLoading = true;
  String _selectedCaseStatus = 'All';
  final List<String> _searchOptions = [
    'Party Name',
    'Case Number',
    'Court Name',
    'ID Number',
  ];
  String? _selectedSearchOption;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAllCases();
  }

  Future<void> _fetchAllCases({
    String search = '',
    String caseStatus = '',
    String searchOption = '',
  }) async {
    setState(() {
      isLoading = true;
      cases = [];
    });
    try {
      var box = await Hive.openBox('userBox');
      final token = box.get('token');

      if (token == null || token.isEmpty) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }
      String url = 'http://10.0.2.2:4000/cases/cases';

      if (caseStatus.isNotEmpty && caseStatus != 'All') {
        url += '?case_status=$caseStatus';
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
          _allCases = List<Map<String, dynamic>>.from(result['cases']);
          _filterAndSearchCases(
            search: search,
            caseStatus: caseStatus,
            searchOption: searchOption,
          );
        } else {
          setState(() {
            isLoading = false;
            cases = [];
            _allCases = [];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('There is no cases with this filter .')),
          );
        }
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception('Failed to load cases');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to connect to the server: ${e.toString()}')),
      );
    }
  }

  void _filterAndSearchCases({
    required String search,
    required String caseStatus,
    required String searchOption,
  }) {
    List<Map<String, dynamic>> filteredCases = _allCases;

    if (caseStatus != 'All' && caseStatus.isNotEmpty) {
      if (caseStatus == ' Recycled ') {
        filteredCases = filteredCases
            .where((caseData) => caseData['case_status'] == 'Ongoing')
            .toList();
      } else {
        filteredCases = filteredCases
            .where((caseData) => caseData['case_status'] == 'Closed')
            .toList();
      }
    }

    if (search.isNotEmpty && searchOption.isNotEmpty) {
      filteredCases = filteredCases.where((caseData) {
        search = search.toLowerCase();
        switch (searchOption) {
          case 'Party Name':
            return _checkPartyName(caseData, search);
          case 'Case Number':
            return (caseData['case_number'] ?? '').toLowerCase() == search;
          case 'Court Name':
            return (caseData['court_name'] ?? '').toLowerCase() == search;
          case 'ID Number':
            return _checkPartyId(caseData, search);
          default:
            return true;
        }
      }).toList();
    }

    setState(() {
      cases = filteredCases;
      isLoading = false;
    });
    if (cases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There is no cases with this filter .')),
      );
    }
  }

  bool _checkPartyName(Map<String, dynamic> caseData, String search) {
    final plaintiffName = (caseData['plaintiff']?['name'] ?? '').toLowerCase();
    final defendantName = (caseData['defendant']?['name'] ?? '').toLowerCase();
    final plaintiffLawyerName =
        (caseData['plaintiffLawyer']?['name'] ?? '').toLowerCase();
    final defendantLawyerName =
        (caseData['defendantLawyer']?['name'] ?? '').toLowerCase();

    final otherPartiesNames = (caseData['otherParties'] as List<dynamic>?)
            ?.map((party) => (party['name'] ?? '').toLowerCase())
            .toList() ??
        [];

    return plaintiffName.contains(search) ||
        defendantName.contains(search) ||
        plaintiffLawyerName.contains(search) ||
        defendantLawyerName.contains(search) ||
        otherPartiesNames.any((name) => name.contains(search));
  }

  bool _checkPartyId(Map<String, dynamic> caseData, String search) {
    final plaintiffId =
        (caseData['plaintiff']?['id_number'] ?? '').toString().toLowerCase();
    final defendantId =
        (caseData['defendant']?['id_number'] ?? '').toString().toLowerCase();
    final plaintiffLawyerId = (caseData['plaintiffLawyer']?['id_number'] ?? '')
        .toString()
        .toLowerCase();
    final defendantLawyerId = (caseData['defendantLawyer']?['id_number'] ?? '')
        .toString()
        .toLowerCase();

    final otherPartiesIds = (caseData['otherParties'] as List<dynamic>?)
            ?.map(
                (party) => (party['id_number'] ?? '').toString().toLowerCase())
            .toList() ??
        [];

    return plaintiffId.contains(search) ||
        defendantId.contains(search) ||
        plaintiffLawyerId.contains(search) ||
        defendantLawyerId.contains(search) ||
        otherPartiesIds.any((id) => id.contains(search));
  }

  void _filterCases(String caseStatus) {
    setState(() {
      _selectedCaseStatus = caseStatus;
    });
    _filterAndSearchCases(
      search: _searchController.text,
      caseStatus: caseStatus,
      searchOption: _selectedSearchOption ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cases List', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
      ),
         body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
            children: [
            Column(
                children: [
                Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Column(
                    children: [
                        Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            SizedBox(
                            height: 38,
                            child: Container(
                                decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15.0),
                                border: Border.all(
                                    color: _selectedSearchOption != null
                                        ? const Color(0xFF003366)
                                        : const Color(0xFF003366),
                                    width: 1.5),
                                ),
                                alignment: Alignment.center,
                                child: DropdownButton<String>(
                                isDense: true,
                                value: _selectedSearchOption,
                                hint: Text(
                                    "Search By",
                                    style: const TextStyle(
                                    color: Color(0xFF003366),
                                    fontFamily: 'Almarai',
                                    ),
                                ),
                                items: _searchOptions.map((String value) {
                                    return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                        value,
                                        style: const TextStyle(
                                        color: Color(0xFF003366),
                                        fontFamily: 'Almarai',
                                        ),
                                    ),
                                    );
                                }).toList(),
                                onChanged: (newValue) {
                                    setState(() {
                                    _selectedSearchOption = newValue;
                                    });
                                },
                                style: const TextStyle(fontFamily: 'Almarai'),
                                dropdownColor: Colors.white,
                                underline: const SizedBox(),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                ),
                            ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                            child: SizedBox(
                                height: 38,
                                child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15.0),
                                    border: Border.all(
                                        color: const Color(0xFF003366),
                                        width: 1.5),
                                ),
                                child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                        hintText: 'Search Here...',
                                        hintStyle: const TextStyle(
                                            fontFamily: 'Almarai',
                                            color: Color(0xFF003366)),
                                        border: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        suffixIcon: IconButton(
                                            icon: const Icon(
                                            Icons.search,
                                            color: Color(0xFF003366),
                                            ),
                                            onPressed: () {
                                            _fetchAllCases(
                                                search: _searchController.text,
                                                caseStatus: _selectedCaseStatus,
                                                searchOption:
                                                    _selectedSearchOption ??
                                                        '');
                                            },
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 4.0, horizontal: 8.0),
                                        isDense: true),
                                    textAlignVertical: TextAlignVertical.center,
                                    textAlign: TextAlign.start,
                                    style: const TextStyle(
                                    fontFamily: 'Almarai',
                                    color: Color(0xFF003366),
                                    ),
                                    onSubmitted: (value) {
                                    _fetchAllCases(
                                        search: value,
                                        caseStatus: _selectedCaseStatus,
                                        searchOption:
                                            _selectedSearchOption ?? '');
                                    },
                                ),
                                )),
                            ),
                        ],
                        ),
                    ],
                    ),
                ),
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                        ElevatedButton(
                        onPressed: () {
                            _filterCases('All');
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedCaseStatus == 'All'
                                ? const Color(0xFF003366)
                                : Colors.white,
                            side: BorderSide(
                            color: _selectedCaseStatus != 'All'
                                ? const Color(0xFF003366)
                                : Colors.transparent,
                            ),
                            shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            ),
                            foregroundColor: _selectedCaseStatus == 'All'
                                ? Colors.white
                                : const Color(0xFF003366)),
                        child: Text(
                            'All',
                            style: TextStyle(fontFamily: 'Almarai'),
                        ),
                        ),
                        ElevatedButton(
                        onPressed: () {
                            _filterCases(' Recycled ');
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedCaseStatus == ' Recycled '
                                ? const Color(0xFF003366)
                                : Colors.white,
                            side: BorderSide(
                            color: _selectedCaseStatus != ' Recycled '
                                ? const Color(0xFF003366)
                                : Colors.transparent,
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0)),
                            foregroundColor: _selectedCaseStatus == ' Recycled '
                                ? Colors.white
                                : const Color(0xFF003366)),
                        child: Text(
                            ' Recycled Cases',
                            style: TextStyle(fontFamily: 'Almarai'),
                        ),
                        ),
                        ElevatedButton(
                        onPressed: () {
                            _filterCases('dismissed');
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedCaseStatus == 'dismissed'
                                ? const Color(0xFF003366)
                                : Colors.white,
                            side: BorderSide(
                            color: _selectedCaseStatus != 'dismissed'
                                ? const Color(0xFF003366)
                                : Colors.transparent,
                            ),
                            shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            ),
                            foregroundColor: _selectedCaseStatus == 'dismissed'
                                ? Colors.white
                                : const Color(0xFF003366)),
                        child: Text(
                            'dismissed Cases',
                            style: TextStyle(fontFamily: 'Almarai'),
                        ),
                        ),
                    ],
                    ),
                ),
                Expanded(
                    child: cases.isEmpty
                        ? const Center(
                            child: Text('No Cases'),
                            )
                        : ListView.separated(
                            itemCount: cases.length,
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            separatorBuilder: (context, index) => const Divider(
                                color: Colors.grey,
                                height: 1,
                            ),
                            itemBuilder: (context, index) {
                            final caseData = cases[index];
                            return Container(
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(
                                    color: const Color(0xFF003366),
                                    )),
                                margin: const EdgeInsets.symmetric(vertical: 4.0),
                                child: ListTile(
                                title: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                    Expanded(
                                        child: Text(
                                        caseData['court_name'] ?? 'N/A',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF003366),
                                            fontFamily: 'Almarai',
                                        ),
                                        ),
                                    ),
                                    ],
                                ),
                                subtitle: Row(
                                    children: [
                                    Text(
                                        'Case Type: ${caseData['case_type'] ?? 'N/A'}',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Almarai',
                                            color: Colors.black87),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                        'Case Number: ${caseData['case_number'] ?? 'N/A'}',
                                        style: const TextStyle(
                                            fontFamily: 'Almarai',
                                            color: Colors.black87),
                                    ),
                                    ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    color: Color(0xFF003366)),
                                onTap: () {
                                    Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            CaseDetailsScreen(caseData: caseData),
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
                Positioned(
                    bottom: 16,
                    right: 16,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NewCaseScreen(),
                          ),
                        );
                      },
                      child: Container(
                          padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF003366),
                              borderRadius: BorderRadius.circular(20)
                            ),
                        child: const Text(
                            '+',
                            style: TextStyle(fontSize: 30,
                            color: Colors.white,
                                fontWeight: FontWeight.bold),
                                ),
                      ),
                    ),
                ),
            ],
          ),
    );
  }
}
class CaseDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> caseData;

  const CaseDetailsScreen({super.key, required this.caseData});

  @override
  _CaseDetailsScreenState createState() => _CaseDetailsScreenState();
}

class _CaseDetailsScreenState extends State<CaseDetailsScreen> {
  String _selectedBottomTab = 'Details';

  final Map<String, bool> _expandedState = {
    'aboutCase': false,
    'prosecutionInfo': false,
    'parties': false,
    'judgePanel': false,
    'notes': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.caseData['court_name'] ?? 'Case Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: const Color(0xFF003366),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildExpandableSection(
                  header: 'About case',
                  key: 'aboutCase',
                  content: _buildInfoColumn(
                    [
                      _buildTextWithLabel(
                        label: 'Case Number:',
                        text: widget.caseData['case_number'] ?? 'غير متوفر',
                      ),
                      _buildTextWithLabel(
                        label: 'Case Type:',
                        text: widget.caseData['case_type'] ?? 'غير متوفر',
                      ),
                      _buildTextWithLabel(
                        label: 'Date Filed:',
                        text: widget.caseData['date_of_roses'] ?? 'غير متوفر',
                      ),
                    ],
                  ),
                ),
                _buildExpandableSection(
                  header: 'Court Information',
                  key: 'prosecutionInfo',
                  content: _buildInfoColumn(
                    [
                      _buildTextWithLabel(
                        label: 'Court Name:',
                        text: widget.caseData['court_name'] ?? 'غير متوفر',
                      ),
                      _buildTextWithLabel(
                        label: 'Court Type:',
                        text: widget.caseData['court_type'] ?? 'غير متوفر',
                      ),
                    ],
                  ),
                ),
                _buildExpandableSection(
                  header: 'Parties to the lawsuit',
                  key: 'parties',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPartyInfo(
                        label: 'Plaintiff:',
                        name: widget.caseData['plaintiff']?['name'],
                        idNumber: widget.caseData['plaintiff']?['id_number'],
                      ),
                      _buildPartyInfo(
                        label: 'Defendant:',
                        name: widget.caseData['defendant']?['name'],
                        idNumber: widget.caseData['defendant']?['id_number'],
                      ),
                      _buildPartyInfo(
                        label: 'Plaintiffs Attorney (Lawyer):',
                        name: widget.caseData['plaintiffLawyer']?['name'],
                        idNumber: widget.caseData['plaintiffLawyer']
                            ?['id_number'],
                      ),
                      _buildPartyInfo(
                        label: 'Defendants Attorney (Lawyer):',
                        name: widget.caseData['defendantLawyer']?['name'],
                        idNumber: widget.caseData['defendantLawyer']
                            ?['id_number'],
                      ),
                      if (widget.caseData['otherParties'] != null &&
                          widget.caseData['otherParties'].isNotEmpty)
                        ...widget.caseData['otherParties']
                            .map((party) => _buildPartyInfo(
                                  label: party['party_type'] == 'witness'
                                      ? 'Witness:'
                                      : 'Other Party:',
                                  name: party['name'],
                                  idNumber: party['id_number'],
                                )),
                    ],
                  ),
                ),
                _buildExpandableSection(
                  header: 'governing  body',
                  key: 'judgePanel',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPartyInfo(
                        label: 'Judge :',
                        name: widget.caseData['judge']?['name'],
                        idNumber: widget.caseData['judge']?['id_number'],
                      ),
                    ],
                  ),
                ),
                _buildExpandableSection(
                  header: 'Notes',
                  key: 'notes',
                  content: Text(
                    widget.caseData['note'] ?? 'No notes available.',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomTabs(),
        ],
      ),
    );
  }

  Widget _buildTextWithLabel({
    required String label,
    required String text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003366),
              fontFamily: 'Almarai'),
        ),
        Text(
          text,
          style: const TextStyle(fontSize: 16, fontFamily: 'Almarai'),
        ),
        const SizedBox(height: 8),
        const Divider(
          color: Colors.grey,
          height: 1,
          thickness: 0.5,
        ),
      ],
    );
  }

  Widget _buildInfoColumn(List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...children,
      ],
    );
  }

  Widget _buildPartyInfo({
    required String label,
    String? name,
    String? idNumber,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003366),
              fontFamily: 'Almarai'),
        ),
        Row(children: [
          Text(
            name ?? 'غير متوفر',
            style: const TextStyle(fontSize: 16, fontFamily: 'Almarai'),
          ),
          Text(
            ' ($idNumber)' ?? '',
            style: const TextStyle(
                fontSize: 14, color: Colors.grey, fontFamily: 'Almarai'),
          ),
        ]),
        const SizedBox(height: 8),
        const Divider(
          color: Colors.grey,
          height: 1,
          thickness: 0.5,
        ),
      ],
    );
  }

  Widget _buildExpandableSection({
    required String header,
    required String key,
    required Widget content,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedState[key] = !_expandedState[key]!;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF003366), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF003366).withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    header,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003366),
                        fontFamily: 'Almarai'),
                  ),
                  Icon(
                    _expandedState[key]!
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                    color: const Color(0xFF003366),
                  ),
                ],
              ),
            ),
            if (_expandedState[key]!)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: content,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomTabs() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF003366),
        border: Border(top: BorderSide(color: Colors.grey, width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomTabButton(
            icon: Icons.list_alt,
            text: 'Details',
          ),
          _buildBottomTabButton(
            icon: Icons.calendar_today,
            text: 'Sessions',
            iconAssetPath: 'web/icons/session.png',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SessionsScreen(
                    sessions: widget.caseData['sessions'] ?? [],
                  ),
                ),
              );
            },
          ),
          _buildBottomTabButton(
              icon: Icons.attach_file,
              text: 'Attachments ',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AttachmentsScreen(caseData: widget.caseData),
                  ),
                );
              }),
          _buildBottomTabButton(
            icon: Icons.payment,
            text: 'Executive payments',
            iconAssetPath: 'web/icons/money.png',
           onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ExecutivePaymentsScreen(
                    caseData: widget.caseData,
                ),
            ),
        );
    },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTabButton({
    required IconData icon,
    required String text,
    String? iconAssetPath,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ??
          () {
            setState(() {
              _selectedBottomTab = text;
            });
          },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconAssetPath != null)
              Image.asset(
                iconAssetPath,
                width: 25,
                height: 25,
                color: Colors.white,
              )
            else
              Icon(icon, color: Colors.white),
            if (_selectedBottomTab == text)
              Text(
                text,
                style: const TextStyle(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}

class ExecutivePaymentsScreen extends StatefulWidget {
  final Map<String, dynamic> caseData;

  const ExecutivePaymentsScreen({super.key, required this.caseData});

  @override
  _ExecutivePaymentsScreenState createState() => _ExecutivePaymentsScreenState();
}

class _ExecutivePaymentsScreenState extends State<ExecutivePaymentsScreen> {
  List<Map<String, dynamic>> _allPayments = [];
  List<Map<String, dynamic>> payments = [];
  bool isLoading = true;
  int? _currentUserId;
  Map<int, bool> _isDisbursedUpdating = {};
  Map<int, dynamic> _caseDetailsCache = {};
  final String _publishableKey = "pk_test_51QlULHGgPcncAP5JnEayNzR6Hs4rdogMrpPJZdgFqZ4tMAEUUb3y7Oeejj82n7JKrjjKswnKXNaN4r7DmGSVdTcY00aesEhYrQ";
  String? _caseId;
  @override
  void initState() {
    super.initState();
     stripe.Stripe.publishableKey = _publishableKey;
      // Print caseData for debugging
    print('Case Data received in ExecutivePaymentsScreen:');
    print(widget.caseData);
    _caseId = widget.caseData['id']?.toString();
    // Use addPostFrameCallback to delay using ScaffoldMessenger
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (_caseId == null) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Case ID is missing')));
           print("Error: caseData['_id'] is null.");
           return;
       }
        _fetchPayments();
    });

  }
  Future<void> _fetchPayments() async {
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
        if(_caseId == null) {
          return;
        }
        final url = 'http://10.0.2.2:4000/payment/payment';

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
           _filterPayments();
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


   void _filterPayments() {
    if(_caseId == null) {
          return;
     }
     final int caseId = int.parse(_caseId!);
     final List<Map<String, dynamic>> filteredPayments = _allPayments
         .where((payment) => payment['case_id'] == caseId)
        .toList();
     setState(() {
        payments = filteredPayments;
       isLoading = false;
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
        title: const Text('Executive Payments'),
        backgroundColor: const Color(0xFF003366),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
       floatingActionButton: FloatingActionButton(
        onPressed: () {
          if(_caseId != null) {
           _showNewPaymentDialog(_currentUserId, int.parse(_caseId!));
          }
        },
          child: const Icon(Icons.add, color: Colors.white),
           backgroundColor: const Color(0xFF003366),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
         : payments.isEmpty
            ? const Center(
                  child: Text('No Payments available for this case.',
                       style: TextStyle(
                          fontFamily: 'Almarai', fontSize: 18)),
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
   Future<void> _showNewPaymentDialog(int? userId, int caseId) async {
     final _formKey = GlobalKey<FormState>();
       final _amountController = TextEditingController();
        final _cardDetails = CardDetails();

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
                       Text('Case ID: $caseId',
                       style: const TextStyle(fontWeight: FontWeight.bold),
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
                       final result = await _handleNewPayment(caseId,int.parse(_amountController.text),_cardDetails,userId);
                           setState(() {
                              isLoading = false;
                           });
                         if (result) {
                           Navigator.of(context).pop();
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

// sessions_screen.dart

class SessionsScreen extends StatelessWidget {
  final List<dynamic> sessions;

  const SessionsScreen({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessions Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: const Color(0xFF003366),
      ),
      body: sessions.isEmpty
          ? const Center(child: Text('No sessions available for this case.'))
          : ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _buildSessionCard(session);
              },
            ),
    );
  }

  Widget _buildSessionCard(dynamic session) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: const Color(0xFF003366), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003366).withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSessionDetail(
            label: 'Session Date',
            value: session['session_date'] ?? 'N/A',
          ),
          _buildSessionDetail(
            label: 'Details',
            value: session['session_details'] ?? 'N/A',
          ),
          _buildSessionDetail(
            label: 'Status',
            value: session['session_status'] ?? 'N/A',
          ),
          if (session['next_session_date'] != null)
            _buildSessionDetail(
              label: 'Next Session Date',
              value: session['next_session_date'] ?? 'N/A',
            ),
        ],
      ),
    );
  }

  Widget _buildSessionDetail({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF003366),
            fontFamily: 'Almarai',
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontFamily: 'Almarai'),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class AttachmentsScreen extends StatefulWidget {
  final Map<String, dynamic> caseData;

  const AttachmentsScreen({super.key, required this.caseData});

  @override
  _AttachmentsScreenState createState() => _AttachmentsScreenState();
}

class _AttachmentsScreenState extends State<AttachmentsScreen> {
  Map<String, PdfControllerPinch?> _pdfControllers = {};
  Map<String, String> _errorMessages = {};
  String _selectedAttachmentFile = '';
  double _scale = 1.0; // متغير للتحكم في التكبير والتصغير
  final double _minScale = 0.5; // الحد الأدنى للتكبير
  final double _maxScale = 3.0; // الحد الأقصى للتكبير


  @override
  Widget build(BuildContext context) {
    final attachments = widget.caseData['attachments'] as List<dynamic>;
    print('Attachments Data: ${widget.caseData}');
    print('Number of attachments: ${attachments.length}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attachments'),
        backgroundColor: const Color(0xFF003366),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: attachments.isEmpty
          ? const Center(
              child: Text('No attachments for this case.',
                  style: TextStyle(fontFamily: 'Almarai', fontSize: 18)))
          : ListView.builder(
              itemCount: attachments.length,
              itemBuilder: (context, index) {
                final attachment = attachments[index];
                return _buildAttachmentItem(attachment);
              },
            ),
    );
  }

  Widget _buildAttachmentItem(dynamic attachment) {
    final fileName = attachment['file_path'] as String? ?? 'N/A';
    final uploadDate = attachment['upload_time'] != null
        ? 'Upload Date: ${attachment['upload_time'].toString().substring(0, 10)}'
        : 'Upload Date: N/A';
    final isPdfVisible =
        _pdfControllers.containsKey(fileName) && _pdfControllers[fileName] != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFF003366), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003366).withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              fileName,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Almarai',
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            subtitle: Text(
              uploadDate,
              style: const TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Almarai',fontWeight: FontWeight.bold),
            ),
            onTap: () => _loadPdf(attachment),
          ),
          if (isPdfVisible)
            Container(
             decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF003366), width: 1),
                borderRadius: BorderRadius.circular(8.0)
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                   Padding(
                    padding: const EdgeInsets.only(right: 5.0,top: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                            IconButton(
                              onPressed: () {
                                _zoomIn();
                                },
                              icon: const Icon(Icons.zoom_in, color: const Color(0xFF003366),)
                            ),
                            IconButton(
                                  onPressed: () {
                                    _zoomOut();
                                    },
                                  icon: const Icon(Icons.zoom_out, color: const Color(0xFF003366),)
                              ),
                             IconButton(
                             onPressed: (){
                                setState(() {
                            _pdfControllers.remove(fileName);
                             if (_errorMessages.containsKey(fileName)) {
                             _errorMessages.remove(fileName);
                            }
                          });
                            },
                             icon: const Icon(Icons.close,color: Colors.red,)),

                      ],
                    ) ,
                    ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 300, // تحديد حد أقصى لارتفاع الـ PDF
                    ),
                    child: _pdfView(fileName),
                  ),
                ],
              ),
            ),
          if (_errorMessages.containsKey(fileName) &&
              _errorMessages[fileName]!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(_errorMessages[fileName]!,
                  style: const TextStyle(fontFamily: 'Almarai')),
            )
        ],
      ),
    );
  }

   void _zoomIn() {
    setState(() {
      _scale = (_scale + 0.2).clamp(_minScale, _maxScale);
    });
  }

   void _zoomOut() {
    setState(() {
      _scale = (_scale - 0.2).clamp(_minScale, _maxScale);
    });
  }


  Future<void> _loadPdf(dynamic attachment) async {
    final fileName = attachment['file_path'] as String? ?? 'N/A';
    if (_pdfControllers.containsKey(fileName)) {
      if (_pdfControllers[fileName] != null) {
        return;
      }
    }

    PdfDocument? document;
    try {
      document = await PdfDocument.openAsset('assets/pdf/$fileName');
      if (document.pagesCount == 0) {
        setState(() {
          _pdfControllers[fileName] = null;
          _errorMessages[fileName] = 'فشل في تحميل الملف PDF';
        });
        return;
      }
      setState(() {
        _pdfControllers[fileName] =
            PdfControllerPinch(document: PdfDocument.openAsset('assets/pdf/$fileName'));
        _errorMessages[fileName] = '';
      });
    } on PlatformException catch (e) {
      setState(() {
        _pdfControllers[fileName] = null;
        _errorMessages[fileName] = 'حدث خطأ: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _pdfControllers[fileName] = null;
        _errorMessages[fileName] = 'حدث خطأ غير متوقع: $e';
      });
    }
  }

  Widget _pdfView(String fileName) {
     return Transform.scale(
      scale: _scale,
      child: PdfViewPinch(
        controller: _pdfControllers[fileName]!,
      ),
    );
  }
}

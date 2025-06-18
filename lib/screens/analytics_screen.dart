import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/omron_data.dart';
import '../services/database_service.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<OmronData> _data = [];
  List<String> _patientNames = [];
  String? _selectedPatient;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _databaseService.getAllOmronData();
      final patients = await _databaseService.getPatientNames();
      
      setState(() {
        _data = data;
        _patientNames = patients;
        if (_patientNames.isNotEmpty && _selectedPatient == null) {
          _selectedPatient = _patientNames.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Gagal memuat data: $e');
    }
  }

  List<OmronData> get _filteredData {
    if (_selectedPatient == null) return _data;
    return _data.where((d) => d.patientName == _selectedPatient).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('Analisis Data'),
      backgroundColor: Colors.orange[700],
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        if (_patientNames.length > 1)
          PopupMenuButton<String>(
            onSelected: (patient) {
              setState(() {
                _selectedPatient = patient;
              });
            },
            itemBuilder: (context) => _patientNames.map((name) => 
              PopupMenuItem(
                value: name,
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: name == _selectedPatient ? Colors.orange[700] : Colors.grey[600],
                    ),
                    SizedBox(width: 8),
                    Text(name),
                    if (name == _selectedPatient)
                      Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check, color: Colors.orange[700], size: 16),
                      ),
                  ],
                ),
              ),
            ).toList(),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Icon(Icons.person),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.orange[700]),
          SizedBox(height: 16),
          Text('Memuat data analisis...'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_data.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildOverallStats(),
          SizedBox(height: 16),
          if (_selectedPatient != null) ...[
            _buildPatientStats(),
            SizedBox(height: 16),
            _buildLatestMeasurement(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Tidak ada data untuk analisis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Belum ada data yang tersimpan',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.add),
            label: Text('Input Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStats() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, color: Colors.orange[700]),
                SizedBox(width: 8),
                Text(
                  'Statistik Keseluruhan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Pasien',
                    '${_patientNames.length}',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Pengukuran',
                    '${_data.length}',
                    Icons.assignment,
                    Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Pengukuran Hari ini',
                    '${_getTodayMeasurements()}',
                    Icons.today,
                    Colors.purple,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Pengukuran Minggu ini',
                    '${_getWeekMeasurements()}',
                    Icons.date_range,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientStats() {
    if (_selectedPatient == null || _filteredData.isEmpty) {
      return SizedBox.shrink();
    }

    final patientData = _filteredData;
    final firstMeasurement = patientData.last.timestamp;
    final lastMeasurement = patientData.first.timestamp;
    final daysBetween = lastMeasurement.difference(firstMeasurement).inDays;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.blue[700]),
                SizedBox(width: 8),
                Text(
                  'Statistik $_selectedPatient',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Pengukuran',
                    '${patientData.length}',
                    Icons.assignment_turned_in,
                    Colors.teal,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Periode (Hari)',
                    '${daysBetween + 1}',
                    Icons.calendar_today,
                    Colors.indigo,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Pengukuran Pertama',
                    DateFormat('dd/MM/yy').format(firstMeasurement),
                    Icons.first_page,
                    Colors.grey,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Pengukuran Terakhir',
                    DateFormat('dd/MM/yy').format(lastMeasurement),
                    Icons.last_page,
                    Colors.brown,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestMeasurement() {
    if (_selectedPatient == null || _filteredData.isEmpty) {
      return SizedBox.shrink();
    }

    final latestData = _filteredData.first;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: Colors.green[700]),
                SizedBox(width: 8),
                Text(
                  'Pengukuran Terakhir',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(latestData.timestamp),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMeasurementItem(
                    'Berat Badan',
                    '${latestData.weight.toStringAsFixed(1)} kg',
                    Icons.scale,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildMeasurementItem(
                    'BMI',
                    latestData.bmi.toStringAsFixed(1),
                    Icons.straighten,
                    _getBMIColor(latestData.bmi),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMeasurementItem(
                    'Body Fat',
                    '${latestData.bodyFatPercentage.toStringAsFixed(1)}%',
                    Icons.fitness_center,
                    Colors.red,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildMeasurementItem(
                    'Muscle',
                    '${latestData.skeletalMusclePercentage.toStringAsFixed(1)}%',
                    Icons.sports_gymnastics,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getBMIColor(latestData.bmi).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getBMIColor(latestData.bmi).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Status BMI',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    latestData.bmiCategory,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getBMIColor(latestData.bmi),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods
  int _getTodayMeasurements() {
    final today = DateTime.now();
    return _data.where((data) => 
      data.timestamp.year == today.year &&
      data.timestamp.month == today.month &&
      data.timestamp.day == today.day
    ).length;
  }

  int _getWeekMeasurements() {
    final now = DateTime.now();
    final weekAgo = now.subtract(Duration(days: 7));
    return _data.where((data) => data.timestamp.isAfter(weekAgo)).length;
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;      // Underweight
    if (bmi < 25.0) return Colors.green;     // Normal
    if (bmi < 30.0) return Colors.orange;    // Overweight
    return Colors.red;                       // Obese
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
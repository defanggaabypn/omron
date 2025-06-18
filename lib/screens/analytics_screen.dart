import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/omron_data.dart';
import '../services/database_service.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<OmronData> _data = [];
  List<String> _patientNames = [];
  String? _selectedPatient;
  bool _isLoading = true;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analisis Data'),
          if (_selectedPatient != null)
            Text(
              _selectedPatient!,
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
        ],
      ),
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
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: [
          Tab(icon: Icon(Icons.trending_up), text: 'Tren'),
          Tab(icon: Icon(Icons.pie_chart), text: 'Komposisi'),
          Tab(icon: Icon(Icons.assessment), text: 'Statistik'),
        ],
      ),
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
    if (_filteredData.isEmpty) {
      return _buildEmptyState();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildTrendTab(),
        _buildCompositionTab(),
        _buildStatisticsTab(),
      ],
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
            _selectedPatient != null
              ? 'Tidak ada data untuk pasien $_selectedPatient'
              : 'Belum ada data yang tersimpan',
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

  Widget _buildTrendTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTrendCard('Berat Badan', 'kg', Colors.blue, 
            _filteredData.map((d) => FlSpot(
              d.timestamp.millisecondsSinceEpoch.toDouble(),
              d.weight,
            )).toList(),
          ),
          SizedBox(height: 16),
          _buildTrendCard('BMI', '', Colors.purple,
            _filteredData.map((d) => FlSpot(
              d.timestamp.millisecondsSinceEpoch.toDouble(),
              d.bmi,
            )).toList(),
          ),
          SizedBox(height: 16),
          _buildTrendCard('Body Fat', '%', Colors.orange,
            _filteredData.map((d) => FlSpot(
              d.timestamp.millisecondsSinceEpoch.toDouble(),
              d.bodyFatPercentage,
            )).toList(),
          ),
          SizedBox(height: 16),
          _buildTrendCard('Skeletal Muscle', '%', Colors.red,
            _filteredData.map((d) => FlSpot(
              d.timestamp.millisecondsSinceEpoch.toDouble(),
              d.skeletalMusclePercentage,
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(String title, String unit, Color color, List<FlSpot> spots) {
    if (spots.isEmpty) return SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: color),
                SizedBox(width: 8),
                Text(
                  'Tren $title',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${spots.length} data point',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toStringAsFixed(1)}$unit',
                            style: TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          return Text(
                            DateFormat('dd/MM').format(date),
                            style: TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompositionTab() {
    if (_filteredData.isEmpty) return _buildEmptyState();

    final latestData = _filteredData.first;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildBodyCompositionChart(latestData),
          SizedBox(height: 16),
          _buildCompositionDetails(latestData),
          SizedBox(height: 16),
          _buildHealthIndicators(latestData),
        ],
      ),
    );
  }

  Widget _buildBodyCompositionChart(OmronData data) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.orange[700]),
                SizedBox(width: 8),
                Text(
                  'Komposisi Tubuh Terkini',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(data.timestamp),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: data.bodyFatPercentage,
                      title: 'Fat\n${data.bodyFatPercentage.toStringAsFixed(1)}%',
                      color: Colors.red[400],
                      radius: 60,
                      titleStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: data.skeletalMusclePercentage,
                      title: 'Muscle\n${data.skeletalMusclePercentage.toStringAsFixed(1)}%',
                      color: Colors.blue[400],
                      radius: 60,
                      titleStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: 100 - data.bodyFatPercentage - data.skeletalMusclePercentage,
                      title: 'Other\n${(100 - data.bodyFatPercentage - data.skeletalMusclePercentage).toStringAsFixed(1)}%',
                      color: Colors.green[400],
                      radius: 60,
                      titleStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompositionDetails(OmronData data) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Komposisi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
            SizedBox(height: 16),
            _buildCompositionItem(
              'Body Fat Percentage',
              '${data.bodyFatPercentage.toStringAsFixed(1)}%',
              data.bodyFatCategory,
              Colors.red,
            ),
            _buildCompositionItem(
              'Skeletal Muscle',
              '${data.skeletalMusclePercentage.toStringAsFixed(1)}%',
              _getSkeletalMuscleCategory(data.skeletalMusclePercentage),
              Colors.blue,
            ),
            _buildCompositionItem(
              'Visceral Fat Level',
              data.visceralFatLevel.toString(),
              _getVisceralFatCategory(data.visceralFatLevel),
              Colors.pink,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompositionItem(String label, String value, String category, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthIndicators(OmronData data) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Indikator Kesehatan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildIndicatorCard(
                    'BMI',
                    data.bmi.toStringAsFixed(1),
                    data.bmiCategory,
                    Icons.straighten,
                    _getBMIColor(data.bmi),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildIndicatorCard(
                    'Body Age',
                    '${data.bodyAge} thn',
                    _getBodyAgeStatus(data.bodyAge, data.age),
                    Icons.schedule,
                    _getBodyAgeColor(data.bodyAge, data.age),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildIndicatorCard(
                    'Metabolism',
                    '${data.restingMetabolism} kcal',
                    _getMetabolismCategory(data.restingMetabolism, data.age, data.gender),
                    Icons.local_fire_department,
                    Colors.deepOrange,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildIndicatorCard(
                    'Overall',
                    data.overallAssessment,
                    _getOverallDescription(data.overallAssessment),
                    Icons.star,
                    _getOverallAssessmentColor(data.overallAssessment),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorCard(String title, String value, String status, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
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
          ),
          SizedBox(height: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    if (_filteredData.isEmpty) return _buildEmptyState();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatisticsOverview(),
          SizedBox(height: 16),
          _buildProgressAnalysis(),
          SizedBox(height: 16),
          _buildRecommendations(),
        ],
      ),
    );
  }

  Widget _buildStatisticsOverview() {
    final stats = _calculateStatistics();
    
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
                  'Ringkasan Statistik',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildStatItem('Total Pengukuran', '${_filteredData.length}', Icons.assignment, Colors.blue),
                _buildStatItem('Periode', '${stats['periodDays']} hari', Icons.date_range, Colors.green),
                _buildStatItem('Rata² Berat', '${stats['avgWeight']} kg', Icons.scale, Colors.orange),
                _buildStatItem('Rata² BMI', '${stats['avgBMI']}', Icons.straighten, Colors.purple),
                _buildStatItem('Min Berat', '${stats['minWeight']} kg', Icons.trending_down, Colors.red),
                _buildStatItem('Max Berat', '${stats['maxWeight']} kg', Icons.trending_up, Colors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressAnalysis() {
    if (_filteredData.length < 2) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
              SizedBox(height: 8),
              Text(
                'Analisis Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Minimal 2 data diperlukan untuk analisis progress',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    final progress = _calculateProgress();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.orange[700]),
                SizedBox(width: 8),
                Text(
                  'Analisis Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildProgressItem('Perubahan Berat', progress['weightChange'], 'kg', progress['weightTrend']),
            _buildProgressItem('Perubahan BMI', progress['bmiChange'], '', progress['bmiTrend']),
            _buildProgressItem('Perubahan Body Fat', progress['bodyFatChange'], '%', progress['bodyFatTrend']),
            _buildProgressItem('Perubahan Muscle', progress['muscleChange'], '%', progress['muscleTrend']),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, double change, String unit, String trend) {
    final isPositive = change > 0;
    final isNeutral = change == 0;
    
        Color color = isNeutral ? Colors.grey : (isPositive ? Colors.green : Colors.red);
    IconData icon = isNeutral ? Icons.remove : (isPositive ? Icons.trending_up : Icons.trending_down);
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}$unit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Spacer(),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _generateRecommendations();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.orange[700]),
                SizedBox(width: 8),
                Text(
                  'Rekomendasi Berdasarkan Data',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...recommendations.map((rec) => _buildRecommendationItem(rec)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(Map<String, dynamic> recommendation) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: recommendation['color'].withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: recommendation['color'].withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            recommendation['icon'],
            color: recommendation['color'],
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation['title'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: recommendation['color'],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  recommendation['description'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for calculations and categorizations
  Map<String, dynamic> _calculateStatistics() {
    if (_filteredData.isEmpty) return {};

    final weights = _filteredData.map((d) => d.weight).toList();
    final bmis = _filteredData.map((d) => d.bmi).toList();
    
    final firstDate = _filteredData.last.timestamp;
    final lastDate = _filteredData.first.timestamp;
    final periodDays = lastDate.difference(firstDate).inDays;

    return {
      'avgWeight': (weights.reduce((a, b) => a + b) / weights.length).toStringAsFixed(1),
      'avgBMI': (bmis.reduce((a, b) => a + b) / bmis.length).toStringAsFixed(1),
      'minWeight': weights.reduce((a, b) => a < b ? a : b).toStringAsFixed(1),
      'maxWeight': weights.reduce((a, b) => a > b ? a : b).toStringAsFixed(1),
      'periodDays': periodDays,
    };
  }

  Map<String, dynamic> _calculateProgress() {
    if (_filteredData.length < 2) return {};

    final latest = _filteredData.first;
    final oldest = _filteredData.last;

    final weightChange = latest.weight - oldest.weight;
    final bmiChange = latest.bmi - oldest.bmi;
    final bodyFatChange = latest.bodyFatPercentage - oldest.bodyFatPercentage;
    final muscleChange = latest.skeletalMusclePercentage - oldest.skeletalMusclePercentage;

    return {
      'weightChange': weightChange,
      'weightTrend': _getTrendDescription(weightChange, 'weight'),
      'bmiChange': bmiChange,
      'bmiTrend': _getTrendDescription(bmiChange, 'bmi'),
      'bodyFatChange': bodyFatChange,
      'bodyFatTrend': _getTrendDescription(bodyFatChange, 'bodyfat'),
      'muscleChange': muscleChange,
      'muscleTrend': _getTrendDescription(muscleChange, 'muscle'),
    };
  }

  String _getTrendDescription(double change, String type) {
    if (change.abs() < 0.1) return 'Stabil';
    
    switch (type) {
      case 'weight':
        return change > 0 ? 'Naik' : 'Turun';
      case 'bmi':
        return change > 0 ? 'Meningkat' : 'Menurun';
      case 'bodyfat':
        return change > 0 ? 'Bertambah' : 'Berkurang';
      case 'muscle':
        return change > 0 ? 'Bertambah' : 'Berkurang';
      default:
        return change > 0 ? 'Naik' : 'Turun';
    }
  }

  List<Map<String, dynamic>> _generateRecommendations() {
    if (_filteredData.isEmpty) return [];

    List<Map<String, dynamic>> recommendations = [];
    final latestData = _filteredData.first;

    // BMI recommendations
    if (latestData.bmi < 18.5) {
      recommendations.add({
        'icon': Icons.restaurant,
        'color': Colors.blue,
        'title': 'Tingkatkan Berat Badan',
        'description': 'BMI Anda di bawah normal. Konsumsi lebih banyak kalori dengan makanan bergizi.',
      });
    } else if (latestData.bmi >= 25.0) {
      recommendations.add({
        'icon': Icons.directions_run,
        'color': Colors.orange,
        'title': 'Program Penurunan Berat',
        'description': 'BMI Anda di atas normal. Tingkatkan aktivitas fisik dan atur pola makan.',
      });
    }

    // Body fat recommendations
    final highBodyFat = (latestData.gender == 'Male' && latestData.bodyFatPercentage > 25) ||
                       (latestData.gender == 'Female' && latestData.bodyFatPercentage > 32);
    
    if (highBodyFat) {
      recommendations.add({
        'icon': Icons.fitness_center,
        'color': Colors.red,
        'title': 'Kurangi Lemak Tubuh',
        'description': 'Fokus pada latihan kardio dan strength training untuk mengurangi body fat.',
      });
    }

    // Visceral fat recommendations
    if (latestData.visceralFatLevel > 9) {
      recommendations.add({
        'icon': Icons.favorite,
        'color': Colors.pink,
        'title': 'Turunkan Lemak Visceral',
        'description': 'Level lemak visceral tinggi. Kurangi konsumsi gula dan lemak jenuh.',
      });
    }

    // Muscle recommendations
    if (latestData.skeletalMusclePercentage < 30) {
      recommendations.add({
        'icon': Icons.sports_gymnastics,
        'color': Colors.purple,
        'title': 'Tingkatkan Massa Otot',
        'description': 'Lakukan latihan resistance training dan konsumsi protein yang cukup.',
      });
    }

    // Progress recommendations
    if (_filteredData.length >= 2) {
      final progress = _calculateProgress();
      final weightChange = progress['weightChange'] as double;
      
      if (weightChange.abs() > 2.0) {
        recommendations.add({
          'icon': Icons.warning,
          'color': Colors.amber,
          'title': 'Perubahan Berat Signifikan',
          'description': 'Perubahan berat badan cukup besar. Konsultasikan dengan ahli gizi.',
        });
      }
    }

    // General recommendations
    recommendations.add({
      'icon': Icons.schedule,
      'color': Colors.green,
      'title': 'Monitoring Rutin',
      'description': 'Lakukan pengukuran secara konsisten untuk tracking progress yang akurat.',
    });

    return recommendations;
  }

  // Helper methods for categorization
  String _getSkeletalMuscleCategory(double percentage) {
    if (percentage < 25) return 'Low';
    if (percentage < 35) return 'Normal';
    if (percentage < 45) return 'High';
    return 'Very High';
  }

  String _getVisceralFatCategory(int level) {
    if (level <= 9) return 'Normal';
    if (level <= 14) return 'High';
    return 'Very High';
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25.0) return Colors.green;
    if (bmi < 30.0) return Colors.orange;
    return Colors.red;
  }

  String _getBodyAgeStatus(int bodyAge, int actualAge) {
    final diff = bodyAge - actualAge;
    if (diff <= -5) return 'Sangat Baik';
    if (diff <= 0) return 'Baik';
    if (diff <= 5) return 'Rata-rata';
    return 'Perlu Perbaikan';
  }

  Color _getBodyAgeColor(int bodyAge, int actualAge) {
    final diff = bodyAge - actualAge;
    if (diff <= -5) return Colors.green;
    if (diff <= 0) return Colors.blue;
    if (diff <= 5) return Colors.orange;
    return Colors.red;
  }

  String _getMetabolismCategory(int metabolism, int age, String gender) {
    // Simplified metabolism categorization
    int baseMetabolism;
    if (gender == 'Male') {
      baseMetabolism = 1500 + (age < 30 ? 200 : (age < 50 ? 0 : -200));
    } else {
      baseMetabolism = 1200 + (age < 30 ? 150 : (age < 50 ? 0 : -150));
    }
    
    if (metabolism > baseMetabolism + 200) return 'Tinggi';
    if (metabolism > baseMetabolism - 200) return 'Normal';
    return 'Rendah';
  }

  String _getOverallDescription(String assessment) {
    switch (assessment) {
      case 'Excellent': return 'Kondisi Prima';
      case 'Good': return 'Kondisi Baik';
      case 'Fair': return 'Cukup Baik';
      default: return 'Perlu Perbaikan';
    }
  }

  Color _getOverallAssessmentColor(String assessment) {
    switch (assessment) {
      case 'Excellent': return Colors.green;
      case 'Good': return Colors.blue;
      case 'Fair': return Colors.orange;
      default: return Colors.red;
    }
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}


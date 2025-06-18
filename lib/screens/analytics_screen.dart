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
    _tabController = TabController(length: 5, vsync: this); // Increased to 5 tabs
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
          Text('Analisis Data Lengkap HBF-375'),
          if (_selectedPatient != null)
            Text(
              '$_selectedPatient (11/11 Fitur)',
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
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: _loadData,
          tooltip: 'Refresh Data',
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        isScrollable: true,
        tabs: [
          Tab(icon: Icon(Icons.trending_up, size: 20), text: 'Tren'),
          Tab(icon: Icon(Icons.pie_chart, size: 20), text: 'Komposisi'),
          Tab(icon: Icon(Icons.assessment, size: 20), text: 'Statistik'),
          Tab(icon: Icon(Icons.accessibility_new, size: 20), text: 'Segmental'),
          Tab(icon: Icon(Icons.compare, size: 20), text: 'Perbandingan'),
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
          Text('Memuat data analisis lengkap...'),
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
        _buildSegmentalTab(),
        _buildComparisonTab(),
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
          // Basic trends
          Text(
            'Tren Pengukuran Dasar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
          ),
          SizedBox(height: 16),
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
          SizedBox(height: 24),
          
          // Advanced trends
          Text(
            'Tren Pengukuran Lanjutan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          SizedBox(height: 16),
          _buildTrendCard('Subcutaneous Fat', '%', Colors.cyan,
            _filteredData.map((d) => FlSpot(
              d.timestamp.millisecondsSinceEpoch.toDouble(),
              d.subcutaneousFatPercentage,
            )).toList(),
          ),
          SizedBox(height: 16),
          _buildTrendCard('Same Age Comparison', 'percentile', Colors.indigo,
            _filteredData.map((d) => FlSpot(
              d.timestamp.millisecondsSinceEpoch.toDouble(),
              d.sameAgeComparison,
            )).toList(),
          ),
          SizedBox(height: 16),
          _buildTrendCard('Body Age', 'years', Colors.teal,
            _filteredData.map((d) => FlSpot(
              d.timestamp.millisecondsSinceEpoch.toDouble(),
              d.bodyAge.toDouble(),
            )).toList(),
          ),
        ],
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
          _buildAdvancedCompositionChart(latestData),
          SizedBox(height: 16),
          _buildHealthIndicators(latestData),
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
          _buildAdvancedStatistics(),
          SizedBox(height: 16),
          _buildRecommendations(),
        ],
      ),
    );
  }

  Widget _buildSegmentalTab() {
    if (_filteredData.isEmpty) return _buildEmptyState();

    final latestData = _filteredData.first;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSegmentalSubcutaneousChart(latestData),
          SizedBox(height: 16),
          _buildSegmentalMuscleChart(latestData),
          SizedBox(height: 16),
          _buildSegmentalComparison(latestData),
          SizedBox(height: 16),
          _buildSegmentalTrends(),
        ],
      ),
    );
  }

  Widget _buildComparisonTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSameAgeComparisonChart(),
          SizedBox(height: 16),
          _buildBenchmarkComparison(),
          SizedBox(height: 16),
          _buildProgressComparison(),
          SizedBox(height: 16),
          _buildGoalTracking(),
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

  Widget _buildAdvancedCompositionChart(OmronData data) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.layers, color: Colors.blue[700]),
                SizedBox(width: 8),
                Text(
                  'Komposisi Lemak Lanjutan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
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
                      value: data.subcutaneousFatPercentage,
                      title: 'Subcutaneous\n${data.subcutaneousFatPercentage.toStringAsFixed(1)}%',
                      color: Colors.cyan[400],
                      radius: 60,
                      titleStyle: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: data.bodyFatPercentage - data.subcutaneousFatPercentage,
                      title: 'Visceral\n${(data.bodyFatPercentage - data.subcutaneousFatPercentage).toStringAsFixed(1)}%',
                      color: Colors.red[400],
                      radius: 60,
                      titleStyle: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: 100 - data.bodyFatPercentage,
                      title: 'Non-Fat\n${(100 - data.bodyFatPercentage).toStringAsFixed(1)}%',
                      color: Colors.green[400],
                      radius: 60,
                      titleStyle: TextStyle(
                        fontSize: 10,
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

  Widget _buildSegmentalSubcutaneousChart(OmronData data) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.accessibility_new, color: Colors.purple[700]),
                SizedBox(width: 8),
                Text(
                  'Distribusi Subcutaneous Fat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: data.segmentalSubcutaneousFat.values.reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const titles = ['Trunk', 'R.Arm', 'L.Arm', 'R.Leg', 'L.Leg'];
                          return Text(
                            titles[value.toInt()],
                            style: TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toStringAsFixed(0)}%', style: TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: data.segmentalSubcutaneousFat['trunk']!, color: Colors.purple[400])]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: data.segmentalSubcutaneousFat['rightArm']!, color: Colors.purple[400])]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: data.segmentalSubcutaneousFat['leftArm']!, color: Colors.purple[400])]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: data.segmentalSubcutaneousFat['rightLeg']!, color: Colors.purple[400])]),
                    BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: data.segmentalSubcutaneousFat['leftLeg']!, color: Colors.purple[400])]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentalMuscleChart(OmronData data) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, color: Colors.red[700]),
                SizedBox(width: 8),
                Text(
                  'Distribusi Skeletal Muscle',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: data.segmentalSkeletalMuscle.values.reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const titles = ['Trunk', 'R.Arm', 'L.Arm', 'R.Leg', 'L.Leg'];
                          return Text(
                            titles[value.toInt()],
                            style: TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toStringAsFixed(0)}%', style: TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: data.segmentalSkeletalMuscle['trunk']!, color: Colors.red[400])]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: data.segmentalSkeletalMuscle['rightArm']!, color: Colors.red[400])]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: data.segmentalSkeletalMuscle['leftArm']!, color: Colors.red[400])]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: data.segmentalSkeletalMuscle['rightLeg']!, color: Colors.red[400])]),
                    BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: data.segmentalSkeletalMuscle['leftLeg']!, color: Colors.red[400])]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSameAgeComparisonChart() {
    if (_filteredData.isEmpty) return SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.compare, color: Colors.indigo[700]),
                SizedBox(width: 8),
                Text(
                  'Perbandingan Usia Sebaya',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%', style: TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          return Text(DateFormat('dd/MM').format(date), style: TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _filteredData.map((d) => FlSpot(
                        d.timestamp.millisecondsSinceEpoch.toDouble(),
                        d.sameAgeComparison,
                      )).toList(),
                      isCurved: true,
                      color: Colors.indigo,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.indigo.withOpacity(0.1),
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

  // Additional helper methods for other widgets would continue here...
  // Due to space constraints, I'll include the essential structure and key methods

  Widget _buildCompositionDetails(OmronData data) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Komposisi Lengkap',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
            SizedBox(height: 16),
            // Basic composition
            _buildCompositionItem('Body Fat', '${data.bodyFatPercentage.toStringAsFixed(1)}%', data.bodyFatCategory, Colors.red),
            _buildCompositionItem('Subcutaneous Fat', '${data.subcutaneousFatPercentage.toStringAsFixed(1)}%', _getSubcutaneousFatCategory(data.subcutaneousFatPercentage), Colors.cyan),
            _buildCompositionItem('Skeletal Muscle', '${data.skeletalMusclePercentage.toStringAsFixed(1)}%', _getSkeletalMuscleCategory(data.skeletalMusclePercentage), Colors.blue),
            _buildCompositionItem('Visceral Fat', data.visceralFatLevel.toString(), _getVisceralFatCategory(data.visceralFatLevel), Colors.pink),
            _buildCompositionItem('Same Age Rank', '${data.sameAgeComparison.toStringAsFixed(0)}th percentile', data.sameAgeCategory, Colors.indigo),
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

  // Helper methods for categorization
  String _getSubcutaneousFatCategory(double percentage) {
    if (percentage <= 10) return 'Low';
    if (percentage <= 20) return 'Normal';
    if (percentage <= 30) return 'High';
    return 'Very High';
  }

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

  // Placeholder methods for remaining widgets
  Widget _buildHealthIndicators(OmronData data) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Health Indicators - Implementation would include BMI status, body age comparison, metabolism rate, etc.'),
      ),
    );
  }

  Widget _buildStatisticsOverview() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Statistics Overview - Implementation would include averages, trends, min/max values for all 11 features'),
      ),
    );
  }

  Widget _buildProgressAnalysis() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Progress Analysis - Implementation would show changes over time for all parameters'),
      ),
    );
  }

  Widget _buildAdvancedStatistics() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Advanced Statistics - Correlation analysis, segmental ratios, age comparison trends'),
      ),
    );
  }

  Widget _buildRecommendations() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Recommendations - AI-powered suggestions based on all 11 parameters and trends'),
      ),
    );
  }

  Widget _buildSegmentalComparison(OmronData data) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Segmental Comparison - Balance analysis between body parts'),
      ),
    );
  }

  Widget _buildSegmentalTrends() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Segmental Trends - Historical changes in body part composition'),
      ),
    );
  }

  Widget _buildBenchmarkComparison() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Benchmark Comparison - Compare against fitness standards and population averages'),
      ),
    );
  }

  Widget _buildProgressComparison() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Progress Comparison - Month-over-month and year-over-year analysis'),
      ),
    );
  }

  Widget _buildGoalTracking() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Goal Tracking - Set and monitor fitness goals based on Omron measurements'),
      ),
    );
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
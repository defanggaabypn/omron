import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/omron_data.dart';

class OmronResultCard extends StatelessWidget {
  final OmronData data;

  const OmronResultCard({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.green[50],
      child: LayoutBuilder( // Gunakan LayoutBuilder untuk mendapatkan constraints
        builder: (context, constraints) {
          return SizedBox(
            height: constraints.maxHeight > 0 
                ? constraints.maxHeight 
                : MediaQuery.of(context).size.height * 0.7, // Fallback height
            child: Column(
              children: [
                // Header yang tidak di-scroll
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _buildHeader(),
                ),
                // Content yang bisa di-scroll
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPatientInfo(),
                        const SizedBox(height: 12),
                        _buildMeasurements(),
                        const SizedBox(height: 12),
                        _buildAnalysis(),
                        const SizedBox(height: 12),
                        _buildRecommendations(),
                        const SizedBox(height: 20), // Extra space di bawah
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.analytics,
            size: 28,
            color: Colors.green[700],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hasil Analisis Omron',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              Text(
                DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(data.timestamp),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        _buildOverallScoreBadge(),
      ],
    );
  }

  Widget _buildOverallScoreBadge() {
    Color badgeColor;
    IconData badgeIcon;
    
    switch (data.overallAssessment) {
      case 'Excellent':
        badgeColor = Colors.green;
        badgeIcon = Icons.star;
        break;
      case 'Good':
        badgeColor = Colors.blue;
        badgeIcon = Icons.thumb_up;
        break;
      case 'Fair':
        badgeColor = Colors.orange;
        badgeIcon = Icons.warning;
        break;
      default:
        badgeColor = Colors.red;
        badgeIcon = Icons.priority_high;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            data.overallAssessment,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfo() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: Colors.green[700], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.patientName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${data.age} tahun • ${data.gender == 'Male' ? 'Pria' : 'Wanita'} • ${data.height.toStringAsFixed(0)} cm',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 Hasil Pengukuran',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMeasurementTile(
                    'Berat Badan',
                    '${data.weight.toStringAsFixed(1)} kg',
                    Icons.scale,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMeasurementTile(
                    'Body Fat',
                    '${data.bodyFatPercentage.toStringAsFixed(1)}%',
                    Icons.pie_chart,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMeasurementTile(
                    'BMI',
                    data.bmi.toStringAsFixed(1),
                    Icons.straighten,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMeasurementTile(
                    'Skeletal Muscle',
                    '${data.skeletalMusclePercentage.toStringAsFixed(1)}%',
                    Icons.fitness_center,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMeasurementTile(
                    'Visceral Fat',
                    data.visceralFatLevel.toString(),
                    Icons.favorite,
                    Colors.pink,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMeasurementTile(
                    'Metabolism',
                    '${data.restingMetabolism} kcal',
                    Icons.local_fire_department,
                    Colors.deepOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildMeasurementTile(
              'Body Age',
              '${data.bodyAge} tahun',
              Icons.schedule,
              Colors.teal,
              isFullWidth: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMeasurementTile(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🔍 Analisis Kesehatan',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        const SizedBox(height: 8),
        _buildAnalysisItem(
          'BMI Status',
          data.bmiCategory,
          _getBMICategoryColor(data.bmiCategory),
          _getBMIDescription(data.bmiCategory),
        ),
        _buildAnalysisItem(
          'Body Fat Status',
          data.bodyFatCategory,
          _getBodyFatCategoryColor(data.bodyFatCategory),
          _getBodyFatDescription(data.bodyFatCategory),
        ),
        _buildAnalysisItem(
          'Visceral Fat',
          _getVisceralFatCategory(data.visceralFatLevel),
          _getVisceralFatColor(data.visceralFatLevel),
          _getVisceralFatDescription(data.visceralFatLevel),
        ),
      ],
    );
  }

  Widget _buildAnalysisItem(String title, String category, Color color, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 11),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💡 Rekomendasi',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _getRecommendations(),
          ),
        ),
      ],
    );
  }

  List<Widget> _getRecommendations() {
    List<Widget> recommendations = [];
    
    // BMI recommendations
    if (data.bmi < 18.5) {
      recommendations.add(_buildRecommendationItem(
        '🍎 Tingkatkan asupan kalori dengan makanan bergizi',
        Colors.blue,
      ));
    } else if (data.bmi >= 25.0) {
      recommendations.add(_buildRecommendationItem(
        '🏃‍♂️ Perbanyak aktivitas fisik dan kurangi kalori',
        Colors.orange,
      ));
    }
    
    // Body fat recommendations
    if (data.bodyFatPercentage > 25 && data.gender == 'Male') {
      recommendations.add(_buildRecommendationItem(
        '💪 Fokus pada latihan kardio dan strength training',
        Colors.red,
      ));
    } else if (data.bodyFatPercentage > 32 && data.gender == 'Female') {
      recommendations.add(_buildRecommendationItem(
        '💪 Fokus pada latihan kardio dan strength training',
        Colors.red,
      ));
    }
    
    // Visceral fat recommendations
    if (data.visceralFatLevel > 9) {
      recommendations.add(_buildRecommendationItem(
        '❤️ Kurangi lemak visceral dengan diet seimbang',
        Colors.pink,
      ));
    }
    
    // General recommendations
    recommendations.add(_buildRecommendationItem(
      '📅 Lakukan pengukuran rutin setiap minggu',
      Colors.green,
    ));
    
    recommendations.add(_buildRecommendationItem(
      '👨‍⚕️ Konsultasikan dengan ahli gizi untuk program yang tepat',
      Colors.purple,
    ));

    return recommendations;
  }

  Widget _buildRecommendationItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods tetap sama...
  Color _getBMICategoryColor(String category) {
    switch (category) {
      case 'Normal': return Colors.green;
      case 'Overweight': return Colors.orange;
      case 'Obese': return Colors.red;
      case 'Underweight': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _getBMIDescription(String category) {
    switch (category) {
      case 'Normal': return 'Berat badan ideal untuk tinggi badan Anda';
      case 'Overweight': return 'Berat badan sedikit berlebih';
      case 'Obese': return 'Berat badan berlebih, perlu perhatian khusus';
      case 'Underweight': return 'Berat badan kurang dari ideal';
      default: return '';
    }
  }

  Color _getBodyFatCategoryColor(String category) {
    switch (category) {
      case 'Athletes': return Colors.green;
      case 'Fitness': return Colors.blue;
      case 'Average': return Colors.orange;
      case 'Obese': return Colors.red;
      case 'Essential Fat': return Colors.purple;
      default: return Colors.grey;
    }
  }

  String _getBodyFatDescription(String category) {
    switch (category) {
      case 'Athletes': return 'Persentase lemak tubuh sangat baik';
      case 'Fitness': return 'Persentase lemak tubuh baik untuk kebugaran';
      case 'Average': return 'Persentase lemak tubuh rata-rata';
      case 'Obese': return 'Persentase lemak tubuh terlalu tinggi';
      case 'Essential Fat': return 'Lemak tubuh minimal yang diperlukan';
      default: return '';
    }
  }

  String _getVisceralFatCategory(int level) {
    if (level <= 9) return 'Normal';
    if (level <= 14) return 'High';
    return 'Very High';
  }

  Color _getVisceralFatColor(int level) {
    if (level <= 9) return Colors.green;
    if (level <= 14) return Colors.orange;
    return Colors.red;
  }

  String _getVisceralFatDescription(int level) {
    if (level <= 9) return 'Level lemak visceral dalam batas normal';
    if (level <= 14) return 'Level lemak visceral agak tinggi';
    return 'Level lemak visceral sangat tinggi';
  }
}
